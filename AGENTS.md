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
| `make` / `make build` | "Compiles" the dotfiles in memory to verify rendering (`chezmoi apply --dry-run`) |
| `make test` / `make check` | Runs the test suite: executes pre-commit linters and validates secret decryption |
| `make configure` | Initializes chezmoi configuration, prompting for age keys if missing |
| `make install` / `make apply` | Applies dotfiles to `$HOME` via `chezmoi apply` |

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

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any shell command containing `curl` or `wget` will be intercepted and blocked by the context-mode plugin. Do NOT retry.
Instead use:
- `context-mode_ctx_fetch_and_index(url, source)` to fetch and index web pages
- `context-mode_ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any shell command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` will be intercepted and blocked. Do NOT retry with shell.
Instead use:
- `context-mode_ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### Direct web fetching — BLOCKED
Do NOT use any direct URL fetching tool. Use the sandbox equivalent.
Instead use:
- `context-mode_ctx_fetch_and_index(url, source)` then `context-mode_ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Shell (>20 lines output)
Shell is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `context-mode_ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `context-mode_ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### File reading (for analysis)
If you are reading a file to **edit** it → reading is correct (edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `context-mode_ctx_execute_file(path, language, code)` instead. Only your printed summary enters context.

### grep / search (large results)
Search results can flood context. Use `context-mode_ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `context-mode_ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `context-mode_ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `context-mode_ctx_execute(language, code)` | `context-mode_ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `context-mode_ctx_fetch_and_index(url, source)` then `context-mode_ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `context-mode_ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `upgrade` MCP tool, run the returned shell command, display as checklist |
