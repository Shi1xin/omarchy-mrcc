#!/bin/bash
set -euo pipefail
BIN=""
if command -v mrcc >/dev/null 2>&1; then
  BIN=$(command -v mrcc)
elif [[ -x "${HOME}/.cargo/bin/mrcc" ]]; then
  BIN="${HOME}/.cargo/bin/mrcc"
else
  exit 0
fi
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$UNIT_DIR"
cat > "${UNIT_DIR}/mrcc-session.service" <<EOF
[Unit]
Description=Stop LCT22002 pump when the graphical session ends
PartOf=graphical-session.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=${BIN} disconnect
Environment=PATH=${HOME}/.cargo/bin:/usr/local/bin:/usr/bin

[Install]
WantedBy=graphical-session.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now mrcc-session.service >/dev/null
EOF
