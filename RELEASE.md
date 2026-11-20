# Release History

*****************

## Release ONDEWO CSI API 5.9.0

### New Features

* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) Add `DeliverWarmTransferOutcomeNotice`: ondewo-sip
  delivers the outcome of a warm transfer that did not hand the caller over, so the bot can tell the caller.
  Authenticated with ondewo-sip's in-container token (`x-ondewo-sip-in-container-token`); a missing or wrong token
  is answered `UNAUTHENTICATED`, and an older server answers `UNIMPLEMENTED`.
  * `WarmTransferOutcomeNotice`: `request_id = 1` (string, 1 to 128 characters, taken at most once per call),
    `outcome = 2` (`WarmTransferOutcome`), `intro_session = 3` (string, the intro's NLU session, `DECLINED` only),
    `callee_display_name = 4` (string, at most 128), `cause = 5` (string, a bounded token, at most 64) and
    `fallback_text = 6` (string, at most 1024, the sentence the bot speaks when it cannot commit the notice as a
    turn; it never carries a decline reason).
  * `WarmTransferOutcome`: `WARM_TRANSFER_OUTCOME_UNSPECIFIED = 0`, `_DECLINED = 1`, `_UNREACHABLE = 2`,
    `_DELEGATION_EXPIRED = 3` (a bot transfer handed to ondewo-vtsi and never claimed; the server runs its
    failed-transfer action).
  * `WarmTransferOutcomeNoticeResponse.status = 1` (`WarmTransferOutcomeNoticeStatus`): `_QUEUED = 1`,
    `_DUPLICATE = 2`, `_DISABLED = 3`, `_INVALID = 4`; `_UNSPECIFIED = 0` is never sent. A queued notice is dropped
    only by `CALL_ENDED`.

### Improvements

* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) `docs/warm_transfer.md`: a hand-written guide to
  the warm-transfer outcome notice: who sends it, when, how the server speaks it, every status, and the limits.
* Purely additive: no field, enum value or RPC was renumbered or removed. `CallMediaControlLevel` and
  `SetCallMediaControlResponse` are unchanged; the notice is not part of the media-control level. The vendored
  APIs stay at ondewo-nlu-api 7.4.0 and ondewo-t2s-api 6.6.0.
* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) The vendored ondewo-s2t-api moves from 7.5.0 to
  7.6.0. It brings
  `TurnDetectionOptions.oneof_turn_detector`: one options message per turn detector (chat LLM, end-of-utterance
  LLM, the ONDEWO German model, the ONDEWO German fusion detector, pipecat Smart Turn); the ONDEWO German and
  pipecat Smart Turn options also carry `end_of_turn_probability_threshold`. The 7.5.0 fields
  `turn_detection_system_prompt`, `turn_detection_user_prompt` and `turn_detection_llm_openai_options` are
  deprecated but still honoured when no detector is chosen. No ondewo-csi-api message changed.

### Breaking Changes

* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) The clients of 5.9.0 are generated with
  ondewo-proto-compiler 5.17.0 (was 5.15.7): protoc 35.1 for every client except C++. The generated code requires
  at least these runtimes (a newer runtime is fine, an older one is refused):
  * Python: `protobuf>=7.35.1` and `grpcio>=1.85.1`, so Python >= 3.10. Every `_pb2.py` carries
    `# Protobuf Python Version: 7.35.1`, every `_pb2_grpc.py` `GRPC_GENERATED_VERSION = '1.85.1'`; both refuse an
    older runtime at import. The `.pyi` stubs come from mypy-protobuf 5.1.0. `grpcio-tools`, `grpcio-reflection`
    and `mypy-protobuf` are no longer runtime dependencies of `ondewo-csi-client`.
  * Java: protobuf-java 4.35.1, grpc-java 1.85.1, proto-google-common-protos 2.82.0.
  * C#: Google.Protobuf 3.35.1, Grpc.Core.Api / Grpc.Net.Client 2.85.0, Google.Api.CommonProtos 2.17.0.
  * PHP: `google/protobuf` 5.35.1 (a major step from 4.x, php >= 8.2.0) and `grpc/grpc` 1.85.0.
  * Go: `google.golang.org/grpc` v1.85.0, `google.golang.org/protobuf` v1.36.12, `go 1.26.0`.
  * Rust: prost / prost-types 0.14.6, tonic / tonic-prost 0.14.9.
  * JavaScript, TypeScript: grpc-web 2.1.1 (`protoc-gen-grpc-web` 2.1.1), `google-protobuf ^4.0.3`. grpc-web 2.1.1
    limits a response to 4 MB unless `maxReceiveMessageSize` is set.
  * Angular: grpc-web 2.1.1 as an exact direct dependency plus `"overrides": { "grpc-web": "$grpc-web" }` (because
    `@ngx-grpc/grpc-web-client` still declares the peer `grpc-web ^1.2.1`), `@ngx-grpc/*` `~3.1.2`,
    `google-protobuf ~3.21.4`. An app installing the client needs the same override.
  * Node.js: `@grpc/grpc-js` 1.14.7 and `google-protobuf` 3.21.4.
  * C++: unchanged (Debian trixie's protobuf 3.21.12 / grpc 1.51.1).

*****************

## Release ONDEWO CSI API 5.8.0

### New Features

* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) Add `SetCallerDtmf`: ondewo-sip reports each DTMF
  key the caller pressed (`CallerDtmfRequest`: `call_id`, per-call `sequence`, `digit`, `duration_ms`,
  `received_unix_ns`), authenticated with its in-container token. `CallerDtmfResponse` answers `accepted` or a
  stable `reason` token (`disabled`, `no-call`, `other-call`, `stale-sequence`, `invalid-digit`, `listening-paused`,
  `amd-in-progress`, `undeclared`). Additive; an older server answers `UNIMPLEMENTED`.
* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) Add the child-measured barge-in cut, so the server
  knows how much of an interrupted answer the caller can actually have heard:
  * `ControlStatus.PLAYBACK_CUT = 9`, reported by the client via `SetControlStatus` with the new
    `SetControlStatusRequest.playback_cut` (field 2). Like `CALL_ENDED` it is a report, not a state: the server never
    assigns it, never pushes it onto the control stream and leaves a pending `BARGE_IN` latched. It requires the
    in-container token (`x-ondewo-sip-in-container-token`). The server answers, in this order:
    * token missing or wrong: `UNAUTHENTICATED`, never retried. A server with no token configured (standalone, or
      relaunched without it) refuses every cut, never requests one (`playback_cut_request_id = 0`) and keeps its own
      estimate;
    * `playback_cut` not set: `INVALID_ARGUMENT`, never retried;
    * `playback_cut_request_id` not pending on the current control stream (zero, unknown, already answered,
      superseded, from a previous stream or call): OK, the cut is dropped;
    * otherwise: OK, the cut is recorded.

    An OK answer echoes the held control status unchanged (`old_control_status == new_control_status`). Any other
    gRPC status leaves delivery unknown; a retry with the same id is safe, because an answered id is dropped.
  * `PlaybackCut` carries `playback_cut_request_id`, `barge_in_epoch`, the `utterance_id` / `chunk_index` /
    `response_sequence` playing at the cut, `written_audio_us`, the raw `queued_audio_us` read once before the flush
    with `queued_audio_estimated` when that read was not possible, `cut_monotonic_ns` and `remainder_held`. The server
    computes the played prefix in one place as `written_audio_us - min(queued_audio_us, written_audio_us)`.
  * `ControlStreamResponse.playback_cut_request_id` (field 4): non-zero only on a `BARGE_IN` transition of a server
    that consumes cuts. It is that transition's process-lifetime sequence number, so a second barge-in during a
    resumed remainder (same epoch) still has its own id. Never set on the stream seed or a media-control message.
  * `S2sStreamResponse.response_sequence` (field 8): a one-based per-stream number of every response the server
    yields. It names responses that carry no `utterance_id` (greeting, merged utterance, filler, apology) in a cut.
  * `SetControlStatusRequest.utterance_id` (field 3) and `response_sequence` (field 4), set with `PLAYBACK_DONE`
    to name the utterance whose playback completed.

### Improvements

