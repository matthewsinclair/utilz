# cryptz

**Version**: run `cryptz --version`
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

A thin wrapper over GPG. It encrypts a file to a recipient, and decrypts a file back. If you do not name an output file, cryptz names it: `encrypt` appends `.gpg`, and `decrypt` strips `.gpg`. If the input name does not end in `.gpg`, `decrypt` appends `.decrypted`.

It is not a key manager. It creates no keys, imports no keys, and changes no GPG configuration. The recipient key must be in your keyring. cryptz requires `gpg`, and `utilz doctor` reports it.

---

## Commands

| Command                    | Description                    |
| -------------------------- | ------------------------------ |
| `encrypt <input> [output]` | Encrypt a file to a recipient. |
| `decrypt <input> [output]` | Decrypt a file.                |

## Options

### Encrypt Options

| Option              | Description                                                                |
| ------------------- | -------------------------------------------------------------------------- |
| `--email <address>` | Recipient key. Defaults to `$CRYPTZ_EMAIL`, else to an address in the code |

### General Options

| Option         | Description              |
| -------------- | ------------------------ |
| `-h`, `--help` | Show help message        |
| `--version`    | Show version information |

---

## Examples

### Basic Usage

```bash
# Encrypt file.txt to file.txt.gpg, for the default recipient
cryptz encrypt file.txt

# Encrypt to a named output, for a named recipient
cryptz encrypt --email user@example.com file.txt encrypted.gpg

# Decrypt file.txt.gpg to file.txt
cryptz decrypt file.txt.gpg
```

---

## Files

- `$UTILZ_HOME/opt/cryptz/cryptz` - Implementation
- `$UTILZ_HOME/opt/cryptz/cryptz.yaml` - Metadata
- `$UTILZ_HOME/bin/cryptz` - Symlink to dispatcher

---

## Environment

- `CRYPTZ_EMAIL` - Default recipient for `encrypt`

---

## Exit Status

- `0` - Success
- `1` - Error: an unknown command, no input, input not found, too many arguments, `gpg` not found, or `gpg` failed

---

## See Also

- `utilz help` - Utilz framework help
- `gpg(1)` - GnuPG

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
