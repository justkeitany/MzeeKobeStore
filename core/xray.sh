#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Xray-core Installation & Setup
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/usr/local/mzeekobe"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CONFIG="/etc/xray/config.json"
XRAY_CERT="/etc/xray/xray.crt"
XRAY_KEY="/etc/xray/xray.key"
DOMAIN_FILE="/root/.mzeekobe_domain"

get_domain() {
    [ -f "$DOMAIN_FILE" ] && cat "$DOMAIN_FILE" || hostname -I | awk '{print $1}'
}

install_xray() {
    echo -e "${YELLOW}[*] Installing Xray-core...${NC}"

    # Use official install script
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>/dev/null

    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}[!] Official installer failed. Trying manual install...${NC}"
        install_xray_manual
        return
    fi

    echo -e "${GREEN}[OK] Xray-core installed: $($XRAY_BIN version 2>/dev/null | head -1)${NC}"
}

install_xray_manual() {
    local ARCH
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="64" ;;
        aarch64) ARCH="arm64-v8a" ;;
        armv7l)  ARCH="arm32-v7a" ;;
        *)       ARCH="64" ;;
    esac

    local VERSION
    VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    VERSION="${VERSION:-v25.1.1}"

    local URL="https://github.com/XTLS/Xray-core/releases/download/$VERSION/Xray-linux-$ARCH.zip"

    echo -e "${YELLOW}[*] Downloading Xray $VERSION...${NC}"
    wget -q "$URL" -O /tmp/xray.zip
    unzip -o /tmp/xray.zip xray -d /tmp/xray_extract/ 2>/dev/null
    mv /tmp/xray_extract/xray "$XRAY_BIN"
    chmod +x "$XRAY_BIN"
    rm -rf /tmp/xray.zip /tmp/xray_extract

    echo -e "${GREEN}[OK] Xray installed manually.${NC}"
}

setup_xray_config() {
    local DOMAIN
    DOMAIN=$(get_domain)
    echo -e "${YELLOW}[*] Setting up Xray config...${NC}"

    mkdir -p /etc/xray /var/log/xray

    # Copy config template
    if [ -f "$INSTALL_DIR/module/config.json" ]; then
        cp "$INSTALL_DIR/module/config.json" "$XRAY_CONFIG"
        echo -e "${GREEN}[OK] Config copied from module template.${NC}"
    else
        echo -e "${RED}[!] Config template not found.${NC}"
        return 1
    fi

    # Set permissions
    chown -R www-data:www-data /var/log/xray 2>/dev/null
    chmod 644 "$XRAY_CONFIG"

    echo -e "${GREEN}[OK] Xray config installed at $XRAY_CONFIG${NC}"
}

setup_ssl_for_xray() {
    local DOMAIN
    DOMAIN=$(get_domain)
    echo -e "${YELLOW}[*] Setting up SSL certificate for Xray...${NC}"

    mkdir -p /etc/xray

    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$XRAY_CERT"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$XRAY_KEY"
        chmod 644 "$XRAY_CERT"
        chmod 600 "$XRAY_KEY"
        echo -e "${GREEN}[OK] SSL cert copied from Let's Encrypt.${NC}"
    else
        echo -e "${YELLOW}[!] Let's Encrypt cert not found. Generating self-signed...${NC}"
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout "$XRAY_KEY" \
            -out "$XRAY_CERT" \
            -subj "/CN=$DOMAIN" 2>/dev/null
        echo -e "${GREEN}[OK] Self-signed certificate generated.${NC}"
    fi
}

install_xray_service() {
    echo -e "${YELLOW}[*] Installing Xray systemd service...${NC}"

    if [ -f "$INSTALL_DIR/module/xray.service" ]; then
        cp "$INSTALL_DIR/module/xray.service" /etc/systemd/system/xray.service
    else
        cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service - Mzee Kobe Store
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    fi

    # Ensure www-data can access log dir
    mkdir -p /var/log/xray
    chown -R www-data:www-data /var/log/xray 2>/dev/null

    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray

    sleep 2
    if systemctl is-active --quiet xray; then
        echo -e "${GREEN}[OK] Xray service running.${NC}"
    else
        echo -e "${RED}[!] Xray failed to start. Check: journalctl -u xray -n 20${NC}"
    fi
}

status_xray() {
    echo -e "${CYAN}[*] Xray Status:${NC}"
    if systemctl is-active --quiet xray 2>/dev/null; then
        echo -e "  Service  : ${GREEN}RUNNING${NC}"
        echo -e "  Version  : $($XRAY_BIN version 2>/dev/null | head -1)"
    else
        echo -e "  Service  : ${RED}STOPPED${NC}"
    fi
    echo -e "  Config   : $XRAY_CONFIG"
    echo -e "  Cert     : $XRAY_CERT"
}

update_xray() {
    echo -e "${YELLOW}[*] Updating Xray-core...${NC}"
    systemctl stop xray 2>/dev/null
    install_xray
    systemctl start xray
    echo -e "${GREEN}[OK] Xray updated.${NC}"
}

case "${1}" in
    install)
        install_xray
        setup_ssl_for_xray
        setup_xray_config
        install_xray_service
        ;;
    config)
        setup_xray_config
        systemctl restart xray 2>/dev/null
        ;;
    ssl)
        setup_ssl_for_xray
        systemctl restart xray 2>/dev/null
        ;;
    status)
        status_xray
        ;;
    update)
        update_xray
        ;;
    restart)
        systemctl restart xray
        echo -e "${GREEN}[OK] Xray restarted.${NC}"
        ;;
    *)
        install_xray
        setup_ssl_for_xray
        setup_xray_config
        install_xray_service
        ;;
esac
