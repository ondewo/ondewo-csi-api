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

## Client-release orchestration (`release_all_clients`)

- It **fails loudly** on a genuine client-release error: the piped sub-make runs under `bash -c 'set -o pipefail; make -C … | tee …'` (a plain sh pipe returns tee's 0 and masks failures), and a **marker file** distinguishes an "already released" SKIP from a real FAILURE (make flattens recipe exit codes to 2, so the code alone can't tell them apart). Do not regress either.
- Every token-bearing recipe line is `@`-prefixed so make never echoes a secret — `docker run -e <TOKEN>`, `echo $(TOKEN) | gh auth`, `twine … -p${PYPI_PASSWORD}`, and the credential sub-make `make release $(info)` (which expands the token at runtime and is easy to miss).

## Pre-commit upgraded (language-agnostic hook set)

Pre-commit here uses only the language-agnostic hooks — **markdownlint-cli2, pre-commit-hooks hygiene, giticket, conventional-pre-commit** — no ruff/mypy/uv (there is no Python). Generated docs (`docs/`) and any generated code are excluded via the top-level `exclude:`.

- **markdownlint MD053 is disabled** (its auto-fix deletes `[comment]: <>` reference-definition markers).
- **markdownlint RELEASE.md reformatting is content-safe**: it only strips trailing whitespace and adds blank lines around headings — the `## Release … <VERSION>` headings and `*****` separators that `ondewo_release` greps for remain intact. (Confirmed: the 6.5.0 release notes sliced correctly after the reformat.)

## GitHub Actions — the docs build is a REQUIRED gate, not advisory

`.github/workflows/generate-doc-and-deploy.yaml` ("Generate API Documentation") is the **only** CI
this repository has, and it is a gate: its middle step runs `protoc` over every `.proto` under
`ondewo/`, so a malformed or unresolvable proto turns the run red. The published docs are a
by-product of that parse. There is no `uv`, `ruff`, `mypy`, `pytest` or coverage threshold here —
there is no Python source (see _Pre-commit upgraded_ above), so do not go looking for a frozen
`uv sync` that does not exist.

Three declared steps, in order (the runner inserts a `Build ondewo/ondewo-protoc-gen-doc-action@master`
step of its own before them, because step 2 is a **docker** action):

1. **Checkout 🛎️** — `actions/checkout@v5` with `submodules: true`.
2. **Generate documentation from ONDEWO proto files 🔧** — `ondewo/ondewo-protoc-gen-doc-action@master`.
   This is the gate.
3. **Deploy 🚀** — `JamesIves/github-pages-deploy-action@v4`, publishing `docs/` into `docs/` on `master`.

**The triggers are `master`-only**: push to `master`, `pull_request` _into_ `master`, or a manual
`workflow_dispatch`. Pushing a feature branch runs nothing at all, so the first time a broken proto
gets reported is the pull request — build the docs locally before you open one.

### Reproducing it locally, with the workflow's own commands

`make build_docs` is the supported path: it clones the action repo and builds the very image CI
builds, so the `protoc` version and the doc templates are the ones CI uses rather than whatever is
on your machine. The command inside that image is `entrypoint.sh`, copied verbatim:

```sh
protoc \
  -I. \
  -Igoogleapis \
  --doc_opt=/resources/templates/${format}.tmpl,${2}.${format} \
  --doc_out=docs \
  $(find ondewo -name '*.proto' | sort)
```

Check what the real run concluded rather than guessing — no `gh` CLI is installed here:

```bash
curl -s "https://api.github.com/repos/ondewo/ondewo-csi-api/actions/runs?head_sha=$(git rev-parse HEAD)" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['total_count']); \
[print(r['run_number'], r['status'], r['conclusion'], r['html_url']) for r in d['workflow_runs']]"
```

A `total_count` of `0` means **no run exists for that SHA** — the normal state of a feature branch
with no open PR. That is not a pass, and must not be reported as one.

### What is sharp about this workflow

- **It really does bite.** Confirmed by falsification: dropping the `;` from `syntax = "proto3";` in
  `ondewo/csi/conversation.proto` makes the step print `Expected ";"` and exit `1`.
