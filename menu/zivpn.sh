#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - ZiVPN / Hysteria2
# ============================================================
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\e[41;1;37m'
CYAN='\e[0;36m'
YELLOW='\e[0;33m'
GREEN='\e[0;32m'
MAGENTA='\e[0;35m'
NC='\e[0m'
BRED='\e[1;31m'
BGREEN='\e[1;32m'
BCYAN='\e[1;36m'

INSTALL_DIR="/usr/local/mzeekobe"
HY2_CONFIG="/etc/hysteria/config.yaml"
DOMAIN_FILE="/root/.mzeekobe_domain"

get_domain() {
    cat "$DOMAIN_FILE" 2>/dev/null || hostname -I | awk '{print $1}'
}

show_header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗██╗██╗   ██╗██████╗ ███╗   ██╗${BCYAN}                      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}╚══███╔╝██║██║   ██║██╔══██╗████╗  ██║${BCYAN}                      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}  ███╔╝ ██║██║   ██║██████╔╝██╔██╗ ██║${BCYAN}  HYSTERIA2           ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN} ███╔╝  ██║╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║${BCYAN}                      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗██║ ╚████╔╝ ██║     ██║ ╚████║${BCYAN}  ★ Mzee Kobe Store   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  ZIVPN / HYSTERIA2  ★   Mzee Kobe Store                  ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    if systemctl is-active --quiet hysteria-server 2>/dev/null; then
        echo -e "  ${CYAN}Hysteria2${NC}: ${BGREEN}RUNNING ✅${NC}"
    else
        echo -e "  ${CYAN}Hysteria2${NC}: ${BRED}STOPPED ❌${NC}"
    fi
    echo ""
}

install_hysteria2() {
    echo -e "${YELLOW}  [*] Installing Hysteria2...${NC}"
    bash -c "$(curl -fsSL https://get.hy2.sh/)" -- 2>/dev/null
    if ! command -v hysteria >/dev/null 2>&1; then
        echo -e "${BRED}  [!] Hysteria2 install failed.${NC}"
        echo ""; read -rp "  Press Enter to continue..."; return
    fi
    echo -e "${BGREEN}  [OK]${NC} Hysteria2 installed: $(hysteria version 2>/dev/null | head -1)"
    local DOMAIN PORT PASSWORD
    DOMAIN=$(get_domain)
    PORT="36712"
    PASSWORD=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | head -c 16 || \
               od -An -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' | head -c 16)
    mkdir -p /etc/hysteria
    cat > "$HY2_CONFIG" << EOF
# Mzee Kobe Store - Hysteria2
listen: :$PORT

tls:
  cert: /etc/xray/xray.crt
  key: /etc/xray/xray.key

auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://$DOMAIN
    rewriteHost: true

bandwidth:
  up: 1 gbps
  down: 1 gbps
EOF
    cat > /etc/systemd/system/hysteria-server.service << 'EOF'
[Unit]
Description=Hysteria2 Server - Mzee Kobe Store
After=network.target nss-lookup.target
[Service]
User=root
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable hysteria-server 2>/dev/null
    systemctl start hysteria-server 2>/dev/null
    sleep 2
    echo "$PASSWORD" > /root/.mzeekobe_hy2_password
    if systemctl is-active --quiet hysteria-server; then
        echo -e "  ${BGREEN}[OK]${NC} Hysteria2 running on port $PORT"
        echo -e "  ${CYAN}Password${NC}: ${YELLOW}$PASSWORD${NC}"
    else
        echo -e "${BRED}  [!] Hysteria2 failed to start. Check: journalctl -u hysteria-server${NC}"
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

show_hy2_link() {
    local DOMAIN PASSWORD PORT
    DOMAIN=$(get_domain)
    PASSWORD=$(cat /root/.mzeekobe_hy2_password 2>/dev/null || echo "not-configured")
    PORT="36712"
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Server  ${NC}: ${YELLOW}${DOMAIN}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Port    ${NC}: ${YELLOW}${PORT}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Password${NC}: ${YELLOW}${PASSWORD}${NC}"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}URL${NC}: ${GREEN}hy2://${PASSWORD}@${DOMAIN}:${PORT}/?insecure=1#MzeeKobe-HY2${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""; read -rp "  Press Enter to continue..."
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}.Install Hysteria2"
    echo -e "  ${YELLOW}[2]${NC}.Start Hysteria2"
    echo -e "  ${YELLOW}[3]${NC}.Stop Hysteria2"
    echo -e "  ${YELLOW}[4]${NC}.Restart Hysteria2"
    echo -e "  ${YELLOW}[5]${NC}.Show Connection Info"
    echo -e "  ${YELLOW}[6]${NC}.View Config"
    echo -e "  ${YELLOW}[7]${NC}.View Logs"
    echo -e "  ${YELLOW}[8]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1) install_hysteria2 ;;
        2)
            systemctl start hysteria-server 2>/dev/null
            echo -e "  ${BGREEN}[OK]${NC} Hysteria2 started."
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        3)
            systemctl stop hysteria-server 2>/dev/null
            echo -e "  ${YELLOW}  Hysteria2 stopped.${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        4)
            systemctl restart hysteria-server 2>/dev/null
            echo -e "  ${BGREEN}[OK]${NC} Hysteria2 restarted."
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        5) show_hy2_link ;;
        6)
            echo ""
            [ -f "$HY2_CONFIG" ] && cat "$HY2_CONFIG" | sed 's/^/  /' || \
                echo -e "  ${BRED}Config not found.${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        7)
            echo ""
            journalctl -u hysteria-server -n 50 --no-pager 2>/dev/null | sed 's/^/  /' || \
                echo -e "  ${YELLOW}No logs available.${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        8|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
