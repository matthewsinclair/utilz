# GitHub Actions Workflows

Each workflow's comments say why each step is as it is. This file names the jobs and when they run.

## Utilz Tests (`tests.yml`)

It runs on a push to `main` or to `candidate/**`, on a pull request to `main`, and on a manual dispatch. A push that changes only `intent/whiteboard/` and `intent/.canon/` starts no run. A newer push cancels the run it supersedes. No tag starts a run: the release core pushes the release commit to `candidate/<tag>` and reads CI there before it tags ([docs/releasing.md](../../docs/releasing.md)).

| Job            | Name                  | When                                                   | What it does                                                                                           |
| -------------- | --------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `test-linux`   | Test on Ubuntu        | every run                                              | `tools/ci-suites` on Ubuntu, with bats-core 1.12.0                                                     |
| `test-macos`   | Test on macOS         | candidate push, dispatch                               | `tools/ci-suites` on macOS, with Homebrew's bats-core                                                  |
| `shellcheck`   | Shell Script Analysis | every run                                              | `shellcheck -x` on every shell file under `bin/` and `opt/`, sourced `*.sh` libraries included         |
| `rust`         | Rust (os)             | Ubuntu every run, macOS on candidate push and dispatch | Each crate's build and tests, and prez's `crate/test/*.sh` suites, with a cargo cache, bound at 25 min |
| `clippy`       | Rust Lint (clippy)    | every run                                              | `cargo fmt --check` and clippy with `-D warnings`, on every crate                                      |
| `menuz-app`    | menuz app (macOS)     | candidate push, dispatch                               | Menuz.app built and tested by Xcode, unsigned                                                          |
| `test-summary` | Test Summary          | every run that is not cancelled                        | Reads every job's result, and fails when one failed                                                    |

Every job fails the run when it fails. `tools/ci-suites` is the one roster for both test jobs. It runs `utilz test` for the dispatcher, then each utility's suite. For prez it runs `prez.bats` alone, because the `rust` job builds and tests prez's crate. The file says why.

## PR Checks (`pr-checks.yml`)

It runs on a pull request. Its jobs are `check-documentation`, `test-coverage`, `commit-message-check`, `pr-size-check` and `utility-metadata-check`.

## Run the tests locally

Build and test through `bin/devbin`, and only through it: `bin/devbin test <rust|shell|estate|all>`. Where `intent estate status` shows a controller, ask it for a slot first ([AGENTS.md](../../AGENTS.md)). [docs/developer-guide.md](../../docs/developer-guide.md) says how to add a utility and its tests.
