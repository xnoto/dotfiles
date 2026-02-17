# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Prerequisites

- chezmoi installed
- pre-commit installed
- age key at one of:
  - **Linux**: `~/.config/sops/age/keys.txt`
  - **macOS**: `~/Library/Application Support/sops/age/keys.txt`

## Usage

```bash
# Install pre-commit hooks (first-time only)
pre-commit install
pre-commit install --hook-type commit-msg

# Initialize chezmoi with this repo as source
make

# Apply dotfiles to $HOME
make install

# Validate templates, linting, and secret decryption
make check

# Preview changes before applying
chezmoi diff --source=/path/to/this/repo
```

| Target | Behavior |
|--------|----------|
| `make` / `make init` | Initialize chezmoi with this repo as the source |
| `make install` | Apply dotfiles to `$HOME` |
| `make check` / `make test` | Run pre-commit hooks and verify age decryption |

## Platform handling

- **macOS**: Uses `.zprofile`, AeroSpace config; excludes `.bashrc.d/` and i3
- **Linux**: Uses `.bashrc.d/`, i3 config; excludes `.zprofile` and AeroSpace

## Secrets

Secrets are encrypted with age. The encrypted file `encrypted_secrets.yaml.age` is decrypted at apply time using the platform-specific key path configured in `.chezmoi.toml.tmpl`. Templates reference secrets via `include "encrypted_secrets.yaml.age" | decrypt`.

## Linting

Pre-commit hooks handle:
- Trailing whitespace and EOF fixes
- YAML validation
- Shellcheck for bash scripts
- Conventional Commits enforcement
- Chezmoi template validation
- Chezmoi doctor checks

## CI

GitHub Actions runs pre-commit on pull requests and pushes to `main`.
