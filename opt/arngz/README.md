# arngz

**Version**: run `arngz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Named window arrangements (desks) across displays and spaces. A desk says, for each display and each space on it, which apps live there and where on a grid their windows sit; `arngz <desk>` restores it. ST0026 builds it in work packages: the desk catalogue and its validator are in (WP-02), and the verbs that need Hammerspoon say which work package builds them.

---

## Installation

As part of the Utilz framework, `arngz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz arngz
```

---

## Usage

```bash
arngz <desk>
arngz <apply|discover|diff|list|show|delete|init|doctor> [ARGS]
```

For detailed help: `utilz help arngz`

---

## Examples

```bash
arngz init          # create the catalogue
arngz list          # each desk, with display and app counts
arngz show zeop1    # one desk, validated
```

---

## Implementation

### Architecture

```
arngz
├── Invoked via: $UTILZ_HOME/bin/arngz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/arngz.md
```

### Dependencies

**Required:**

- `yq`, which reads and validates desks

**Optional** (needed by `apply` and `discover`, which later work packages build):

- Hammerspoon, the engine, a macOS app that `utilz doctor` looks up by bundle id
- `hs`, Hammerspoon's command-line tool

The CLI runs under bash 3.2.

---

## Testing

```bash
# Run tests
utilz test arngz

# Run tests directly
cd opt/arngz/test
bats arngz.bats
```

---

## Development

### Making Changes

1. Edit `opt/arngz/arngz`
2. Test changes: `arngz --help`
3. Run tests: `utilz test arngz`
4. Update help if needed: `help/arngz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [arngz Help](../../help/arngz.md) - Run: `utilz help arngz`
