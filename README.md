# Sandboxed Claude Code

Run the [Claude Code](https://claude.ai/claude-code) CLI inside an isolated Docker container, kept separate from your host system.

## Overview

This repository packages the Claude Code CLI into a disposable Ubuntu container so you can use it without giving it direct access to your host machine. The container:

- runs as an unprivileged user (`claudia`),
- mounts **only** your current working directory and a dedicated config directory,
- loads its credentials and runtime options from a local `.env` file,
- routes API traffic through a configurable base URL (useful for a local proxy or gateway).

Each run is ephemeral (`--rm`): the container is discarded on exit, while your work and Claude config persist on the host via bind mounts.

## Prerequisites

- **Docker** and **Docker Compose** (the `docker compose` plugin).
- **`socat`** on the host — only needed for the WSL launch path (see [Usage](#usage)).
- A configured **`.env`** file in the repository root (see [Configuration](#configuration)).

## Configuration

### `.env`

Create a `.env` file in the repository root. It is **gitignored** and must be supplied by you — never commit it. Document values are omitted here on purpose; set your own.

| Variable | Purpose |
| --- | --- |
| `ANTHROPIC_AUTH_TOKEN` | Authentication token used by Claude Code. |
| `ANTHROPIC_BASE_URL` | API base URL. Point this at your proxy/gateway (e.g. the host-local service bridged on WSL). |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Model ID used for the "opus" tier. |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Model ID used for the "sonnet" tier. |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Model ID used for the "haiku" tier. |
| `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` | OpenTelemetry metrics endpoint. |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | OTLP protocol (e.g. `http/protobuf`). |
| `OTEL_METRICS_EXPORTER` | OTel metrics exporter to use. |

Additional optional toggles (telemetry, experimental features, etc.) are included as commented-out entries in `.env`; uncomment the ones you need.

> Tip: consider adding a committed `.env.example` listing these variable names (without values) so collaborators know what to set.

### `settings.json`

Claude Code settings mounted into the container at `/home/claudia/.claude/settings.json`. Defaults:

```json
{
  "model": "opus",
  "theme": "auto"
}
```

## Build

Build the image (tagged `myself/claude:1.0` per `docker-compose.yml`):

```bash
docker compose build
```

## Usage

Run the launch script for your platform **from the directory you want Claude to work in** — that directory is mounted into the container as the working directory.

### macOS

```bash
./run.mac.sh
```

### WSL

```bash
./run.wsl.sh
```

On WSL the script additionally starts a `socat` listener that bridges
`172.17.0.1:7755` (the Docker bridge interface, reachable from the container) to
`127.0.0.1:6655` (a host-local service, e.g. the endpoint behind
`ANTHROPIC_BASE_URL`). The listener is torn down automatically when the
container exits.

### What gets mounted

| Host | Container |
| --- | --- |
| `$(pwd)` (your current directory) | `/home/claudia/work` |
| `./.claude_config` | `/home/claudia/.claude` |

Your work stays in the current directory; Claude Code configuration and state persist in `./.claude_config` across runs.

## Project structure

```
.
├── Dockerfile          # Ubuntu 26.04 image with Claude Code installed
├── docker-compose.yml  # `claude` service definition
├── run.mac.sh          # Launch on macOS
├── run.wsl.sh          # Launch on WSL (sets up the socat bridge)
├── soac.sh             # Standalone socat bridge command
├── test.sh             # Debug helper (prints pwd + resolved compose path)
├── settings.json       # Claude Code settings (mounted into the container)
└── .env                # Credentials & runtime config (gitignored — create your own)
```

The `Dockerfile` builds on `ubuntu:26.04`, creates an administrative user
(`admuser`, with sudo) and an unprivileged user (`claudia`), installs Claude
Code via the official `install.sh`, and wires up `HOME`, `CLAUDE_CONFIG_DIR`,
and `PATH`.

## Notes & troubleshooting

- **Ephemeral containers** — runs use `--rm`, so the container is removed on exit. Persisted state lives in the bind-mounted `./.claude_config` directory.
- **`test.sh`** is a debug helper that prints the current directory and the resolved `docker-compose.yml` path; it does not launch anything.
- If Claude can't reach the API on WSL, verify the `socat` bridge is running and that `ANTHROPIC_BASE_URL` matches the bridged port.
