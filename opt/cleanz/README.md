# cleanz

**Version**: run `cleanz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

cleanz removes hidden characters and formatting artifacts from text copied from LLM interfaces. It also strips metadata, C2PA included, from images. `help/cleanz.md` lists what it cleans.

---

## Installation

As part of the Utilz framework, `cleanz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz cleanz
```

---

## Usage

```bash
cleanz [OPTIONS] [FILE]
```

For detailed help: `utilz help cleanz`

---

## Implementation

### Architecture

```
cleanz
+-- Invoked via: $UTILZ_HOME/bin/cleanz (symlink)
+-- Dispatched by: $UTILZ_HOME/bin/utilz
+-- Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
+-- Trope patterns: $UTILZ_HOME/opt/cleanz/data/trope-indicators.txt
+-- Help from: $UTILZ_HOME/help/cleanz.md
```

### Dependencies

`help/cleanz.md` lists them. The script runs under bash 3.2, the bash that macOS ships.

---

## Testing

```bash
utilz test cleanz
```

---

## Development

### Making Changes

1. Edit `opt/cleanz/cleanz`
2. Test changes: `cleanz --help`
3. Run tests: `utilz test cleanz`
4. Update help if needed: `help/cleanz.md`

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2025 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [cleanz Help](../../help/cleanz.md) - Run: `utilz help cleanz`
