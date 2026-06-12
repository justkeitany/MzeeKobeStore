#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - UDP Custom / BadVPN UDPGW Setup
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/usr/local/mzeekobe"
BADVPN_BIN="/usr/bin/badvpn"
BADVPN_PORT="7300"
UDPCUSTOM_PORT="36712"
UDPCUSTOM_BIN="/usr/bin/udp-custom"

install_badvpn() {
    echo -e "${YELLOW}[*] Installing BadVPN UDPGW...${NC}"

    # Copy badvpn binary from module (pre-compiled)
    if [ -f "$INSTALL_DIR/module/badvpn-udpgw" ]; then
        cp "$INSTALL_DIR/module/badvpn-udpgw" "$BADVPN_BIN"
        chmod +x "$BADVPN_BIN"
        echo -e "${GREEN}[OK] BadVPN binary installed.${NC}"
    else
        # Try to download
        wget -q "https://github.com/ambrop72/badvpn/releases/latest/download/badvpn-udpgw" \
            -O "$BADVPN_BIN" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}[!] Could not obtain badvpn binary. Please install manually.${NC}"
            return 1
        fi
        chmod +x "$BADVPN_BIN"
    fi

    # Install systemd service
    cp "$INSTALL_DIR/module/badvpn.service" /etc/systemd/system/badvpn.service

    systemctl daemon-reload
    systemctl enable badvpn
    systemctl start badvpn

    if systemctl is-active --quiet badvpn; then
        echo -e "${GREEN}[OK] BadVPN UDPGW started on port $BADVPN_PORT${NC}"
    else
        echo -e "${RED}[!] BadVPN failed to start. Check: systemctl status badvpn${NC}"
    fi
}

install_udp_custom() {
    echo -e "${YELLOW}[*] Installing UDP Custom...${NC}"

    if [ -f "$INSTALL_DIR/module/udp-custom-linux-amd64" ]; then
        cp "$INSTALL_DIR/module/udp-custom-linux-amd64" "$UDPCUSTOM_BIN"
        chmod +x "$UDPCUSTOM_BIN"
    else
        echo -e "${RED}[!] UDP Custom binary not found in module directory.${NC}"
        return 1
    fi

    # Copy config
    mkdir -p /etc/udp-custom
    cp "$INSTALL_DIR/module/udp_config.json" /etc/udp-custom/config.json

    # Create systemd service
    cat > /etc/systemd/system/udp-custom.service << 'EOF'
[Unit]
Description=UDP Custom - Mzee Kobe Store
After=network.target

[Service]
User=root
ExecStart=/usr/bin/udp-custom server /etc/udp-custom/config.json
Restart=on-failure
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udp-custom
    systemctl start udp-custom

    if systemctl is-active --quiet udp-custom; then
        echo -e "${GREEN}[OK] UDP Custom started on port $UDPCUSTOM_PORT${NC}"
    else
        echo -e "${RED}[!] UDP Custom failed to start.${NC}"
    fi
}

status_udp() {
    echo -e "${CYAN}[*] UDP Services Status:${NC}"
    echo -e ""
    echo -e "  BadVPN UDPGW (port $BADVPN_PORT):"
    if systemctl is-active --quiet badvpn; then
        echo -e "    Status: ${GREEN}RUNNING${NC}"
    else
        echo -e "    Status: ${RED}STOPPED${NC}"
    fi

    echo -e ""
    echo -e "  UDP Custom (port $UDPCUSTOM_PORT):"
    if systemctl is-active --quiet udp-custom; then
        echo -e "    Status: ${GREEN}RUNNING${NC}"
    else
        echo -e "    Status: ${RED}STOPPED${NC}"
    fi
}

case "${1}" in
    badvpn)
        install_badvpn
        ;;
    udpcustom)
        install_udp_custom
        ;;
    all)
        install_badvpn
        install_udp_custom
        ;;
    status)
        status_udp
        ;;
    *)
        install_badvpn
        install_udp_custom
        ;;
esac
