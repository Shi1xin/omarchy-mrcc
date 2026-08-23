# Liquid Cooler（Omarchy）

[English](README.md)

LCT22002 外置水冷的栏插件。只调用 [`mrcc`](https://github.com/Shi1xin/mrcc) CLI。

## 安装

```bash
cargo install --git https://github.com/Shi1xin/mrcc.git --locked
omarchy plugin add https://github.com/Shi1xin/omarchy-mrcc.git --enable
```

需要已安装 `dbus`、`bluez`、`bluez-utils`，并把 `~/.cargo/bin` 加入 `PATH`。

左键点栏图标打开面板。右键：未连接时连接，已连接时断开。

## 许可证

MIT.
