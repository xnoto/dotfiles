# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Prerequisites

- chezmoi installed
- age key at one of:
  - **Linux**: `~/.config/sops/age/keys.txt`
  - **macOS**: `~/Library/Application Support/sops/age/keys.txt`

## Usage

```bash
# First-time setup (clone and apply)
chezmoi init --source=/path/to/this/repo --apply

# Or if using as the source directory directly
chezmoi init --apply

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Edit a managed file
chezmoi edit ~/.config/alacritty.toml
```

## Platform handling

- **macOS**: Uses `.zprofile`, excludes `.bashrc.d/` and i3
- **Linux**: Uses `.bashrc.d/`, excludes `.zprofile`

## Secrets

Secrets are encrypted with age. The encrypted file `encrypted_secrets.yaml.age` is decrypted at apply time using the platform-specific key path configured in `.chezmoi.toml.tmpl`.

## Linting

Pre-commit hooks are configured for:
- Trailing whitespace and EOF fixes
- YAML validation
- Shellcheck for bash scripts
- Conventional Commits enforcement
- Chezmoi template validation
- Chezmoi doctor checks

```bash
# Install pre-commit hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run manually
pre-commit run --all-files

# Or use chezmoi directly
chezmoi verify
chezmoi doctor
```
