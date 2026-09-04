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
make setup

# Preview a rendered apply without modifying $HOME
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
| `make` / `make build` | Render an apply as a dry-run without modifying `$HOME` |
| `make setup` / `make init` | Securely install a missing identity, then initialize chezmoi |
| `make install` | Apply dotfiles to `$HOME` |
| `make check` / `make test` | Run pre-commit hooks and verify age decryption |

## Platform handling

- **macOS**: Uses `.zprofile`, AeroSpace config; excludes `.bashrc.d/` and i3
- **Linux**: Uses `.bash_profile` → `.bashrc` → `.bashrc.d/`, i3 config; excludes `.zprofile` and AeroSpace

## Secrets

Secrets are encrypted with age. The encrypted file `encrypted_secrets.yaml.age` is decrypted at apply time using the platform-specific key path configured in `.chezmoi.toml.tmpl`. `make setup` creates a missing identity atomically with owner-only permissions. Secret-rendering targets use the `private_` attribute. Most shell tokens remain unexported and are injected only into their command wrappers: `ghorg` receives its clone token and `opencode_web` receives its web password. `GITHUB_MCP_TOKEN` is consumed by the mcp-gateway `bin/github` launcher after it sources `~/.shellenv`. The Cloudflare Access client ID and secret are an intentional exception: they are exported so supported agent CLIs can use them. Templates reference secrets via `include "encrypted_secrets.yaml.age" | decrypt`.

## AWS profiles

- `makeitwork` — Make IT Work Cloud AWS access. Use this profile for SOPS AWS KMS operations after the KMS recipient is configured, for example `AWS_PROFILE=makeitwork sops -e -i secrets.yaml`.

## Linting

Pre-commit hooks handle:
- Trailing whitespace and EOF fixes
- YAML validation
- Shellcheck for bash scripts
- Conventional Commits enforcement
- Chezmoi template validation
- Chezmoi doctor checks

## CI

GitHub Actions runs the full pre-commit suite on Linux and macOS using an ephemeral age identity and non-production fixture secrets. The rendered `~/.shellenv` is additionally sourced under `sh`, `zsh`, and `bash` to keep it portable across the macOS and Fedora shells. CI actions and validation tools are pinned to immutable versions or commits. External archives and checkouts have their own update and integrity policies in `.chezmoiexternal.toml.tmpl`; inspect that mapping before relying on an external source as pinned or checksummed.

## Credits

### Fonts

This repository includes the following third-party fonts:

- **Fixedsys Excelsior** (`FSEX.ttf`)
  - Source: https://github.com/kika/fixedsys
  - Original author: Darien Valentine
  - License: [CC0 1.0 Universal (Public Domain Dedication)](https://creativecommons.org/publicdomain/zero/1.0/)
  - Description: A TrueType bitmap font with programming ligatures, based on the classic Fixedsys typeface.

- **The Ultimate Oldschool PC Font Pack** (`Px437_IBM_VGA_*`)
  - Source: https://int10h.org/oldschool-pc-fonts/
  - Author: VileR
  - License: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
  - Description: Pixel-perfect reproductions of classic IBM VGA text mode fonts from DOS-era.
