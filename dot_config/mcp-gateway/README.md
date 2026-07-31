# MCP gateway

This directory runs local stdio MCP servers once and exposes each server over
Streamable HTTP for OpenCode, Claude Code, and Codex. A small Node supervisor
runs one `mcp-proxy` process per server so a failed credential, VPN, or Podman
dependency cannot prevent unrelated MCP servers from starting.

Each proxy listens only on a dedicated localhost port recorded in
`servers.json`, with its MCP endpoint at `http://127.0.0.1:<port>/mcp`. The
supervisor probes `tools/list` and restarts only the failed proxy after repeated
protocol failures.

## Dependencies

On macOS, the managed Brewfile provides `node`, `uv`, `podman`, and `tmux`.

On Fedora Linux, install `nodejs`, `uv`, `podman`, and `tmux` with the system
package manager. The gateway uses `npx` and `uvx` to run pinned MCP packages.

## Services

After applying the dotfiles, load the service for the current platform.

### macOS

```sh
launchctl bootout "gui/$(id -u)/com.xnoto.mcp-gateway" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.xnoto.mcp-gateway.plist"
```

### Fedora Linux

```sh
systemctl --user daemon-reload
systemctl --user enable mcp-gateway.service
systemctl --user restart mcp-gateway.service
```

## Verification

```sh
"$HOME/.config/mcp-gateway/healthcheck"
```

The Grafana and Argo CD launchers source the private `~/.shellenv` file and
export only the credential required by that MCP server.

Context-mode remains a client-local MCP because it owns per-session capture
and compaction behavior; it is not routed through this shared gateway.

The endpoints are unauthenticated and intentionally bound to loopback. Do not
forward or expose these ports to other hosts.

On macOS, initialize and start the Podman machine before using the
`terraform-docs` endpoint.
