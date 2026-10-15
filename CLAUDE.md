# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working Principles

Behavioral guidelines to reduce common mistakes. They bias toward caution over speed; for trivial tasks, use judgment.

### Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical changes

Touch only what you must. Clean up only your own mess.

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that _your_ changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### Goal-driven execution

Define success criteria. Loop until verified.

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

These guidelines are working if: fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and
clarifying questions come before implementation rather than after mistakes.

## Logging

```python
from loguru import logger as log
```

- **Levels:** `log.trace()`, `log.debug()`, `log.info()`, `log.warning()`, `log.error()`, `log.exception()`. Choose by
  hotness/verbosity — `trace` for per-token / hot-path detail, `debug` for routine method entry/exit, `info` for notable
  lifecycle events, `warning` / `error` / `exception` for problems.
- **Interpolate with f-strings, not loguru's `{}` positional args.** Consistent with the Code Style rule, use
  `f"…{value}"`; only add the `f` prefix when the string actually interpolates (`"START: …"` with no params stays a
  plain string).
- **`START:` / `DONE:` bracketing.** Wrap a method (or other notable operation) with a `START:` line at entry and a
  `DONE:` line at exit, both naming `ClassName: method_name` (append `: param={value}` context where useful):

  ```python
  log.debug("START: IntentBertClassifier: predict")
  ...
  log.debug(f"DONE: IntentBertClassifier: predict. Elapsed time: {perf_counter() - start_time:.5f}")
  ```

- **Timing uses `perf_counter()`, rendered `:.5f`.** Measure elapsed time with `time.perf_counter()` captured as a start
  value and subtracted at the `DONE:` line; always format the elapsed value with the `:.5f` spec:

  ```python
  from time import perf_counter

  start_time: float = perf_counter()
  ...
  log.info(f"DONE: SESSION SERVICER: DetectIntent. Elapsed time: {perf_counter() - start_time:.5f}")
  ```

  Never measure a duration with `time.time()` — reserve `time.time()` for wall-clock timestamps (epoch seconds persisted
  to a DB / proto, unique-id or filename stamps). `perf_counter()` has an undefined epoch and must not be stored or
  compared across processes.

## Docstrings

Google-style, triple double-quotes:

```python
"""
Short imperative summary line.

Args:
    param_name (type):
        Description of the parameter.

Returns:
    type:
        Description of the return value.

Raises:
    ExceptionType:
        When this exception is raised.
"""
```

## Git Commits

- **Never include Claude as author or co-author** in commit messages, PR descriptions, or any other text. Do not add
  `Co-Authored-By: Claude…` trailers, "Generated with Claude Code" footers, or any similar attribution.
- The user's own git author identity (already configured in git) is the only identity that should appear on commits.
- This rule overrides the default Claude Code commit-template guidance.
- **Never prepend the JIRA ticket ID** (e.g. `[OND211-2386]`) to the commit subject yourself. The `giticket` pre-commit
  hook reads the ticket from the branch name (`(feature|bugfix|support|hotfix)/<TICKET>-…`) and prepends `[<ticket>]`
  (with a trailing space) automatically. Writing the prefix manually produces a duplicate like
  `[OND211-2386] [OND211-2386] feat: …`. Write the subject as plain Conventional Commits (`feat: …`, `fix(scope): …`,
  `docs(types): …`) and let the hook add the prefix on commit.

## General Principles

- Follow existing patterns before introducing new abstractions.
- Keep changes minimal and consistent with surrounding code.
- Validate inputs early with descriptive, context-rich error messages.
- Use context managers for files, sockets, and thread pools.
- Prefer region comments for grouping methods in files that already use them.
- End edited Markdown and YAML files with a trailing newline.

## Embedded API submodules and what the generated clients ship

`ondewo-csi-api` embeds sibling API repos as submodules; the generated clients are built from that
combined tree. Current pins:

- `ondewo-nlu-api` **7.0.0**
- `ondewo-s2t-api` 7.4.0
- `ondewo-t2s-api` 6.6.0

Two consequences worth knowing before touching a submodule pointer:

- **The generated Python client ships `ondewo/csi` only.** `ondewo-csi-client-python` contains **no**
  `ondewo/nlu` (or s2t/t2s) `*_pb2` modules — it declares `ondewo-nlu-client==7.0.1` as a runtime
  dependency and consumes those protos from that wheel. Bumping `ondewo-nlu-api` here therefore
  changes only what the csi protos may _reference_, not what the client physically installs, so it
  cannot collide in a downstream descriptor pool. (`ondewo-vtsi-client-python` is the one that
  vendors 55 `ondewo/nlu` files and does have that hazard — see ondewo-vtsi `CLAUDE.md` §3.)
- **`ondewo-nlu-api` 7.0.0 made several previously-plain scalars `optional`.** Downstream code must
  read them with `HasField()` and write them conditionally; assigning unconditionally turns "unset"
  into "explicitly the default", which is a different instruction on the wire, not a no-op.

