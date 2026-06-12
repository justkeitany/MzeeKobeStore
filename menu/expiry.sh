#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Expiry Management
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

show_header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗██╗  ██╗██████╗ ██╗██████╗ ██╗   ██╗${BCYAN}              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔════╝╚██╗██╔╝██╔══██╗██║██╔══██╗╚██╗ ██╔╝${BCYAN}              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}█████╗   ╚███╔╝ ██████╔╝██║██████╔╝ ╚████╔╝ ${BCYAN}              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔══╝   ██╔██╗ ██╔═══╝ ██║██╔══██╗  ╚██╔╝  ${BCYAN}              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗██╔╝ ██╗██║     ██║██║  ██║   ██║   ${BCYAN} MANAGEMENT    ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  EXPIRY MANAGEMENT  ★   Mzee Kobe Store                  ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}.List Expired Users"
    echo -e "  ${YELLOW}[2]${NC}.Delete All Expired Users"
    echo -e "  ${YELLOW}[3]${NC}.Users Expiring in 3 Days"
    echo -e "  ${YELLOW}[4]${NC}.Delete Expired SSH Users"
    echo -e "  ${YELLOW}[5]${NC}.Delete Expired XRAY Users"
    echo -e "  ${YELLOW}[6]${NC}.Auto-Delete Schedule Info"
    echo -e "  ${YELLOW}[7]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1)
            echo ""
            python3 "$INSTALL_DIR/core/expiry.py" list-expired 2>/dev/null || \
                echo -e "  ${YELLOW}expiry.py not available.${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        2)
            echo -ne "  ${BRED}Delete ALL expired users? [y/N]: ${NC}"
            read -r conf
            if [[ "$conf" =~ ^[Yy]$ ]]; then
                python3 "$INSTALL_DIR/core/expiry.py" delete-all 2>/dev/null && \
                    echo -e "  ${BGREEN}[OK]${NC} All expired users deleted." || \
                    echo -e "  ${BRED}[!]${NC} Error running expiry.py"
            else echo -e "  ${YELLOW}Cancelled.${NC}"; fi
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        3)
            echo ""
            python3 "$INSTALL_DIR/core/expiry.py" expiring-soon --days 3 2>/dev/null || \
                echo -e "  ${YELLOW}expiry.py not available.${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        4)
            echo -ne "  ${YELLOW}Delete expired SSH users? [y/N]: ${NC}"
            read -r conf
            if [[ "$conf" =~ ^[Yy]$ ]]; then
                python3 "$INSTALL_DIR/core/expiry.py" delete-expired-ssh 2>/dev/null && \
                    echo -e "  ${BGREEN}[OK]${NC} Expired SSH users deleted."
            else echo -e "  ${YELLOW}Cancelled.${NC}"; fi
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        5)
            echo -ne "  ${YELLOW}Delete expired XRAY users? [y/N]: ${NC}"
            read -r conf
            if [[ "$conf" =~ ^[Yy]$ ]]; then
                python3 "$INSTALL_DIR/core/expiry.py" delete-expired-xray 2>/dev/null && \
                    echo -e "  ${BGREEN}[OK]${NC} Expired XRAY users deleted."
            else echo -e "  ${YELLOW}Cancelled.${NC}"; fi
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        6)
            echo ""
            echo -e "${CYAN}  Auto-delete cron schedule:${NC}"
            crontab -l 2>/dev/null | grep -i "expiry\|mzeekobe" || \
                echo -e "  ${YELLOW}No auto-delete cron configured.${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        7|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
