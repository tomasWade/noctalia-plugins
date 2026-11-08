# noctalia-plugins

A [Noctalia](https://github.com/noctalia-dev/noctalia) plugin source. Point Noctalia at this
repo (or a local clone) and enable the plugins you want:

```sh
noctalia msg plugins source add noctalia-plugins path /path/to/noctalia-plugins
noctalia msg plugins enable haotianyu/proxy-toggle
```

## proxy-toggle

A **stateful control-center toggle tile** for a `systemd --user` tunnel service —
built for, but not limited to, a [sing-box](https://github.com/SagerNet/sing-box)
TUN setup (any `proxy / VPN / tunnel` unit works).

- A headless service polls `systemctl --user is-active <unit>` every 2 seconds.
- The control-center tile lights up while the service is running and dims when it
  is not — same look as the built-in Wi-Fi / Bluetooth tiles.
- Clicking the tile runs your toggle command (e.g. a small script doing
  `systemctl --user start/stop` with a desktop notification).

### Add the tile

```toml
[[control_center.shortcuts]]
type = "haotianyu/proxy-toggle:toggle"
```

### Settings

Settings are edited under **Settings → Plugins** (gear icon) or via
`[plugin_settings."haotianyu/proxy-toggle"]` in Noctalia's state settings.

| Key              | Default               | Description                                    |
| ---------------- | --------------------- | ---------------------------------------------- |
| `unit`           | `proxy-tunnel`        | systemd --user unit to watch (no `.service`)   |
| `toggle_command` | `proxy-tunnel-toggle` | Command executed on click                      |
| `label`          | `Proxy`               | Text under the tile                            |
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

plus a tiny toggle script on `PATH` (`proxy-tunnel-toggle`) that flips the unit
and sends a notification. Give sing-box's binary `cap_net_admin` (`setcap`) and
no password is needed to start or stop the tunnel.

## License

[MIT](LICENSE)
