#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Main Interactive Menu
# ============================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ── Color codes ──────────────────────────────────────────────
RED='\e[41;1;37m'       # Red background white text (banner boxes)
CYAN='\e[0;36m'         # Cyan text
YELLOW='\e[0;33m'       # Yellow text
GREEN='\e[0;32m'        # Green text
MAGENTA='\e[0;35m'      # Magenta/purple for borders
BLUE='\e[0;34m'         # Blue text
WHITE='\e[1;37m'        # Bold white
NC='\e[0m'              # Reset
BRED='\e[1;31m'         # Bold red text
BGREEN='\e[1;32m'       # Bold green
BYELLOW='\e[1;33m'      # Bold yellow
BCYAN='\e[1;36m'        # Bold cyan

INSTALL_DIR="/usr/local/mzeekobe"
MENU_DIR="$INSTALL_DIR/menu"
VERSION=$(cat "$INSTALL_DIR/version" 2>/dev/null || echo "1.0.0")

# ── Service status check ─────────────────────────────────────
check_service() {
    systemctl is-active --quiet "$1" 2>/dev/null && \
        echo -e "${BGREEN}ON✅${NC}" || echo -e "${BRED}OFF❌${NC}"
}

# ── Gather system info (cached per run) ──────────────────────
gather_info() {
    UPTIME_VAL=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    # Force IPv4 with -4 flag
    IP=$(curl -4 -s ifconfig.me --max-time 5 2>/dev/null || hostname -I | awk '{print $1}')
    CITY=$(curl -4 -s "https://ipinfo.io/$IP/city" --max-time 5 2>/dev/null || echo "Unknown")
    ORG=$(curl -4 -s "https://ipinfo.io/$IP/org" --max-time 5 2>/dev/null || echo "Unknown")
    COUNTRY=$(curl -4 -s "https://ipinfo.io/$IP/country" --max-time 5 2>/dev/null || echo "Unknown")
    DOMAIN=$(cat /root/.mzeekobe_domain 2>/dev/null || echo "Not set")
    TZ=$(cat /etc/timezone 2>/dev/null || timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo "UTC")

    DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
    DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
    DISK_FREE=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')

    ST_NGINX=$(check_service nginx)
    ST_DROPBEAR=$(check_service dropbear)
    ST_XRAY=$(check_service xray)
    ST_WS=$(check_service mzeekobe-ws)
}

