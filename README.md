# noctalia-plugins

A [Noctalia](https://github.com/noctalia-dev/noctalia) plugin source.

## proxy-toggle

A **stateful control-center toggle tile** for a `systemd --user` tunnel service —
built for, but not limited to, a [sing-box](https://github.com/SagerNet/sing-box)
TUN setup (any `proxy / VPN / tunnel` unit works).

- A headless service polls `systemctl --user is-active <unit>` every 2 seconds.
- The control-center tile lights up while the service is running and dims when it
  is not — same look as the built-in Wi-Fi / Bluetooth tiles.
- Clicking the tile runs your toggle command (e.g. a small script doing
  `systemctl --user start/stop` with a desktop notification).

### Install

Add this repo as a plugin source (no clone needed):

```sh
noctalia msg plugins source add noctalia-plugins git https://github.com/tomasWade/noctalia-plugins
noctalia msg plugins enable tomasWade/proxy-toggle
```

Or add a local clone instead: `noctalia msg plugins source add noctalia-plugins path /path/to/noctalia-plugins`

Then add the tile to your control center:

```toml
[[control_center.shortcuts]]
type = "tomasWade/proxy-toggle:toggle"
```

> **Note:** the control center shows up to **6** shortcut tiles. If the tile
> does not appear, check whether your `[[control_center.shortcuts]]` list
> already has six entries — define an explicit list that includes this one.

A Noctalia restart is needed for a newly added shortcut tile to show up.

### Settings

Settings are edited under **Settings → Plugins** (gear icon) or via
`[plugin_settings."tomasWade/proxy-toggle"]` in Noctalia's state settings.

| Key              | Default               | Description                                    |
| ---------------- | --------------------- | ---------------------------------------------- |
| `unit`           | `proxy-tunnel`        | systemd --user unit to watch (no `.service`)   |
| `toggle_command` | `proxy-tunnel-toggle` | Command executed on click                      |
| `label`          | `Proxy`               | Text shown under the tile                      |
| `icon`           | `world`               | Glyph name for the tile                        |

### Suggested pairing

Any transparent-proxy unit qualifies. For a sing-box TUN tunnel, a typical
setup is a user unit like:

```ini
# ~/.config/systemd/user/proxy-tunnel.service
[Unit]
Description=Global proxy tunnel (sing-box TUN)
After=network-online.target

[Service]
ExecStart=/usr/bin/sing-box run -c %h/.config/sing-box/tunnel.json
Restart=on-failure

[Install]
WantedBy=default.target
```

a toggle script on `PATH` as `proxy-tunnel-toggle`:

```sh
#!/usr/bin/env sh
if systemctl --user is-active --quiet proxy-tunnel; then
    systemctl --user stop proxy-tunnel \
        && notify-send -t 2500 "Proxy" "tunnel off · direct"
else
    systemctl --user start proxy-tunnel \
        && notify-send -t 2500 "Proxy" "tunnel on · routed via tunnel"
fi
```

and `cap_net_admin` on the sing-box binary so the user unit needs no password:

```sh
sudo setcap cap_net_admin,cap_net_raw+ep "$(command -v sing-box)"
```

For a bar-side running indicator to go with the tile, see the community
`sing-box-status` widget.

## License

[MIT](LICENSE)
