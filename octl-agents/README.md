# Octl Agents

Live [opencode](https://opencode.ai) agent status on the Noctalia bar, powered by
[octl](https://github.com/tomasWade/octl) — a session manager for the opencode v2
daemon. The bar widget shows how many agents are running and, crucially, how many
are **waiting for you**: permission prompts and errors turn the widget into the
alert color, so a stuck agent is visible from anywhere, not just in the terminal.

A companion panel lists every non-archived session grouped by state, with the
pending command, question, or error message right under the session title.

## Plugin

| Field | Value |
| --- | --- |
| ID | `tomaswade/octl-agents` |
| Entries | Bar widget: `status`; panel: `sessions`; service: `watcher` |

## Requirements

- `octl` on `PATH`, with its daemon running (`octl --daemon`); the plugin shells
  out to `octl query snaps --json` and treats a non-zero exit as "daemon offline".
- `noctalia` on `PATH` (the running shell binary — used to toggle the panel).

## Usage

Add the widget to a bar:

```toml
[widget.octl-agents]
type = "tomaswade/octl-agents:status"

[bar.default]
end = [ "octl-agents", "session" ]
```

Bar widget states, by priority:

- **Dim glyph** — daemon offline, or every session idle.
- **Accent color + count** — N sessions running (`BUSY`).
- **Alert color + count** — N sessions need you (`PERMISSION` prompts or `ERROR`).

Hover for a per-session breakdown (state marker + title + pending detail); click
to toggle the panel:

```sh
noctalia msg panel-toggle tomaswade/octl-agents:sessions
```

The panel groups sessions into *Waiting for you* / *Errors* / *Running* / *Idle*
and refreshes live while open.

## Settings

- **Poll interval (ms)** — how often the daemon is queried (500–60000, default 2000).
- **Bar glyph** — the glyph shown on the bar (default `brain`).
- **Busy color** — glyph/count color while agents run (default `primary`).
- **Alert color** — glyph/count color when attention is needed (default `error`).

## IPC

The service answers one probe event for debugging:

```sh
noctalia msg plugin tomaswade/octl-agents:watcher all dump
```

It dumps the current aggregated snapshot as JSON (also written to
`/tmp/opencode/octl-agents-dump.json`). Aside from that, the service only reads
(runs `octl query snaps --json` every poll); the widget and panel only run
`noctalia msg panel-toggle` on click. No network access.