- **`googleapis: warning: directory does not exist.` on every single run is normal, and is not the
  failure.** The entrypoint passes `-Igoogleapis`, a directory this repository does not have;
  `google/api/annotations.proto`, `google/rpc/status.proto` and friends resolve out of the vendored
  `google/` tree at the repo root via `-I.`. Deleting or relocating `google/` breaks the docs build
  even though no `.proto` here ever mentions the string "googleapis".
- **Only `find ondewo -name '*.proto'` is compiled — the submodules are not.** Checkout pulls
  `ondewo-nlu-api`, `ondewo-s2t-api` and `ondewo-t2s-api`, but nothing compiles them: the
  `ondewo/nlu`, `ondewo/s2t` and `ondewo/t2s` protos that _are_ compiled are the vendored copies
  under `ondewo/`. Bumping a submodule pin therefore changes neither the docs nor the gate — copying
  the protos into `ondewo/` is the change that matters.
- **`diff -rq ondewo/s2t ondewo-s2t-api/ondewo/s2t` reports a difference that is whitespace-only.**
  Pre-commit's `trailing-whitespace` hook rewrites `ondewo/**` while `ondewo-*-api/**` sits in the
  top-level `exclude:`, so the vendored copy drifts from the submodule by stripped line-ends alone
  (measured: 40 changed lines, zero of them surviving `diff -b`). Use `diff -b` before reading that
  as proto skew.
- **Green is not "clean": `protoc` exits `0` on warnings.** Today's run reports
  `ondewo/csi/conversation.proto:20:1: warning: Import google/protobuf/timestamp.proto is unused.`
  and the same for `google/protobuf/any.proto` — both pre-existing, neither fatal. `entrypoint.sh`
  also has no `set -e` and loops over the formats, so the step's exit status is the **last** format's
  `protoc`; the html and md passes parse the same files, so that has never masked anything, but it is
  a second reason to read the log rather than the tick.
- **`docs/` is generated output, and a stale `docs/` on a feature branch is not a broken build.**
  Deploy regenerates it from the protos and publishes to `master`. Measured on this branch: freshly
  generated `index.md` is 1,072,321 bytes against the committed 587,101, and `CALL_ENDED` — added by
  this branch — appears in the fresh copy and not the committed one. Never hand-edit `docs/`.
- **Never run the Deploy step by hand**: it writes into `master`'s `docs/`. The workflow guards it
  with `if: ${{ !env.ACT }}`, and `nektos/act` sets `ACT=true`, so a local `act` run skips it by
  design.
- **Keep the `--user "$(id -u):$(id -g)"` that `make build_docs` passes.** CI runs the container as
  root; invoking the CI-shaped `docker run` by hand instead writes `docs/index.html` and
  `docs/index.md` into your working tree owned by `root:root`. The two invocations are otherwise
  equivalent — verified byte-identical output for all three generated files.
- **A `make build_docs` that dies with `could not read Username for 'https://github.com'` is not a
  credentials problem.** The action repo is public and that clone is anonymous; the failure was
  transient here and the identical command succeeded on retry. Retry before you go hunting for a
  token. Note also that the target leaves `.tmp-protoc-gen-doc-action/` behind as untracked cruft
  (it is not in `.gitignore`) — `make clean_docs_builder` removes it and the local image.

## Jenkins — never trigger a multibranch scan or branch indexing

**NEVER trigger a Jenkins multibranch scan or branch indexing.** Do not call a multibranch/folder job's
`build`, `scan`, or reindex endpoints, click "Scan Repository Now" / "Build Now" on a folder, run
`p4 scan`, or use any API/CLI that reindexes branches or scans the repository. A scan/reindex runs across
**every** branch, consumes CI resources, and can kick off unintended builds and deploys.

If a branch is not building — it was not discovered, or its job is marked `buildable: false` / orphaned —
**report it and stop**. Let the user or a Jenkins admin adjust branch-discovery/config or rename the branch
to the convention. Never force a build by scanning or reindexing.
