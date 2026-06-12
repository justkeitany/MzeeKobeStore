#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - SSH WebSocket Proxy Setup
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/usr/local/mzeekobe"
WS_SCRIPT="$INSTALL_DIR/module/ws.py"
SERVICE_FILE="/etc/systemd/system/mzeekobe-proxy.service"

install_sshws() {
    echo -e "${YELLOW}[*] Setting up SSH WebSocket proxy...${NC}"

    # Ensure ws.py exists
    if [ ! -f "$WS_SCRIPT" ]; then
        echo -e "${RED}[!] ws.py not found at $WS_SCRIPT${NC}"
        return 1
    fi

    # Create systemd service
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Mzee Kobe SSH WebSocket Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $WS_SCRIPT -b 127.0.0.1 -p 700
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mzeekobe-proxy
    systemctl start mzeekobe-proxy

    if systemctl is-active --quiet mzeekobe-proxy; then
        echo -e "${GREEN}[OK] SSH WebSocket proxy started on 127.0.0.1:700${NC}"
    else
        echo -e "${RED}[!] Proxy failed to start. Check: journalctl -u mzeekobe-proxy${NC}"
    fi
}

install_dropbear_ws() {
    echo -e "${YELLOW}[*] Setting up Dropbear WebSocket proxy...${NC}"

    local DROPBEAR_WS="$INSTALL_DIR/module/dropbear-ws.py"
    if [ ! -f "$DROPBEAR_WS" ]; then
        echo -e "${RED}[!] dropbear-ws.py not found${NC}"
        return 1
    fi

    cat > /etc/systemd/system/mzeekobe-dropbear-ws.service << EOF
[Unit]
Description=Mzee Kobe Dropbear WebSocket (port 80)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $DROPBEAR_WS -b 0.0.0.0 -p 80
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mzeekobe-dropbear-ws
    systemctl start mzeekobe-dropbear-ws

    if systemctl is-active --quiet mzeekobe-dropbear-ws; then
        echo -e "${GREEN}[OK] Dropbear WebSocket proxy started on 0.0.0.0:80${NC}"
    else
        echo -e "${RED}[!] Dropbear-ws failed to start.${NC}"
    fi
}

status_sshws() {
    echo -e "${CYAN}[*] SSH WebSocket Services:${NC}"
    for svc in mzeekobe-proxy mzeekobe-dropbear-ws; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  $svc: ${GREEN}RUNNING${NC}"
        else
            echo -e "  $svc: ${RED}STOPPED${NC}"
        fi
    done
}

restart_sshws() {
    systemctl restart mzeekobe-proxy 2>/dev/null
    systemctl restart mzeekobe-dropbear-ws 2>/dev/null
    echo -e "${GREEN}[OK] WebSocket services restarted.${NC}"
}

case "${1}" in
    install)
        install_sshws
        install_dropbear_ws
        ;;
    dropbear)
        install_dropbear_ws
        ;;
    status)
        status_sshws
        ;;
    restart)
        restart_sshws
        ;;
    *)
        install_sshws
        install_dropbear_ws
        ;;
esac
