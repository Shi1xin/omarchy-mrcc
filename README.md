# Liquid Cooler (Omarchy)

[中文](README.zh.md)

Bar widget for an LCT22002 external laptop AIO. Talks to the [`mrcc`](https://github.com/Shi1xin/mrcc) CLI only.

## Install

```bash
cargo install --git https://github.com/Shi1xin/mrcc.git --locked
omarchy plugin add https://github.com/Shi1xin/omarchy-mrcc.git --enable
```

`dbus`, `bluez`, and `bluez-utils` must already be installed. Put `~/.cargo/bin` on `PATH`.

Left-click the bar icon to open the panel. Right-click connects when disconnected, and disconnects when connected.

## License

MIT.
