# cryptz

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`cryptz` - GPG encryption and decryption utility

---

## Synopsis

```bash
cryptz encrypt <input> [output] [--email <address>]
cryptz decrypt <input> [output]
```

---

## Description

A thin, predictable wrapper over GPG for the two things you actually do with it: encrypt a file to a recipient, and decrypt one back. It decides the output filename for you unless you name one -- `encrypt` appends `.gpg`, `decrypt` strips it (or appends `.decrypted` when the input was not named `.gpg`) -- so the round trip needs no bookkeeping.

It is not a key manager. It creates no keys, imports none, and edits no GPG configuration; the recipient must already be in your keyring. `gpg` itself is a hard requirement and is reported by `utilz doctor`.

---

## Commands

| Command                    | Description                                                       |
| -------------------------- | ----------------------------------------------------------------- |
| `encrypt <input> [output]` | Encrypt a file to a recipient. Output defaults to `<input>.gpg`   |
| `decrypt <input> [output]` | Decrypt a file. Output defaults to `<input>` with `.gpg` stripped |

## Options

### Encrypt Options

| Option              | Description                                              |
| ------------------- | -------------------------------------------------------- |
| `--email <address>` | Recipient key to encrypt to. Defaults to `$CRYPTZ_EMAIL` |

### General Options

| Option         | Description              |
| -------------- | ------------------------ |
| `-h`, `--help` | Show help message        |
| `--version`    | Show version information |

---

## Examples

### Basic Usage

```bash
# Show help
cryptz --help

# Show version
cryptz --version
```

---

## Files

- `$UTILZ_HOME/opt/cryptz/cryptz` - Implementation
- `$UTILZ_HOME/opt/cryptz/cryptz.yaml` - Metadata
- `$UTILZ_HOME/bin/cryptz` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - General error

---

## See Also

- `utilz(1)` - Utilz framework dispatcher
- `utilz-help(1)` - Show help for utilities
- [cryptz README]($UTILZ_HOME/opt/cryptz/README.md) - Detailed documentation

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
