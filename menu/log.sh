#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Log Viewer
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

show_header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╗      ██████╗  ██████╗ ███████╗${BCYAN}  VIEWER              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║     ██╔═══██╗██╔════╝ ██╔════╝${BCYAN}                      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║     ██║   ██║██║  ███╗███████╗${BCYAN}  Mzee Kobe Store      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║     ██║   ██║██║   ██║╚════██║${BCYAN}                      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗╚██████╔╝╚██████╔╝███████║${BCYAN}                      ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  LOG VIEWER  ★   Mzee Kobe Store                         ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

view_log() {
    local LOG_FILE="$1"
    local LOG_NAME="$2"
    local LINES="${3:-50}"
    clear
    echo -e "${RED}▌  LOG: ${LOG_NAME}                                             ▐${NC}"
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    if [ -f "$LOG_FILE" ]; then
        tail -n "$LINES" "$LOG_FILE" | while IFS= read -r line; do
            echo -e "${MAGENTA}║${NC}  ${CYAN}${line}${NC}"
        done
    else
        echo -e "${MAGENTA}║${NC}  ${YELLOW}Log file not found: ${LOG_FILE}${NC}"
    fi
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -rp "  Press Enter to go back..."
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}.Xray Access Log"
    echo -e "  ${YELLOW}[2]${NC}.Xray Error Log"
    echo -e "  ${YELLOW}[3]${NC}.Nginx Access Log"
    echo -e "  ${YELLOW}[4]${NC}.Nginx Error Log"
    echo -e "  ${YELLOW}[5]${NC}.Bot Log"
    echo -e "  ${YELLOW}[6]${NC}.Expiry Log"
    echo -e "  ${YELLOW}[7]${NC}.Validator Log"
    echo -e "  ${YELLOW}[8]${NC}.System Auth Log"
    echo -e "  ${YELLOW}[9]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1) view_log "/var/log/xray/access.log" "Xray Access" 100 ;;
        2) view_log "/var/log/xray/error.log" "Xray Error" 50 ;;
        3) view_log "/var/log/nginx/access.log" "Nginx Access" 100 ;;
        4) view_log "/var/log/nginx/error.log" "Nginx Error" 50 ;;
        5) view_log "/var/log/mzeekobe_bot.log" "Telegram Bot" 50 ;;
        6) view_log "/var/log/mzeekobe_expiry.log" "Expiry Manager" 50 ;;
        7) view_log "/var/log/mzeekobe_validator.log" "Validator" 50 ;;
        8) view_log "/var/log/auth.log" "Auth Log" 50 ;;
        9|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
