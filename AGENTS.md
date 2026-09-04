# AGENTS.md

Context for AI agents working in this repository.

## Repository Overview

This is a [chezmoi](https://www.chezmoi.io/) dotfiles repository. Chezmoi manages dotfiles by:
1. Storing source files here with special naming conventions
2. Transforming and installing them to `$HOME` when `chezmoi apply` runs

**This repository is NOT applied directly** - chezmoi processes files before installation.

## Agent operating rules

- Follow the active server's tool-routing and safety instructions. This file is
  repository guidance; it must not override the runtime's GitHub, filesystem,
  web, or shell policy or require unavailable tools.
- Treat every target as exactly one of: chezmoi-rendered source, external
  checkout/archive, package or binary, service definition, or runtime state.
  Identify its canonical owner before changing it, and do not claim package
  installation, service health, or workstation behavior from source validation.
- Do not run `make install`, `make apply`, `chezmoi apply`, package managers,
  or service-management commands. Those are owner-run workstation operations.
- Before changing a shell entrypoint or `~/.shellenv`, map all consumers:
  interactive/login Bash, login zsh, and POSIX wrapper scripts. Keep
  OS-native initialization in the native shell entrypoint; `~/.shellenv` must
  remain portable POSIX shell.
- Before changing an external mapping, establish its producer, update policy,
  pin/integrity model, and affected consumer. Do not assume an external clone
  or archive is a package installation.
- When adding or changing a secret consumer, update the non-production fixture
  and its scope assertions. Never print or persist decrypted values.

## Makefile Targets

| Target | Behavior |
|--------|----------|
| `make` / `make build` | "Compiles" the dotfiles in memory to verify rendering (`chezmoi apply --dry-run`) |
| `make test` / `make check` | Runs the test suite: executes pre-commit linters and validates secret decryption |
| `./configure` / `make setup` | Securely installs a missing age identity, then initializes chezmoi |
| `make install` / `make apply` | Applies dotfiles to `$HOME` via `chezmoi apply` |

`make` is safe and non-destructive. `make install` writes to `$HOME`.

## Naming Conventions

| Source Name | Installed As |
|------------|--------------|
| `dot_foo` | `~/.foo` |
| `dot_config/bar` | `~/.config/bar` |
| `foo.tmpl` | `foo` (template processed) |
| `encrypted_foo.age` | `foo` (decrypted) |
| `private_dot_foo` | `~/.foo` with group/world permissions removed |

See [chezmoi reference](https://www.chezmoi.io/reference/source-state-attributes/) for full attribute list.

## Files NOT Installed

Files in `.chezmoiignore` are excluded from installation. Treat that file as the authoritative list. It includes repository metadata and tooling, tests, secret-management sources, and platform-specific exclusions. The root `opencode.json` is a project-scoped OpenCode configuration for this checkout and is not installed into `$HOME`.

`~/.config/opencode` and `~/.config/mcp-gateway` are external Git checkouts whose application files are owned by the sibling `opencode-config` and `mcp-gateway` repositories. Keep the MCP gateway's macOS LaunchAgent, Linux systemd user unit, and encrypted secret rendering in this repository because those remain platform-specific chezmoi concerns.

**When adding repo-only files**, add them to `.chezmoiignore` under "Always ignore these" and to `.gitignore` when they are generated local state.

## Platform Handling

- `.chezmoiignore` uses Go templates to conditionally exclude files
- `.chezmoi.os` is `darwin` (macOS) or `linux`
- Templates (`.tmpl` files) can use `{{ if eq .chezmoi.os "darwin" }}` conditionals
- Platform-specific paths, package locations, and system initialization must be
  guarded by the platform and capability that provide them.

## Secrets

- Encrypted with [age](https://github.com/FiloSottile/age)
- Source files: `encrypted_*.age`
- Key location configured in `.chezmoi.toml.tmpl` (platform-specific paths)
- `make setup` reads a missing identity from hidden stdin and installs it atomically with owner-only permissions
- Templates access secrets via `include "encrypted_secrets.yaml.age" | decrypt`
- Secret-rendering templates must use a `private_` source-state attribute
- Shell tokens remain unexported and are injected only into command wrappers
  that require them, except the Cloudflare Access client ID and secret. Those
  are deliberately exported because multiple agent CLIs consume them.
- CI replaces the encrypted payload with non-production fixture secrets and runs the same rendering checks
- `make check` validates complete rendering and decryption
- Never commit unencrypted secrets

### Safe encrypted-secret editing

- Never run `chezmoi decrypt` by itself when its stdout is attached to a
  terminal, log, or agent context. Pipe decrypted data directly into the
  process that consumes it.
- Never put a secret in a command-line argument. Pass it through hidden stdin,
  a dedicated file descriptor, or an environment variable scoped to one child
  process, then unset the variable.
- Prefer an in-memory decrypt-transform-encrypt pipeline. Write only encrypted
  output to a same-directory temporary file and atomically replace the source
  after validating it:

  ```bash
  umask 077
  source=encrypted_secrets.yaml.age
  tmp=$(mktemp ".${source}.tmp.XXXXXX")
  trap 'rm -f "$tmp"' EXIT

  chezmoi decrypt "$source" \
    | SECRET_VALUE="$secret" <transform-command-reading-yaml-from-stdin> \
    | chezmoi encrypt --output "$tmp"

  chezmoi decrypt "$tmp" \
    | <validation-command-that-prints-no-values>
  mv "$tmp" "$source"
  trap - EXIT
  unset secret SECRET_VALUE
  ```

- The transform must preserve unrelated keys and must not print decrypted
  values. Validation may report key names, counts, types, or pass/fail status
  only.
- If plaintext temporary storage is unavoidable, use `umask 077`, keep it
  outside the repository, and remove it with a trap. An encrypted temporary
  file is still preferred.
- If an external system issues a token before encryption succeeds, revoke that
  token on failure so no unmanaged credential remains active.
- After replacement, run `make build` and the secret-decryption hooks. Do not
  use a diff command that renders secret-bearing destination contents.

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
4. **detect-private-key** - rejects committed private-key material
5. **detect-secrets** - rejects newly introduced credentials against the reviewed baseline
6. **shellcheck** - lints non-template bash scripts and `configure`
7. **commitizen** - enforces [Conventional Commits](https://www.conventionalcommits.org/)
8. **chezmoi-templates** - renders every `.tmpl` file
9. **chezmoi-doctor** - runs `chezmoi doctor` sanity checks and propagates failures
10. **chezmoi-dry-run** - renders a complete apply without modifying `$HOME`
11. **chezmoi-secrets-decrypt** - validates encrypted secret decryption and YAML parsing
12. **secret-template-permissions** - rejects secret-rendering templates without `private_`

### Running Manually

```bash
pre-commit run --all-files
```

For a manual hook refresh, use `pre-commit autoupdate --freeze` so hook
revisions remain immutable commit SHAs and retain their release comments.
Refresh `.secrets.baseline` with `detect-secrets scan --baseline
.secrets.baseline` when those public SHAs change, then stage the baseline before
running the full suite; the hook intentionally rejects an unstaged baseline.
Before changing the CI Python patch version, verify it exists for every matrix
platform and architecture in `actions/python-versions`' manifest; newer CPython
patches may be available on Linux before macOS arm64.

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

The job runs source validation on Linux and macOS with pinned tooling and
disposable fixture secrets. It does not apply dotfiles to a persistent host,
install packages, start services, or functionally verify external tools.
