#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - System Status
# ============================================================
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\e[41;1;37m'
CYAN='\e[0;36m'
YELLOW='\e[0;33m'
GREEN='\e[0;32m'
MAGENTA='\e[0;35m'
WHITE='\e[1;37m'
NC='\e[0m'
BRED='\e[1;31m'
BGREEN='\e[1;32m'
BCYAN='\e[1;36m'

INSTALL_DIR="/usr/local/mzeekobe"

svc_status() {
    local label="$1"
    local svc="$2"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        printf "  ${CYAN}%-22s${NC}: ${BGREEN}ON✅${NC}\n" "$label"
    else
        printf "  ${CYAN}%-22s${NC}: ${BRED}OFF❌${NC}\n" "$label"
    fi
}

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗   ██║   ███████║   ██║   ██║   ██║███████╗${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${RED}▌  ★  CHECK SYSTEM  ★   Mzee Kobe Store                       ▐${NC}"
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Server Info ──────────────────────────────────────────────
SERVER_IP=$(curl -s ifconfig.me --max-time 4 2>/dev/null || hostname -I | awk '{print $1}')
DOMAIN=$(cat /root/.mzeekobe_domain 2>/dev/null || echo "Not set")
UPTIME_VAL=$(uptime -p 2>/dev/null | sed 's/up //' || uptime)
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
MEM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/{print $2}')
MEM_USED=$(free -m 2>/dev/null | awk '/Mem:/{print $3}')
DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')

echo -e "${RED}▌  SERVER INFORMATION                                          ▐${NC}"
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}IP Address ${NC}: ${YELLOW}${SERVER_IP}${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}Domain     ${NC}: ${GREEN}${DOMAIN}${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}Uptime     ${NC}: ${YELLOW}${UPTIME_VAL}${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}CPU Load   ${NC}: ${YELLOW}${CPU_LOAD:-N/A}${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}Memory     ${NC}: ${YELLOW}${MEM_USED}MB / ${MEM_TOTAL}MB${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}Disk       ${NC}: ${YELLOW}${DISK_USED}${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Service Status ───────────────────────────────────────────
echo -e "${RED}▌  SERVICES                                                    ▐${NC}"
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
svc_status "Nginx" "nginx"
svc_status "Xray Core" "xray"
svc_status "SSH" "ssh"
svc_status "Dropbear" "dropbear"
svc_status "Squid Proxy" "squid"
svc_status "WS Proxy" "mzeekobe-ws"
svc_status "Dropbear WS" "mzeekobe-dropbear-ws"
svc_status "OpenVPN WS" "mzeekobe-ovpn-ws"
svc_status "BadVPN UDPGW" "badvpn"
svc_status "UDP Custom" "udp-custom"
svc_status "Hysteria2" "hysteria-server"
svc_status "Telegram Bot" "mzeekobe-bot"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Online Users ─────────────────────────────────────────────
ONLINE=$(who 2>/dev/null | wc -l)
echo -e "${RED}▌  ONLINE USERS                                                ▐${NC}"
echo -e "  ${CYAN}Active SSH sessions${NC}: ${YELLOW}${ONLINE}${NC}"
if [ "$ONLINE" -gt 0 ]; then
    echo -e "${MAGENTA}╔══════════════╦══════════════╦════════════╦══════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${CYAN}Username      ${MAGENTA}║${NC} ${CYAN}Terminal      ${MAGENTA}║${NC} ${CYAN}Date/Time   ${MAGENTA}║${NC} ${CYAN}From      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╠══════════════╬══════════════╬════════════╬══════════╣${NC}"
    who 2>/dev/null | while read -r u t d tt fr; do
        printf "${MAGENTA}║${NC} ${YELLOW}%-14s${MAGENTA}║${NC} ${YELLOW}%-14s${MAGENTA}║${NC} ${YELLOW}%-12s${MAGENTA}║${NC} ${YELLOW}%-10s${MAGENTA}║${NC}\n" \
            "$u" "$t" "$d $tt" "${fr//[()]/}"
    done
    echo -e "${MAGENTA}╚══════════════╩══════════════╩════════════╩══════════╝${NC}"
fi
echo ""

# ── Xray stats if available ──────────────────────────────────
if [ -f "$INSTALL_DIR/core/status.py" ]; then
    echo -e "${RED}▌  XRAY USER STATS                                             ▐${NC}"
    python3 "$INSTALL_DIR/core/status.py" 2>/dev/null || true
    echo ""
fi

read -rp "  Press Enter to go back..."
