# Utilz Test Suite

This directory holds the framework's own BATS suites and `test_helper.bash`, which every utility's suite loads. Each utility keeps its suites in `opt/<name>/test/`. Each file's header comment says what it covers and why.

## The suites here

| Area                 | Files                                                                                                                  |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| The dispatcher       | `dispatcher.bats`, `help_dispatch.bats`, `version_dispatch.bats`                                                       |
| The common library   | `common_lib.bats`, `isolation.bats`                                                                                    |
| Editor bridges       | `bridge.bats`                                                                                                          |
| End to end           | `integration.bats`                                                                                                     |
| Trees and publishing | `tree.bats`, `upgrade.bats`, `install_lib.bats`, `install_guards.bats`, `install_e2e.bats`, `keg.bats`, `formula.bats` |

`population_helper.bash` is the one home for the set of utilities that the sweeping suites walk (issue 0117). `stub-bin/` holds stubs, eg `gh`, that `test_helper.bash` puts first on `PATH` for every test.

## Run them

Build and test through `bin/devbin`, and only through it ([AGENTS.md](../../../AGENTS.md)):

```bash
bin/devbin test shell        # every shell suite
bin/devbin test estate       # every suite under the bash 3.2 macOS ships
```

To run one utility's suites, use `utilz test <name>`, from the tree's own `bin/`. To run one file, use `bats opt/utilz/test/<file>.bats`, and add `-f '<name pattern>'` for one test. Where `intent estate status` shows a controller, ask it for a slot first.

The suites that publish a fake checkout (`make_fake_src`, `publish_checkout_copy`) run devbin under bash 5 or later, through `run_devbin`. `keg.bats` refuses a linked worktree, because its fixture commits inside a copy of `.git`. Run it from a primary checkout.

## Write them

[docs/developer-guide.md](../../../docs/developer-guide.md#writing-tests) says how to write a suite, which helpers to use and how to keep the user's state out of a test. `test_helper.bash` is the reference for each helper.
