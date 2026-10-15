<p align="center">
    <a href="https://www.ondewo.com">
      <img alt="ONDEWO Logo" src="https://raw.githubusercontent.com/ondewo/ondewo-logos/master/github/ondewo_logo_github_2.png"/>
    </a>
</p>

# ONDEWO CSI APIs

This repository contains the original interface definitions of public ONDEWO APIs that support gRPC protocols. Reading the original interface definitions can provide a better understanding of ONDEWO APIs and help you to utilize them more efficiently. You can also use these definitions with open source tools to generate client libraries, documentation, and other artifacts.

The core components of all the client libraries are built directly from files in this repo using [the proto compiler.](https://github.com/ondewo/ondewo-proto-compiler)

For an end-user, the APIS in this repo function mostly as documentation for the endpoints. For specific implementations, look in the following repos for working implementations:

* [Python](https://github.com/ondewo/ondewo-csi-client-python)
* [Angular](https://github.com/ondewo/ondewo-csi-client-angular)
* [Nodejs](https://github.com/ondewo/ondewo-csi-client-nodejs)
* [Typescript](https://github.com/ondewo/ondewo-csi-client-typescript)
* [Javascript](https://github.com/ondewo/ondewo-csi-client-js)

Please note that some of these implementations are works-in-progress. The repo will make clear the status of the implementation.

## Overview

ONDEWO APIs use [Protocol Buffers](https://github.com/google/protobuf) version 3 (proto3) as their Interface Definition Language (IDL) to define the API interface and the structure of the payload messages. The same interface definition is used for gRPC versions of the API in all languages.

There are several ways of accessing APIs:

1. Protocol Buffers over gRPC: You can access APIs published in this repository through [GRPC](https://github.com/grpc), which is a high-performance binary RPC protocol over HTTP/2. It offers many useful features, including request/response multiplex and full-duplex streaming.

2. ONDEWO Client Libraries:
You can use these libraries to access ONDEWO Cloud APIs. They are based on gRPC for better performance and provide idiomatic client surface for better developer experience.

The `.proto`-files of this repository are dependent on 3 other APIs:

* `Natural Language Understanding (NLU)`
* `Speech to Text (S2T)`
* `Text to Speech (T2S)`

To make development with this API easier, use the `make build` command to pull the `.proto`-files from the api-repositories and put them all in the `ondewo` folder.

## Discussions

Please use the issue tracker in this repo for discussions about this API, or the issue tracker in the relevant client if it is language-specific.

## Repository Structure

```
.
├── CONTRIBUTING.md
├── Dockerfile.utils
├── docs
│   ├── index.html
│   ├── index.md
│   └── style.css
├── install_nvm.sh
├── LICENSE
├── Makefile
├── ondewo
│   ├── csi
│   │   └── conversation.proto
│   ├── nlu
│   │   ├── agent.proto
│   │   ├── aiservices.proto
│   │   ├── common.proto
│   │   ├── context.proto
│   │   ├── entity_type.proto
│   │   ├── intent.proto
│   │   ├── operation_metadata.proto
│   │   ├── operations.proto
│   │   ├── project_role.proto
│   │   ├── project_statistics.proto
│   │   ├── server_statistics.proto
│   │   ├── session.proto
│   │   ├── user.proto
│   │   ├── utility.proto
│   │   └── webhook.proto
│   ├── s2t
│   │   └── speech-to-text.proto
│   └── t2s
│       └── text-to-speech.proto
├── ondewo-nlu-api             <-------- NLU-API Repository @ https://github.com/ondewo/ondewo-nlu-api
├── ondewo-s2t-api             <-------- S2T-API Repository @ https://github.com/ondewo/ondewo-s2t-api
├── ondewo-t2s-api             <-------- T2S-API Repository @ https://github.com/ondewo/ondewo-t2s-api
├── README.md
└── RELEASE.md
```

## Generate gRPC Source Code

API client libraries can be built directly from files in this repo using [the proto compiler.](https://github.com/ondewo/ondewo-proto-compiler)

## Automatic Release Process

The entire process is automated to make development easier. The actual steps are simple:

TODOs after Pull Request was merged in:

* Checkout master:
    >git checkout master
* Pull the new stuff:
    >git pull
* (If not already, run the `setup_developer_environment_locally` command):
   >make setup_developer_environment_locally
* Update the `ONDEWO_CSI_API_VERSION` in the `Makefile`
* Add the new Release Notes in `RELEASE.md` in the format:

   ```
   ## Release ONDEWO CSI API X.X.X       <---- Beginning of Notes

      ...<NOTES>...

   *****************                      <---- End of Notes
   ```

* `Commit and push` the changes made in `RELEASE.md` and `Makefile`
* Release:
   >make ondewo_release

---
The `make ondewo_release` command runs these steps, in this order:

* `spc` (read-only): the version is `MAJOR.MINOR.PATCH`, neither `release/<version>` nor the tag
  `<version>` exists locally or on origin (anchored ref lookups; an unreadable origin fails closed), and
  `RELEASE.md` has a non-empty `## Release ONDEWO CSI API <version>` section
* `scripts/with_devops_accounts.sh --github-token`: clones ondewo-devops-accounts into a private
  `mktemp -d` directory OUTSIDE the checkout, reads `GITHUB_GH_TOKEN` into the environment of the
  release sub-make, and deletes the clone **before** the release starts (and on every failure path)
* creating and pushing the release branch
* creating and pushing the release tag
* creating the GitHub release in the pinned `Dockerfile.utils` image, which refuses empty notes; gh
  reads the token from `GH_TOKEN` of that one command, so nothing is persisted by `gh auth login`

The token never appears on a command line (where `/proc/<pid>/cmdline` would show it to every user on
the host) or in the console; `python3 scripts/check_release_credentials_hygiene.py` checks the Makefile
and the workflows for that.

`make -n ondewo_release` prints the wrapper line only: it deliberately calls `make`, not `$(MAKE)`,
because make executes `$(MAKE)` lines even under `-n` and a dry run would clone the credentials. Use
`make -n release` to see the release steps.

## Automatic Release Process - Clients

All eleven `ondewo-csi-client-<language>` SDKs (`CLIENTS` in the Makefile: python nodejs typescript
angular js cpp csharp go java php rust) are released from this repository, after the API itself.
Each client repository implements the same contract, so the driver treats them all alike:

| Client target | Side effects | Used for |
| --- | --- | --- |
| `release_preflight` | none | credentials valid, version new on origin and on the registry, notes present, host tools there |
| `ondewo_release` | the release | the release itself; it starts with `release_preflight` |
| `release_verify` | none | the tag exists, the GitHub release has a body, and the registry serves the version |

```bash
make preflight_all_clients           # read-only: every client's release_preflight, serially
make release_all_clients             # preflight_all_clients, then all clients in parallel
make release_python_client           # one client (likewise release_<language>_client)
make preflight_python_client         # one client's preflight (likewise preflight_<language>_client)
make check_proto_compiler_is_latest  # optional: is ONDEWO_PROTO_COMPILER_VERSION the newest compiler tag?
```

What `release_all_clients` does (`scripts/release_client.sh` per client):

1. Clones ondewo-devops-accounts **once** into a private `mktemp -d` directory outside every
   repository (`scripts/with_devops_accounts.sh`) and hands each client its own copy as
   `DEVOPS_ACCOUNT_DIR`; every copy and the clone are deleted on every exit path, Ctrl-C included.
2. Runs `preflight_all_clients`. **A single failing preflight stops the run before any client is
   released.**
3. Releases the clients in parallel, each into a fresh `release_run_<language>.log` (mode 600), and prints a
   summary. One failing client does not abort the others; the run fails if any client failed.

For every client, in preflight and release alike, the driver clones the client, inserts the generated
release notes into its `RELEASE.md` unless it already documents the version, and rewrites the anchored
`ONDEWO_CSI_VERSION=`, `ONDEWO_PROTO_COMPILER_GIT_BRANCH=tags/<ONDEWO_PROTO_COMPILER_VERSION>` and
`(ONDEWO_)CSI_API_GIT_BRANCH=` assignments of its Makefile. Then what origin already has decides:

| On the client's origin | Result |
| --- | --- |
| tag `<version>` and `release_verify` passes | **SKIP**: already released and verified |
| tag `<version>` but `release_verify` fails | **FAILED**: a half-finished release; finish it by hand |
| branch `release/<version>` but no tag | **FAILED**: a half-finished release; finish or undo it by hand |
| neither | preflight: `release_preflight`; release: `ondewo_release`, then `release_verify` |

A client is reported RELEASED only when its `release_verify` passed after the release. A client whose
Makefile lacks `release_preflight` or `release_verify` fails with `client <x> lacks release_preflight`
(or `release_verify`) instead of being skipped. The client clone is removed on every exit path; files a
client container wrote as root are removed through a digest-pinned busybox container, never `sudo`.

Every csi client provides `release_preflight` and `release_verify` since the 5.6.2 release, which was the
first one cut by this driver.

The proto compiler is pinned exactly in `ONDEWO_PROTO_COMPILER_VERSION`; move it deliberately.

**Host requirements:** git (with SSH access to GitHub and Bitbucket), make, perl, bash and docker,
plus whatever each client's own release documents. The behaviour above is tested against fake client
repositories by `python3 scripts/test_release_driver.py` (also run by the `Release credential hygiene`
workflow).

## Proto Documentation

The documentation for this, and all other APIs and their available versions, can be found on [ondewo.github.io](https://ondewo.github.io). For Offline usage, it can also be found in the `docs` folder.

As part of the `pre-commit` hooks, `update_githubio` is run. It will preemptively stop if:

* The command is not run on the `master` branch
* There already exists a version-object with the specified version in the `data.js` of the `ondewo.github.io` repository

> :warning:  This command is dependent on your installation of NPM and NodeJS -- Make sure to install both, or run `make setup_developer_environment_locally`