# ── Main display ─────────────────────────────────────────────
show_menu() {
    clear
    gather_info

    DATE_D=$(date '+%Y-%m-%d')
    DATE_W=$(date '+%A')
    DATE_T=$(date '+%H:%M:%S')

    # ── ASCII art title ──────────────────────────────────────
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███╗   ███╗███████╗███████╗███████╗                          ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}████╗ ████║╚══███╔╝██╔════╝██╔════╝                          ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔████╔██║  ███╔╝ █████╗  █████╗    ${YELLOW}★ KOBE STORE ★${BCYAN}       ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║╚██╔╝██║ ███╔╝  ██╔══╝  ██╔══╝                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║ ╚═╝ ██║███████╗███████╗███████╗                          ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"

    # ── System Info banner ───────────────────────────────────
    echo -e "${RED}▌        ★  SYSTEM INFO  ★                                    ▐${NC}"
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Uptime  ${NC}: ${YELLOW}${UPTIME_VAL}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}IP      ${NC}: ${YELLOW}${IP}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}City    ${NC}: ${YELLOW}${CITY}${NC}   ${CYAN}Country${NC}: ${YELLOW}${COUNTRY}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Org     ${NC}: ${YELLOW}${ORG}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Domain  ${NC}: ${GREEN}${DOMAIN}${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}Timezone${NC}: ${YELLOW}${TZ}${NC}"
    echo -e "${MAGENTA}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}💾 FullDisk${NC}: ${YELLOW}${DISK_TOTAL}${NC}  ${CYAN}Used${NC}: ${YELLOW}${DISK_USED}${NC}  ${CYAN}Remain${NC}: ${YELLOW}${DISK_FREE}${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"

    # ── Date/Time box ────────────────────────────────────────
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}${DATE_D}${NC}  📆 ${YELLOW}${DATE_W}${NC}  🕐 ${YELLOW}${DATE_T}${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

    # ── Package Status ───────────────────────────────────────
    echo -e "${RED}▌  PACKAGE STATUS                                              ▐${NC}"
    echo -e "  ${CYAN}Nginx${NC}: ${ST_NGINX}   ${CYAN}Dropbear${NC}: ${ST_DROPBEAR}   ${CYAN}Websocket${NC}: ${ST_WS}   ${CYAN}Xray Core${NC}: ${ST_XRAY}"
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${NC}"

    # ── 2-Column Menu Grid ───────────────────────────────────
    echo -e "  ${YELLOW}[1]${NC}.SSH Menu            ${YELLOW}[2]${NC}.VMess Menu"
    echo -e "  ${YELLOW}[3]${NC}.VLess Menu           ${YELLOW}[4]${NC}.Trojan Menu"
    echo -e "  ${YELLOW}[5]${NC}.SOCKS Menu           ${YELLOW}[6]${NC}.Add/Change Domain"
    echo -e "  ${YELLOW}[7]${NC}.Renew Certificate    ${YELLOW}[8]${NC}.Restart Services"
    echo -e "  ${YELLOW}[9]${NC}.Check System         ${YELLOW}[10]${NC}.Block Listed Sites"
    echo -e "  ${YELLOW}[11]${NC}.Telegram Bot        ${YELLOW}[12]${NC}.Reboot"
    echo -e "  ${YELLOW}[13]${NC}.DNS Settings        ${YELLOW}[14]${NC}.Port Info"
    echo -e "  ${YELLOW}[15]${NC}.View Logs           ${YELLOW}[16]${NC}.IP Tools"
    echo -e "  ${YELLOW}[17]${NC}.ZiVPN/Hysteria2     ${YELLOW}[18]${NC}.Expiry Mgmt"
    echo -e "  ${YELLOW}[19]${NC}.Update Panel        ${YELLOW}[0]${NC}.Exit"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"

    # ── Footer ───────────────────────────────────────────────
    echo -e "  ${CYAN}Version${NC}: ${YELLOW}${VERSION}${NC}  ${CYAN}AutoScript By${NC}: ${GREEN}Mzee Kobe Store${NC}  ${CYAN}License${NC}: ${YELLOW}MIT${NC}"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ── Restart Services helper ──────────────────────────────────
restart_services() {
    clear
    echo -e "${RED}▌  RESTART SERVICES                                            ▐${NC}"
    echo ""
    for svc in nginx xray dropbear mzeekobe-ws mzeekobe-dropbear-ws mzeekobe-ovpn-ws; do
        echo -ne "  ${CYAN}Restarting ${svc}...${NC} "
        if systemctl restart "$svc" 2>/dev/null; then
            echo -e "${BGREEN}OK${NC}"
        else
            echo -e "${BRED}SKIP${NC}"
        fi
    done
    echo ""
    echo -e "  ${BGREEN}All services restarted.${NC}"
    echo ""
    read -rp "  Press Enter to continue..."
}

# ── Main loop ────────────────────────────────────────────────
while true; do
    show_menu
    echo -ne "  ${YELLOW}[+] Enter Option (1-19)${NC}: "
    read -r opt

    case "$opt" in
        1)  bash "$MENU_DIR/ssh.sh" ;;
        2)  bash "$MENU_DIR/vmess.sh" ;;
        3)  bash "$MENU_DIR/vless.sh" ;;
        4)  bash "$MENU_DIR/trojan.sh" ;;
        5)  bash "$MENU_DIR/socks.sh" ;;
        6)  bash "$MENU_DIR/domain.sh" ;;
        7)
            clear
            echo -e "${YELLOW}  [*] Renewing SSL certificate...${NC}"
            bash "$INSTALL_DIR/core/ssl_renew.sh" renew
            echo ""
            read -rp "  Press Enter to continue..."
            ;;
        8)  restart_services ;;
        9)  bash "$MENU_DIR/status.sh" ;;
        10) bash "$MENU_DIR/netguard.sh" ;;
        11)
            clear
            echo -e "${CYAN}  Telegram Bot service:${NC}"
            systemctl status mzeekobe-bot --no-pager 2>/dev/null || \
                echo -e "${BRED}  Bot service not installed.${NC}"
            echo ""
            read -rp "  Press Enter to continue..."
            ;;
        12)
            echo -ne "  ${BRED}Reboot server? [y/N]:${NC} "
            read -r rb
            if [[ "$rb" =~ ^[Yy]$ ]]; then
                reboot
            fi
            ;;
        13) bash "$MENU_DIR/dns.sh" ;;
        14) bash "$MENU_DIR/port.sh" ;;
        15) bash "$MENU_DIR/log.sh" ;;
        16) bash "$MENU_DIR/iptools.sh" ;;
        17) bash "$MENU_DIR/zivpn.sh" ;;
        18) bash "$MENU_DIR/expiry.sh" ;;
        19) bash "$MENU_DIR/update.sh" ;;
        0)
            clear
            echo -e "${BGREEN}  Goodbye from Mzee Kobe Store!${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${BRED}  [!] Invalid option. Try again.${NC}"
            sleep 1
            ;;
    esac
done
