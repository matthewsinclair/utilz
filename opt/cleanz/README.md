# cleanz

**Version**: run `cleanz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

cleanz removes hidden characters and formatting artifacts from text copied from LLM interfaces. It also strips metadata, C2PA included, from images. `help/cleanz.md` lists what it cleans.

---

## Installation

`cleanz` comes with Utilz. Once Utilz is installed, as the [README](../../README.md#installation) says, `cleanz` is on your PATH.

---

## Usage

```bash
cleanz [OPTIONS] [FILE]
```

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

`cleanz.yaml` declares them, and `help/cleanz.md` says what each one is for. The script runs under bash 3.2, the bash that macOS ships.

---

## Testing

```bash
utilz test cleanz
```

---

## Development

### Making Changes

1. Edit `opt/cleanz/cleanz`
2. Update help if needed: `help/cleanz.md`

---

## License

MIT. See [LICENSE](../../LICENSE).

---

## See Also

- [cleanz Help](../../help/cleanz.md) - Run: `utilz help cleanz`
