#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - WebSocket Proxy Services Setup
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/usr/local/mzeekobe"
MODULE_DIR="$INSTALL_DIR/module"

install_ws_proxy() {
    echo -e "${YELLOW}[*] Installing ws.py (SSH WebSocket proxy on port 700)...${NC}"

    cat > /etc/systemd/system/mzeekobe-ws.service << EOF
[Unit]
Description=Mzee Kobe WS Proxy (ws.py:700)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $MODULE_DIR/ws.py -b 127.0.0.1 -p 700
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mzeekobe-ws
    systemctl start mzeekobe-ws

    if systemctl is-active --quiet mzeekobe-ws; then
        echo -e "${GREEN}[OK] ws.py running on 127.0.0.1:700${NC}"
    else
        echo -e "${RED}[!] ws.py failed to start${NC}"
    fi
}

install_dropbear_ws() {
    echo -e "${YELLOW}[*] Installing dropbear-ws.py (Dropbear WebSocket proxy on port 8880)...${NC}"

    cat > /etc/systemd/system/mzeekobe-dropbear-ws.service << EOF
[Unit]
Description=Mzee Kobe Dropbear WS Proxy (port 8880)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $MODULE_DIR/dropbear-ws.py -b 0.0.0.0 -p 8880
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
        echo -e "${GREEN}[OK] dropbear-ws.py running on 0.0.0.0:8880${NC}"
    else
        echo -e "${RED}[!] dropbear-ws.py failed to start${NC}"
    fi
}

install_openvpn_wss() {
    echo -e "${YELLOW}[*] Installing openvpn-wss.py (OpenVPN WebSocket proxy on port 900)...${NC}"

    cat > /etc/systemd/system/mzeekobe-ovpn-ws.service << EOF
[Unit]
Description=Mzee Kobe OpenVPN WSS Proxy (port 900)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $MODULE_DIR/openvpn-wss.py -b 0.0.0.0 -p 900
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mzeekobe-ovpn-ws
    systemctl start mzeekobe-ovpn-ws

    if systemctl is-active --quiet mzeekobe-ovpn-ws; then
        echo -e "${GREEN}[OK] openvpn-wss.py running on 0.0.0.0:900${NC}"
    else
        echo -e "${RED}[!] openvpn-wss.py failed to start${NC}"
    fi
}

install_all() {
    install_ws_proxy
    install_dropbear_ws
    install_openvpn_wss
}

status_ws() {
    echo -e "${CYAN}[*] WebSocket Proxy Services:${NC}"
    local services=("mzeekobe-ws" "mzeekobe-dropbear-ws" "mzeekobe-ovpn-ws")
    local ports=("700" "8880" "900")
    for i in "${!services[@]}"; do
        svc="${services[$i]}"
        port="${ports[$i]}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  $svc (port $port): ${GREEN}RUNNING${NC}"
        else
            echo -e "  $svc (port $port): ${RED}STOPPED${NC}"
        fi
    done
}

restart_all() {
    for svc in mzeekobe-ws mzeekobe-dropbear-ws mzeekobe-ovpn-ws; do
        systemctl restart "$svc" 2>/dev/null
    done
    echo -e "${GREEN}[OK] All WebSocket services restarted.${NC}"
}

stop_all() {
    for svc in mzeekobe-ws mzeekobe-dropbear-ws mzeekobe-ovpn-ws; do
        systemctl stop "$svc" 2>/dev/null
    done
    echo -e "${YELLOW}[*] All WebSocket services stopped.${NC}"
}

case "${1}" in
    install) install_all ;;
    ws)      install_ws_proxy ;;
    dropbear) install_dropbear_ws ;;
    openvpn) install_openvpn_wss ;;
    status)  status_ws ;;
    restart) restart_all ;;
    stop)    stop_all ;;
    *)       install_all ;;
esac