`ControlStatus.CALL_ENDED` (wire value **8**) was added on this branch for the persistent-listener
per-call reset: ondewo-sip sends it over `SetControlStatus` so a warm ondewo-csi wipes its per-call
state in place instead of the container cold-booting after every call. The numeric value is a
cross-repo contract — never renumber an existing `ControlStatus` member.

## Client-release orchestration (`release_all_clients`)

The flow is described in README "Automatic Release Process - Clients"; the logic lives in
`scripts/release_client.sh` and `scripts/with_devops_accounts.sh`, and `scripts/test_release_driver.py`
runs it against fake client repositories. It is a port of ondewo-vtsi-api's driver (PR #28). Invariants,
each of which a past run violated:

- **All eleven SDKs are in `CLIENTS`**; the release-notes heading is the capitalised name except `C++`
  and `PHP` (`CLIENT_DISPLAY_NAME_<x>`). It used to list five.
- **SKIP means "tag on origin AND `release_verify` passes".** It used to be "some branch name contains the
  version" (`branch -a | grep`, unanchored), so a client that failed after pushing `release/<version>` was
  reported as done on the re-run, and `release/15.6.0` made 5.6.0 a SKIP. A branch without a tag, or a tag
  whose `release_verify` fails, is FAILED. The marker file still separates SKIP from RELEASED (make flattens
  exit codes to 2); a marker only counts when the client exited 0.
- **`preflight_all_clients` is a prerequisite** of the parallel release (`.NOTPARALLEL:` keeps the order
  under `-j`): one failing preflight stops the run before anything is released.
- **A client without `release_preflight` / `release_verify` FAILS** with "client <x> lacks …"; never skip it.
  All eleven csi clients have them since 5.6.2, the first release cut by this driver.
- **One devops-accounts clone per run**, in `mktemp -d`, never in a checkout, removed by an EXIT trap; each
  client gets a private copy as an ABSOLUTE path (clients run as `make -C <client>`, where a relative
  `./ondewo-devops-accounts` resolves to nothing and the client silently clones its own; a client deleting
  "its" clone cannot break a parallel one). The wrapper lines call `make`, not `$(MAKE)`: make executes
  `$(MAKE)` lines under `-n`, so a dry run would clone the credentials.
- **Cleanup on every exit path, no sudo**: the client clone and the private temp dir go in the script's
  EXIT trap; root-owned files go through a digest-pinned busybox container.
- **No bare `export`**, and the client make starts without `MAKEFLAGS` and without every variable named in
  it: make exports command-line variables (`CLIENT=…`) to children, and a client's `?=` would take them.
- **The version rewrites are anchored on the assignment** (`^ONDEWO_CSI_VERSION\s*=`, …). Unanchored they
  also hit lines that merely mention the variable: two `echo` lines of ondewo-csi-client-go's go.mod check
  and comments in the csharp and angular Makefiles.
- **The proto compiler is pinned** (`ONDEWO_PROTO_COMPILER_VERSION`), not "the first tag the API returns".
- The client make's output is piped through `tee` under `set -o pipefail`; a plain pipe returns tee's 0.
- Every token-bearing recipe line is `@`-prefixed, and gh gets the token as `GH_TOKEN` of the one command
  that needs it (no `gh auth login`); `scripts/check_release_credentials_hygiene.py` fails on a token on argv.

## Pre-commit upgraded (language-agnostic hook set)

Pre-commit here uses only the language-agnostic hooks — **markdownlint-cli2, pre-commit-hooks hygiene, giticket, conventional-pre-commit** — no ruff/mypy/uv (there is no Python). Generated docs (`docs/`) and any generated code are excluded via the top-level `exclude:`.

- **markdownlint MD053 is disabled** (its auto-fix deletes `[comment]: <>` reference-definition markers).
- **markdownlint RELEASE.md reformatting is content-safe**: it only strips trailing whitespace and adds blank lines around headings — the `## Release … <VERSION>` headings and `*****` separators that `ondewo_release` greps for remain intact. (Confirmed: the 6.5.0 release notes sliced correctly after the reformat.)

## Jenkins — never trigger a multibranch scan or branch indexing

**NEVER trigger a Jenkins multibranch scan or branch indexing.** Do not call a multibranch/folder job's
`build`, `scan`, or reindex endpoints, click "Scan Repository Now" / "Build Now" on a folder, run
`p4 scan`, or use any API/CLI that reindexes branches or scans the repository. A scan/reindex runs across
**every** branch, consumes CI resources, and can kick off unintended builds and deploys.

If a branch is not building — it was not discovered, or its job is marked `buildable: false` / orphaned —
**report it and stop**. Let the user or a Jenkins admin adjust branch-discovery/config or rename the branch
to the convention. Never force a build by scanning or reindexing.
