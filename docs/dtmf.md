# DTMF keys in the ONDEWO CSI API

This guide describes how the speech-to-speech pipeline (ONDEWO CSI) receives the DTMF (keypad) keys a caller presses
and turns them into caller turns. The generated reference of every message and field is [index.md](index.md) (also
`index.html`); this page explains how the pieces fit together. It covers ONDEWO CSI API **5.8.0**.

The API surface is one RPC, `Conversations.SetCallerDtmf`. It is an **internal** RPC: only ONDEWO SIP in the same
per-call container calls it. Applications do not call it; they shape what a key does through the NLU answer (a key
menu or a key entry, see [Declaring keys](#declaring-keys-in-the-nlu-answer)) and, through ONDEWO VTSI, through the
per-call `DtmfConfig`. Pressing keys TOWARDS the far end (e.g. an IVR the bot called) is the other direction and
belongs to the [ONDEWO SIP API](https://github.com/ondewo/ondewo-sip-api/blob/master/docs/dtmf.md) (`SipSendDtmf`) and
the [ONDEWO VTSI API](https://github.com/ondewo/ondewo-vtsi-api/blob/master/docs/dtmf.md) (`Calls.SendCallDtmf`).

## Sequence

```mermaid
sequenceDiagram
    participant Caller
    participant SIP as ONDEWO SIP
    participant CSI as ONDEWO CSI (Conversations)
    participant NLU as ONDEWO NLU / AI Teams

    NLU-->>CSI: answer declaring a key menu or a key entry
    CSI->>Caller: bot speaks the prompt ("for sales press 1")
    Caller->>SIP: RFC 4733 telephone-event
    SIP->>CSI: SetCallerDtmf(call_id, sequence, digit, ...)<br/>+ x-ondewo-sip-in-container-token
    CSI-->>SIP: CallerDtmfResponse(accepted=true)
    opt the bot is speaking
        CSI->>Caller: playback cut (a key is a barge-in)
    end
    Note over CSI: a menu key commits at once;<br/>a key entry collects until its terminator,<br/>maximum length or timeout
    CSI->>NLU: turn text [DTMF:1] + one-turn context c-dtmf
    NLU-->>CSI: next answer (declares keys again, or clears them)
```

## `SetCallerDtmf`

```protobuf
rpc SetCallerDtmf (CallerDtmfRequest) returns (CallerDtmfResponse);

message CallerDtmfRequest {
    string call_id = 1;            // ONDEWO SIP's id of the call (SipStatus.call_id)
    uint64 sequence = 2;           // 1 for the first key of the call, then +1 per admitted key
    string digit = 3;              // one of 0-9 * # A-D; never logged in clear
    uint32 duration_ms = 4;        // how long the key was held; 0 when unknown
    int64 received_unix_ns = 5;    // when ONDEWO SIP received the key (for the key-to-audio latency)
}

message CallerDtmfResponse {
    bool accepted = 1;             // true if the key was taken as caller input
    string reason = 2;             // empty when accepted, otherwise a stable token
}
```

### Fields

| Field | Semantics |
| --- | --- |
| `call_id` | The call the key belongs to, as ONDEWO SIP reports it in `SipStatus.call_id`. A key of another call than the one the server currently serves is refused (`other-call`), so a late key of a finished call can never reach the next call of a persistent container. |
| `sequence` | Per-call number assigned by ONDEWO SIP: 1 for the first key, then +1 for every key it admitted, including keys it later could not deliver. A number not greater than the last one accepted is refused (`stale-sequence`). A jump by more than one tells the server that a key was lost (see [Invalid entries](#invalid-entries)). |
| `digit` | Exactly one key: `0`-`9`, `*`, `#` or `A`-`D`. Anything else is refused (`invalid-digit`). |
| `duration_ms` | How long the key was held; informational, `0` when unknown. |
| `received_unix_ns` | Wall clock at ONDEWO SIP's receipt, used to measure the SIP-to-CSI and key-to-first-audio latency. `0` when unknown. |
| `accepted` | `true` when the key was taken as caller input. An accepted key may still end up in an invalid entry; the response does not say what the key did. |
| `reason` | Empty when accepted; otherwise one of the tokens below. |

### Authentication

Every request must carry ONDEWO SIP's in-container token in the `x-ondewo-sip-in-container-token` metadatum. It is a
random secret minted at container start and handed only to the processes of that container; it proves "sent from
inside this container", which an address cannot (per-call containers run with host networking). The server compares
it in constant time. A missing or wrong token is answered with the gRPC status **`UNAUTHENTICATED`** and the key is
not taken (fail closed). A server that does not implement the RPC (CSI API before 5.8.0) answers **`UNIMPLEMENTED`**;
ONDEWO SIP then stops forwarding keys for the life of the container.

### Refusals (`CallerDtmfResponse.reason`)

A refused key changes nothing. The checks run in this order:

| `reason` | Meaning |
| --- | --- |
| `disabled` | Keys are switched off for this call (`CSI_DTMF_ACTIVE=False`, or ONDEWO VTSI's `DtmfConfig.enabled=false`). |
| `amd-in-progress` | Answering machine detection is still deciding about the call; fax and IVR tones never become turns. |
| `listening-paused` | An operator paused the bot's listening (ONDEWO SIP `SipSetCallMediaControl`). |
| `no-call` | The server has no call (no speech-to-speech stream) to give the key to. |
| `other-call` | `call_id` is not the server's current call. |
| `stale-sequence` | `sequence` is not greater than the last accepted one (a repeat or a reordered key). |
| `invalid-digit` | `digit` is not exactly one of `0-9 * # A-D`. |
| `undeclared` | The bot's last answer declared no key menu or key entry, and the undeclared-key policy is `drop` (the default). The key does not interrupt the bot. |
| `invalid-key` | A key outside the options of a declared menu whose `invalid_key_policy` is `ignore`. This token is sent by the 5.8.0 server although the proto comment does not list it yet; treat unknown tokens as refusals. |

ONDEWO SIP forwards each key once with a short deadline and retries once; it does not resend a refused key.

## Declaring keys in the NLU answer

**What the bot asked for decides what a key does.** Every answered NLU response either declares keys or clears them,
so a menu never outlives the turn that offered it. The declaration is read from, first hit wins:

1. `diagnostic_info["ondewo_expected_input"]["dtmf"]` of the NLU response. A classic ONDEWO NLU intent declares it
   with an intent tag, which ONDEWO NLU turns into this block:
   - `ondewo-voice:dtmf-menu:<menu_id>`
   - `ondewo-voice:dtmf-digits:<id>[:min=N][:max=N][:terminator=K][:timeout_ms=N][:masked][:nospeech]`
2. The output context `c-voice-turn` (written at run time, e.g. by an AI Team), with the parameters `dtmf_mode`,
   `dtmf_menu_id`, `dtmf_options` (`"1=marketing;2=sales"`), `dtmf_min_digits`, `dtmf_max_digits`,
   `dtmf_terminator`, `dtmf_timeout_ms`, `dtmf_masked`.

The fields of a declaration:

| Field | Values | Meaning |
| --- | --- | --- |
| `mode` | `menu` \| `digits` | One key chooses (`menu`), or a key string is collected (`digits`). |
| `menu_id` | string | The menu's or entry's name, sent back in `c-dtmf.menu_id`. |
| `options` | keys | The keys a menu offers. |
| `min_digits`, `max_digits` | `max_digits` clamped to 1 - 32, `min_digits` to 1 - `max_digits` | Length of a key entry. |
| `terminator` | a key, usually `#` | Ends a key entry; not part of the value. |
| `clear_key` | a key, usually `*` | Empties an open key entry. Disabled for an entry whose terminator is the same key. |
| `inter_digit_timeout_ms` | 300 - 10000 | Silence after a key that ends a key entry; `0` or unreadable means the deployment default (`CSI_DTMF_INTER_DIGIT_TIMEOUT_MS`, 2000). |
| `masked` | bool | The value is sensitive (a PIN); ONDEWO NLU persists it masked. |
| `allow_speech` | bool | `false` (tag option `:nospeech`) ignores speech while the bot asks for this key entry, e.g. a PIN pad. |
| `invalid_key_policy` | `commit` \| `ignore` | A menu key outside `options`: commit it so the agent can re-prompt (default), or refuse it (`invalid-key`). |

Every clamp and every unreadable value is logged as a warning naming the field. A committed entry or menu choice
**consumes** its declaration: further keys are undeclared until the next answer declares again.

## How keys become turns

| The bot's last answer declared | A key does |
| --- | --- |
| a `menu` | commits a turn at once (`ended_by=menu`); a key outside `options` commits too, unless `invalid_key_policy=ignore` |
| a `digits` entry | is collected; the entry commits on its terminator (`ended_by=terminator`), at `max_digits` (`max`) or after the inter-digit timeout (`timeout`); the clear key empties it |
| nothing | is dropped (`undeclared`) and does not stop the bot; with the undeclared policy `commit_single` every key is a one-key turn (`mode=menu`, empty `menu_id`) |

- **A key over the bot is a barge-in**, at once: the playback is cut exactly like a confirmed spoken interruption,
  without the speech gates (noise gate, minimum words, the protected first message) and also when spoken
  interruptions are switched off. A key entry barges in once, at its first key. `CSI_DTMF_BARGE_IN_ACTIVE=False` (ONDEWO
  VTSI: `DtmfConfig.barge_in=false`) lets the bot finish.
- **A key wins its turn.** While a key entry is open, and for a short guard (`CSI_DTMF_SPEECH_GUARD_MS`, 300 ms)
  after a key turn, a spoken final is not committed. A menu leaves speech alone until a key arrives, so a caller may
  still say the option.

### The turn sent to NLU

The committed keys are sent as the turn text `[DTMF:<keys>]` (`CSI_DTMF_TEXT_TEMPLATE`), e.g. `[DTMF:1]`. `*` and `#`
are spelled `STAR` and `HASH` (a menu choice `*` is `[DTMF:STAR]`), because the NLU tokenizer drops both characters
and `[DTMF:*]` would otherwise match `[DTMF:#]`. A classic intent matches the token as a training phrase (typically
gated by its menu's input context); an AI Team reads it as the caller's message. The terminator is not part of the
keys.

The turn carries the one-turn context **`c-dtmf`** (lifespan 1) and none of the speech-recognition contexts:

| Parameter | Value |
| --- | --- |
| `digits` | the keys (empty for an invalid entry) |
| `mode` | `menu` \| `digits` |
| `menu_id` | the declared name, or empty |
| `ended_by` | `menu` \| `terminator` \| `max` \| `timeout` \| `too_short` \| `key_lost` |
| `masked` | `true` \| `false`, as declared |
| `keys` | the number of keys the entry received |
| `source` | `dtmf` |

### Invalid entries

An invalid key entry is a turn, not silence, so a re-prompt intent (training phrase `[DTMF:INVALID]`) can ask again:

- **`too_short`**: the entry ended by its terminator or its timeout with fewer than `min_digits` keys.
- **`key_lost`**: a key was lost while the entry was open, i.e. `sequence` jumped by more than one (or the key that
  opened the entry followed a gap). A clear key after the loss forgives it.

The turn text is then `[DTMF:INVALID]` and `c-dtmf` carries `digits=""`, the `ended_by` above, the entry's `menu_id`,
`masked` and `keys`.

### Example

The bot's answer was tagged `ondewo-voice:dtmf-digits:customer_number:min=4:max=8:terminator=#:masked` and the caller
presses the fictional number `4711` and then `#`. The NLU receives the text `[DTMF:4711]` with the context
`c-dtmf` = `{digits: "4711", mode: "digits", menu_id: "customer_number", ended_by: "terminator", masked: "true",
keys: "4", source: "dtmf"}`. Had the caller pressed only `47#`, the text would be `[DTMF:INVALID]` with
`ended_by: "too_short"` and `keys: "2"`.

## Configuration

Deployment defaults of the server; ONDEWO VTSI can override the first four per call with
`VoiceInteractionConfig.dtmf_config` (see the
[ONDEWO VTSI API DTMF guide](https://github.com/ondewo/ondewo-vtsi-api/blob/master/docs/dtmf.md)).

| Setting | Default | Meaning |
| --- | --- | --- |
| `CSI_DTMF_ACTIVE` | `True` | `False` answers every key `disabled`. |
| `CSI_DTMF_BARGE_IN_ACTIVE` | `True` | Whether a taken key stops the bot. |
| `CSI_DTMF_INTER_DIGIT_TIMEOUT_MS` | `2000` | Default inter-digit timeout of a key entry (300 - 10000). |
| `CSI_DTMF_UNDECLARED_POLICY` | `drop` | `drop` or `commit_single`. |
| `CSI_DTMF_SPEECH_GUARD_MS` | `300` | How long after a key turn a spoken final is still superseded (0 - 5000). |
| `CSI_DTMF_TEXT_TEMPLATE` | `[DTMF:{digits}]` | The turn text of a key entry. |

## Security

- **Keys are never logged in clear**, neither by ONDEWO SIP nor by ONDEWO CSI: log lines carry `<dtmf:N>` (the
  number of keys), and the `[DTMF:...]` turn text is masked in every log line. `[DTMF:INVALID]` carries no key and
  stays readable.
- **A `masked` entry** still carries its keys to the NLU, which needs them to act, and which persists them masked.
- **Authentication** is the in-container token; nothing outside the container can inject a key.
- **Events and audit records carry counts only**; see the ONDEWO VTSI guide.

## Limits

| Limit | Value |
| --- | --- |
| Keys per `SetCallerDtmf` request | exactly 1 |
| Keys per key entry | up to 32 (`max_digits` is clamped to 32); entries of 1 to 30 keys are tested end to end on live calls |
| Inter-digit timeout | 300 - 10000 ms, default 2000 |
| Key alphabet | `0`-`9`, `*`, `#`, `A`-`D` |

## See also

- [ONDEWO SIP API: DTMF](https://github.com/ondewo/ondewo-sip-api/blob/master/docs/dtmf.md): how ONDEWO SIP admits,
  numbers and forwards a key, and `SipSendDtmf`.
- [ONDEWO VTSI API: DTMF](https://github.com/ondewo/ondewo-vtsi-api/blob/master/docs/dtmf.md): the per-call
  `DtmfConfig` and `Calls.SendCallDtmf`.
- Server documentation (ONDEWO CSI): `docs/voice_interaction.md` § "DTMF keys".