* [[OND236-120]](https://ondewo.atlassian.net/browse/OND236-120) `docs/dtmf.md`: a hand-written guide to DTMF
  on the CSI API: `SetCallerDtmf` (fields, authentication, every refusal token), how the NLU answer declares key
  menus and key entries, the `[DTMF:<keys>]` turn and its `c-dtmf` context, invalid entries, security and limits.
* Purely additive: no field, enum value or RPC was renumbered or removed. A client sends `PLAYBACK_CUT` only after
  it read a non-zero `playback_cut_request_id`, so a server built against 5.7.0 never receives value 9, and a client
  built against 5.7.0 never sees the new fields. The vendored APIs stay at ondewo-nlu-api 7.4.0, ondewo-s2t-api 7.5.0
  and ondewo-t2s-api 6.6.0.

*****************

## Release ONDEWO CSI API 5.7.0

### Improvements

* Tracking [ondewo-nlu-api 7.4.0](https://github.com/ondewo/ondewo-nlu-api/releases/tag/7.4.0) (was 7.1.0).
  `ondewo-s2t-api` stays at 7.5.0 and `ondewo-t2s-api` at 6.6.0, both already the latest.
* `ondewo/csi/conversation.proto` is untouched, so every csi message, field and RPC keeps its number and meaning and
  a client built against 5.6.2 stays wire-compatible. What changes is the vendored nlu surface this API ships:
  * `ondewo/nlu/session.proto` gains `LlmAgentNodeEvent` (streamed as `llm_agent_node_event` on
    `StreamingDetectIntent`) and the per-base-URL `LlmBaseUrlUsage` breakdown in `LlmTelemetryReport`.
  * `ondewo/nlu/agent.proto` gains a base-URL filter on the agent and session statistics requests.
  * `ondewo/nlu/operation_metadata.proto` gains the `REPARSE_DATASET` operation type.
  * `ondewo/nlu/rag.proto` moves `max_pages` from `RagCrawlerDeepCrawlerConfig` to `RagCrawlerConfig`
    (nlu-api 7.3.0).
* MINOR rather than patch because the published API surface grew, and because the client SDKs move their
  `ondewo-nlu-client` dependency to the 7.4 line: csi-client 5.6.x capped it below 7.2.0.

*****************

## Release ONDEWO CSI API 5.6.2

### Improvements

* No API change: the two unused imports `google/protobuf/timestamp.proto` and `google/protobuf/any.proto` are
  removed from `ondewo/csi/conversation.proto`. No message, field, enum value or RPC changed, so a client built
  against 5.6.0 stays wire-compatible. The vendored APIs stay at ondewo-nlu-api 7.1.0, ondewo-s2t-api 7.5.0 and
  ondewo-t2s-api 6.6.0.
* All eleven client SDKs (python, nodejs, typescript, angular, js, cpp, csharp, go, java, php, rust) are released
  from this repository by `make release_all_clients`, generated with the pinned ondewo-proto-compiler 5.15.7. A
  read-only `preflight_all_clients` runs first and stops the run before anything is released when one client's
  credentials, version or release notes are not in order; a client is reported released only when its
  `release_verify` saw the tag, a non-empty GitHub release and the version served by its registry.
* Release credentials stay off command lines and out of the repository: the devops-accounts clone lives in a
  private temporary directory and is deleted before the release starts.
* Client SDK fixes shipped with this release:
  * python: the async `S2sStream` and `GetControlStream` wrappers return the stream instead of awaiting it, so
    both async streams can be opened at all (before, grpc.aio raised `TypeError` on the first call).
  * nodejs and js: the published packages no longer ship the TypeScript sources and spec files.
  * nodejs, typescript, js and angular: published to npm before anything is pushed, with the shipped package
    content checked against the committed tree; eslint is no longer pinned back to an older parser.
  * every SDK: a read-only release preflight, the full test suite before publishing, API-surface tests derived
    from the protos instead of hard-coded lists, pinned toolchain images and a registry check after publishing.

*****************

## Release ONDEWO CSI API 5.6.0

### New Features

* [[OND233-367]](https://ondewo.atlassian.net/browse/OND233-367) Add `SetCallMediaControl`: per-call operator media control pushed by ondewo-sip (in-container token only). The request `CallMediaControlLevel` carries the FULL effective level (`bot_muted`, `listening_paused`), a container-lifetime monotonic `generation` (a push is applied only when its generation is strictly greater than the last applied one, otherwise it is answered `stale=true`) and a bounded `reason` token. The response `SetCallMediaControlResponse` reports the `applied` level, `changed`, `stale`, `bot_playback_in_flight` and a `refusal_reason` (`amd-in-progress`).
* [[OND233-367]](https://ondewo.atlassian.net/browse/OND233-367) Add `ControlStreamResponse.media_control` (field 3): set ONLY on media-control messages, pushed on a level change and seeded on every `GetControlStream` connect. A client must handle such a message as media control and must not apply its echoed `control_status`, which would un-latch a pending `BARGE_IN`.

### Improvements

* `SipTrigger.INVITE` is documented as not implemented: ondewo-csi cannot reach ondewo-vtsi. Use the ondewo-vtsi `Calls.InviteToCall` RPC.
* Purely additive: no field, enum value or RPC was renumbered or removed, and `ControlStatus` is unchanged, so a client built against 5.5.0 stays wire-compatible.

*****************

## Release ONDEWO CSI API 5.5.0

### Improvements

* Tracking [ondewo-nlu-api 7.1.0](https://github.com/ondewo/ondewo-nlu-api/releases/tag/7.1.0) (was 7.0.0) and [ondewo-s2t-api 7.5.0](https://github.com/ondewo/ondewo-s2t-api/releases/tag/7.5.0) (was 7.4.0). `ondewo-t2s-api` stays at 6.6.0, which is already the latest.
* The change is **purely additive and `ondewo/csi/conversation.proto` is untouched**, so every existing message, field and RPC keeps its number and meaning and a client built against 5.4.0 stays wire-compatible. What grows is the vendored surface this API ships and re-exports:
  * `ondewo/s2t/speech-to-text.proto` gains the `VadMethod` and `TsdMethod` enums and the `Silero` and `WespeakerTsd` messages — voice-activity and turn-shift detection configuration — together with their fields.
  * `ondewo/nlu/rag.proto` gains `RagCrawlerIncrementalConfig`.
* This is a MINOR bump rather than a patch because the published API surface grew: a consumer can now reference definitions that did not exist in 5.4.0.

*****************

## Release ONDEWO CSI API 5.4.0

### Improvements

* [[OND235-105]](https://ondewo.atlassian.net/browse/OND235-105) Extend `ControlStatus` with barge-in and playback lifecycle statuses `BARGE_IN`, `RESUME_PLAYBACK`, `DISCARD_REMAINDER`, `PLAYBACK_RESUMED` and `PLAYBACK_DONE`
* [[OND235-105]](https://ondewo.atlassian.net/browse/OND235-105) Add monotonic barge-in `epoch` field to `ControlStreamResponse`
* [[OND235-105]](https://ondewo.atlassian.net/browse/OND235-105) Add utterance/turn framing fields `utterance_id`, `chunk_index`, `last_chunk` and `turn_epoch` to `S2sStreamResponse`
* [[OND211-2418]](https://ondewo.atlassian.net/browse/OND211-2418) Upgrade API to NLU API [7.0.0](https://github.com/ondewo/ondewo-nlu-api/releases/7.0.0), S2T API [7.4.0](https://github.com/ondewo/ondewo-s2t-api/releases/7.4.0) and T2S API [6.6.0](https://github.com/ondewo/ondewo-t2s-api/releases/6.6.0) libraries

*****************

## Release ONDEWO CSI API 5.3.0

### Improvements

* [[OND235-105]](https://ondewo.atlassian.net/browse/OND235-105) Upgrade API to NLU API [6.11.0](https://github.com/ondewo/ondewo-nlu-api/releases/6.11.0), S2T API [7.3.0](https://github.com/ondewo/ondewo-s2t-api/releases/7.3.0) and T2S API [6.2.0](https://github.com/ondewo/ondewo-t2s-api/releases/6.2.0) libraries
* [[OND211-2333]](https://ondewo.atlassian.net/browse/OND211-2333) Add local documentation build make targets (`build_docs`, `clean_docs_builder`) and improve proto file documentation with HTML formatting

*****************

## Release ONDEWO CSI API 5.2.0

### Improvements

* [[OND235-66]](https://ondewo.atlassian.net/browse/OND235-66) Extend `SipTripperType` with `PLAY_AUDIO` "play audio from URL" and "play audio from file (mapped volume)"

*****************

## Release ONDEWO CSI API 5.1.0

### Improvements

* [[OND235-87]](https://ondewo.atlassian.net/browse/OND235-87) Upgrade API to S2T API [6.1.0](https://github.com/ondewo/ondewo-s2t-api/releases/6.1.0)

*****************

## Release ONDEWO CSI API 5.0.0

### Improvements

* [[OND235-87]](https://ondewo.atlassian.net/browse/OND235-87) Upgrade API to NLU API [6.0.0](https://github.com/ondewo/ondewo-nlu-api/releases/6.0.0), S2T API [6.0.0](https://github.com/ondewo/ondewo-s2t-api/releases/6.0.0) and T2S API [6.0.0](https://github.com/ondewo/ondewo-t2s-api/releases/6.0.0) libraries
* [[OND235-87]](https://ondewo.atlassian.net/browse/OND235-87) Add further control messages for csi and vtsi

*****************

## Release ONDEWO CSI API 4.0.0

### Improvements

* [[OND235-57]](https://ondewo.atlassian.net/browse/OND235-76) Upgrade API to NLU API [5.0.0](https://github.com/ondewo/ondewo-nlu-api/releases/5.0.0), S2T API [5.7.0](https://github.com/ondewo/ondewo-s2t-api/releases/5.7.0) and T2S API [5.3.0](https://github.com/ondewo/ondewo-t2s-api/releases/5.3.0) libraries
* Upgrade `Dockerfile.utils` to `python:3.10-slim`
* Upgrade nvm to `v18.18.0`

*****************

## Release ONDEWO CSI API 3.2.0

### Improvements

* [[OND235-57]](https://ondewo.atlassian.net/browse/OND235-57) Upgrade to ONDEWO NLU API [4.7.0](https://github.com/ondewo/ondewo-nlu-api/releases/4.7.0), ONDEWO S2T API [5.4.0](https://github.com/ondewo/ondewo-s2t-api/releases/5.4.0) and ONDEWO T2S API [5.0.0](https://github.com/ondewo/ondewo-t2s-api/releases/5.0.0) libraries

### Bug Fixes

* Fixed spellings

*****************

## Release ONDEWO CSI API 3.1.0

### Improvements

* Added documentation for all messages and added RABBIT MQ control message examples
* Upgraded dependency to ONDEWO NLU API [4.6.0](https://github.com/ondewo/ondewo-nlu-api/releases/4.6.0)
* Corrected spelling from synthesize_response to synthesize_response

*****************

## Release ONDEWO CSI API 3.0.0

### New Features

* Synchronize API Client Versions

*****************

## Release ONDEWO CSI API 2.3.1

### New Features

* ONDEWO Natural Language Understanding (NLU) API
  Version [2.10.0](https://github.com/ondewo/ondewo-nlu-api/releases/2.10.0)
* ONDEWO Speech-2-Text (S2T) API Version [3.3.0](https://github.com/ondewo/ondewo-s2t-api/releases/3.3.0)
* ONDEWO Text-2-Speech (S2T) API Version [4.3.0](https://github.com/ondewo/ondewo-t2s-api/releases/4.3.0)

*****************

## Release ONDEWO CSI API 2.1.0

### New Features

* [[OND211-2039]](https://ondewo.atlassian.net/browse/OND211-2039) Added pre-commit hooks and adjusted files to them

*****************

## Release ONDEWO CSI API 2.0.0

### New Features

* [[OND211-2039]](https://ondewo.atlassian.net/browse/OND211-2039) Automated Release Process

*****************

## Release ONDEWO CSI API 1.6.0

### New Features

* Update nlu api to 2.5.0 and s2t api to 3.1.0

*****************

## Release ONDEWO CSI API 1.5.0

### New Features

* Update nlu api to 2.4.0 s2t api to 3.0.0 and t2s api to 3.0.0

*****************

## Release ONDEWO CSI API 1.4.0

### New Features

* Extend sip control messages

*****************

## Release ONDEWO CSI API 1.3.0

### New Features

* Added SIP Control messages

*****************

## Release ONDEWO CSI API 1.2.0

### New Features

* Added Control messages

*****************

## Release ONDEWO CSI API 1.1.0

### New Features

* New nlu,t2s,s2t api and proto generation

*****************

## Release ONDEWO CSI API 1.0.0

### New Features

* [[OND233-258]](https://ondewo.atlassian.net/browse/OND233-258) add ControlStream endpoints
* [[OND211-380]](https://ondewo.atlassian.net/browse/OND211-380) generate API documentation,
  accessible at [ondewo.github.io/ondewo-csi-api](https://ondewo.github.io/ondewo-csi-api/)

*****************

## Release ONDEWO CSI API 0.2.2

### New Features

* [[OND233-201]](https://ondewo.atlassian.net/browse/OND233-201) add endpoint for checking health of upstream S2T, NLU
  and T2S servers
* [[OND233-213]](https://ondewo.atlassian.net/browse/OND233-213) add optional initial intent field to S2sStreamRequest
  to trigger an intent in NLU system
* [[OND233-216]](https://ondewo.atlassian.net/browse/OND233-216) add SipTrigger message to S2sStreamResponse in case a
  SIP trigger was detected in NLU response
