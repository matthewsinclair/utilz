# arngz

**Version**: run `arngz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Named window arrangements (desks) across displays and spaces. Hammerspoon is the engine, through its `hs` tool.

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
arngz <apply|discover|diff|list|show|delete|current|which|auto|init|doctor|log> [ARGS]
```

For detailed help: `utilz help arngz`

---

## Implementation

### Architecture

```
arngz
├── Invoked via: $UTILZ_HOME/bin/arngz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
├── Engine: $UTILZ_HOME/opt/arngz/lib/*.lua, loaded by Hammerspoon
└── Help from: $UTILZ_HOME/help/arngz.md
```

### Dependencies

`arngz.yaml` declares them, and `help/arngz.md` says what each one is for. The CLI runs under bash 3.2.

---

## Testing

```bash
utilz test arngz
```

---

## Development

### Making Changes

1. Edit `opt/arngz/arngz`, or the engine in `opt/arngz/lib/`
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
