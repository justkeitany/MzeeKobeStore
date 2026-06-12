#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - VLESS Management
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
PROTO="vless"

show_header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╗   ██╗██╗     ███████╗███████╗███████╗${BCYAN}                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║   ██║██║     ██╔════╝██╔════╝██╔════╝${BCYAN}                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║   ██║██║     █████╗  ███████╗███████╗${BCYAN}                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}╚██╗ ██╔╝██║     ██╔══╝  ╚════██║╚════██║${BCYAN}                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN} ╚████╔╝ ███████╗███████╗███████║███████║${BCYAN}  MENU            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  VLESS MENU  ★   Mzee Kobe Store                         ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

check_xray_users() {
    echo ""
    echo -e "${RED}▌  LOGGED IN VLESS USERS                                       ▐${NC}"
    echo -e "${MAGENTA}╔═══════════════════╦════════════════════╦═══════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${CYAN}Username           ${MAGENTA}║${NC} ${CYAN}IP Address          ${MAGENTA}║${NC} ${CYAN}Time               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╠═══════════════════╬════════════════════╬═══════════════════╣${NC}"
    local LOG="/var/log/xray/access.log"
    if [ -f "$LOG" ]; then
        grep -i "$PROTO" "$LOG" 2>/dev/null | tail -30 | while IFS= read -r line; do
            uname=$(echo "$line" | grep -oP 'email: \K[^ ]+' || echo "unknown")
            ip=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1 || echo "?")
            ts=$(echo "$line" | awk '{print $1, $2}' | head -c 19)
            printf "${MAGENTA}║${NC} ${YELLOW}%-19s${MAGENTA}║${NC} ${YELLOW}%-20s${MAGENTA}║${NC} ${YELLOW}%-19s${MAGENTA}║${NC}\n" "$uname" "$ip" "$ts"
        done
    else
        echo -e "  ${YELLOW}  Log file not found.${NC}"
    fi
    echo -e "${MAGENTA}╚═══════════════════╩════════════════════╩═══════════════════╝${NC}"
    echo ""; read -rp "  Press Enter to continue..."
}

check_configs() {
    echo ""
    echo -e "${RED}▌  VLESS CONFIG FILES                                          ▐${NC}"
    python3 "$INSTALL_DIR/core/xray.py" list --proto "$PROTO" 2>/dev/null || \
        echo -e "  ${BRED}No users found.${NC}"
    echo ""
    echo -ne "  ${YELLOW}Show config for username (blank=skip): ${NC}"; read -r cuser
    [ -n "$cuser" ] && python3 "$INSTALL_DIR/core/xray.py" show --proto "$PROTO" --user "$cuser" 2>/dev/null
    echo ""; read -rp "  Press Enter to continue..."
}

check_bandwidth() {
    echo ""
    echo -e "${RED}▌  BANDWIDTH USED - VLESS                                      ▐${NC}"
    local LOG="/var/log/xray/access.log"
    if [ -f "$LOG" ]; then
        grep -i "$PROTO" "$LOG" 2>/dev/null | grep -oP 'email: \K[^ ]+' | \
            sort | uniq -c | sort -rn | head -20 | \
            while read -r count uname; do
                printf "  ${YELLOW}%-30s${NC} ${GREEN}%s connections${NC}\n" "$uname" "$count"
            done
    else echo -e "  ${YELLOW}Log not available.${NC}"; fi
    echo ""; read -rp "  Press Enter to continue..."
}

while true; do
    show_header
    echo ""
    echo -e "  ${YELLOW}[1]${NC}.Add VLess Account      ${YELLOW}[2]${NC}.Check Logged In Users"
    echo -e "  ${YELLOW}[3]${NC}.Delete VLess Account   ${YELLOW}[4]${NC}.Block Sites"
    echo -e "  ${YELLOW}[5]${NC}.Renew VLess Account    ${YELLOW}[6]${NC}.Check Configs Files"
    echo -e "  ${YELLOW}[7]${NC}.Check Bandwidth Used   ${YELLOW}[8]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1)
            echo ""
            echo -e "${RED}▌  ADD VLESS ACCOUNT                                           ▐${NC}"
            echo -ne "  ${YELLOW}Username  : ${NC}"; read -r user
            echo -ne "  ${YELLOW}Days valid: ${NC}"; read -r days
            if [ -z "$user" ] || [ -z "$days" ]; then
                echo -e "${BRED}  [!] Username and days required.${NC}"
            else
                python3 "$INSTALL_DIR/core/xray.py" add --proto "$PROTO" --user "$user" --days "$days"
                echo -e "  ${BGREEN}[OK]${NC} VLess account created: $user ($days days)"
            fi
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        2) check_xray_users ;;
        3)
            echo -ne "  ${YELLOW}Username to delete: ${NC}"; read -r user
            echo -ne "  ${YELLOW}Confirm? [y/N]: ${NC}"; read -r conf
            [[ "$conf" =~ ^[Yy]$ ]] && \
                python3 "$INSTALL_DIR/core/xray.py" delete --proto "$PROTO" --user "$user" && \
                echo -e "  ${BGREEN}[OK]${NC} Deleted $user."
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        4) bash "$INSTALL_DIR/menu/netguard.sh" ;;
        5)
            echo -ne "  ${YELLOW}Username: ${NC}"; read -r user
            echo -ne "  ${YELLOW}Days to add: ${NC}"; read -r days
            python3 "$INSTALL_DIR/core/xray.py" renew --proto "$PROTO" --user "$user" --days "$days"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        6) check_configs ;;
        7) check_bandwidth ;;
        8|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
