# AGENTS.md

Context for AI agents working in this repository.

## Repository Overview

This is a [chezmoi](https://www.chezmoi.io/) dotfiles repository. Chezmoi manages dotfiles by:
1. Storing source files here with special naming conventions
2. Transforming and installing them to `$HOME` when `chezmoi apply` runs

**This repository is NOT applied directly** - chezmoi processes files before installation.

## Makefile Targets

| Target | Behavior |
|--------|----------|
| `make` / `make check` / `make test` | Validate only: runs pre-commit and verifies secret decryption |
| `make install` | Applies dotfiles to `$HOME` via `chezmoi init` + `chezmoi apply` |

`make` is safe and non-destructive. `make install` writes to `$HOME`.

## Naming Conventions

| Source Name | Installed As |
|------------|--------------|
| `dot_foo` | `~/.foo` |
| `dot_config/bar` | `~/.config/bar` |
| `foo.tmpl` | `foo` (template processed) |
| `encrypted_foo.age` | `foo` (decrypted) |

See [chezmoi reference](https://www.chezmoi.io/reference/source-state-attributes/) for full attribute list.

## Files NOT Installed

Files in `.chezmoiignore` are excluded from installation. Currently:
- `README.md`, `LICENSE`, `Makefile`, `AGENTS.md`
- `secrets/`, `.sops.yaml`, `secrets.yaml`
- Platform-specific exclusions (see file for details)

**When adding repo-only files**, add them to `.chezmoiignore` under "Always ignore these".

## Platform Handling

- `.chezmoiignore` uses Go templates to conditionally exclude files
- `.chezmoi.os` is `darwin` (macOS) or `linux`
- Templates (`.tmpl` files) can use `{{ if eq .chezmoi.os "darwin" }}` conditionals

## Secrets

- Encrypted with [age](https://github.com/FiloSottile/age)
- Source files: `encrypted_*.age`
- Key location configured in `.chezmoi.toml.tmpl` (platform-specific paths)
- Templates access secrets via `include "encrypted_secrets.yaml.age" | decrypt`
- The `chezmoi-templates` pre-commit hook **skips** files containing `decrypt` (can't resolve `include` from stdin)
- `make check` separately validates decryption via `chezmoi cat`
- Never commit unencrypted secrets

## Pre-commit Checks

**Both hooks must be installed:**
```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

### Hooks

1. **end-of-file-fixer** - ensures files end with newline
2. **trailing-whitespace** - removes trailing whitespace
3. **check-yaml** - validates YAML syntax
4. **shellcheck** - lints bash scripts in `dot_bashrc.d/` (excludes `.tmpl`)
5. **commitizen** - enforces [Conventional Commits](https://www.conventionalcommits.org/)
6. **chezmoi-templates** - validates `.tmpl` syntax (skips files with `decrypt`/`output`)
7. **chezmoi-doctor** - runs `chezmoi doctor` sanity checks

### Running Manually

```bash
pre-commit run --all-files
```

## Commit Messages

Must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

# Examples:
feat: add alacritty config
fix: correct path in zprofile template
chore: update pre-commit hooks
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

## CI

GitHub Actions (`.github/workflows/lint.yaml`) runs pre-commit on:
- Pull requests to `main`
- Pushes to `main`
