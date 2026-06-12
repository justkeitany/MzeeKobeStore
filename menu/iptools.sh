#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - IP Tools
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
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╗██████╗     ████████╗ ██████╗  ██████╗ ██╗     ███████╗${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║██╔══██╗    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║██████╔╝       ██║   ██║   ██║██║   ██║██║     ███████╗${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║██╔═══╝        ██║   ██║   ██║██║   ██║██║     ╚════██║${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║██║             ██║   ╚██████╔╝╚██████╔╝███████╗███████║${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  IP TOOLS  ★   Mzee Kobe Store                           ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}.Show Server IP"
    echo -e "  ${YELLOW}[2]${NC}.Show Online IPs (active SSH)"
    echo -e "  ${YELLOW}[3]${NC}.Ping Test"
    echo -e "  ${YELLOW}[4]${NC}.Traceroute"
    echo -e "  ${YELLOW}[5]${NC}.IP Info Lookup"
    echo -e "  ${YELLOW}[6]${NC}.Network Interfaces"
    echo -e "  ${YELLOW}[7]${NC}.Active Connections"
    echo -e "  ${YELLOW}[8]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1)
            echo ""
            PUB_IP=$(curl -s ifconfig.me --max-time 5)
            LOC_IP=$(hostname -I | awk '{print $1}')
            echo -e "${MAGENTA}╔══════════════════════════════╗${NC}"
            echo -e "${MAGENTA}║${NC}  ${CYAN}Public IP${NC} : ${YELLOW}${PUB_IP}${NC}"
            echo -e "${MAGENTA}║${NC}  ${CYAN}Local IP ${NC} : ${YELLOW}${LOC_IP}${NC}"
            echo -e "${MAGENTA}╚══════════════════════════════╝${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        2)
            echo ""
            echo -e "${RED}▌  ACTIVE SSH SESSIONS                                         ▐${NC}"
            echo -e "${MAGENTA}╔═══════════════╦═══════════════╦═══════════════╦═══════════╗${NC}"
            echo -e "${MAGENTA}║${NC} ${CYAN}Username       ${MAGENTA}║${NC} ${CYAN}Terminal       ${MAGENTA}║${NC} ${CYAN}Date/Time      ${MAGENTA}║${NC} ${CYAN}From       ${MAGENTA}║${NC}"
            echo -e "${MAGENTA}╠═══════════════╬═══════════════╬═══════════════╬═══════════╣${NC}"
            who 2>/dev/null | while read -r u t d tt fr; do
                printf "${MAGENTA}║${NC} ${YELLOW}%-15s${MAGENTA}║${NC} ${YELLOW}%-15s${MAGENTA}║${NC} ${YELLOW}%-15s${MAGENTA}║${NC} ${YELLOW}%-11s${MAGENTA}║${NC}\n" \
                    "$u" "$t" "$d $tt" "${fr//[()]/}"
            done
            echo -e "${MAGENTA}╚═══════════════╩═══════════════╩═══════════════╩═══════════╝${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        3)
            echo -ne "  ${YELLOW}Host to ping: ${NC}"; read -r host
            [ -z "$host" ] && { echo -e "${BRED}  [!] Host required.${NC}"; sleep 1; continue; }
            ping -c 5 "$host"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        4)
            echo -ne "  ${YELLOW}Host to traceroute: ${NC}"; read -r host
            [ -z "$host" ] && { echo -e "${BRED}  [!] Host required.${NC}"; sleep 1; continue; }
            if command -v traceroute >/dev/null 2>&1; then traceroute -n "$host"
            elif command -v tracepath >/dev/null 2>&1; then tracepath "$host"
            else mtr --report --no-dns "$host" 2>/dev/null || echo -e "${YELLOW}  traceroute not available.${NC}"; fi
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        5)
            echo -ne "  ${YELLOW}IP to lookup (blank = this server): ${NC}"; read -r ip
            ip="${ip:-$(curl -s ifconfig.me --max-time 5)}"
            echo -e "${CYAN}  Lookup: $ip${NC}"
            echo -e "${MAGENTA}╔══════════════════════════════════════╗${NC}"
            curl -s "https://ipinfo.io/$ip" --max-time 5 2>/dev/null | \
                python3 -c "import sys,json; d=json.load(sys.stdin); [print('  '+k+': '+str(v)) for k,v in d.items()]" 2>/dev/null || \
                curl -s "https://ipinfo.io/$ip" --max-time 5 | sed 's/^/  /'
            echo -e "${MAGENTA}╚══════════════════════════════════════╝${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        6)
            echo ""
            echo -e "${CYAN}  Network interfaces:${NC}"
            ip addr show 2>/dev/null | grep -E "^[0-9]:|inet " | sed 's/^/  /' | head -30
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        7)
            echo ""
            echo -e "${CYAN}  Active connections (top 25):${NC}"
            echo -e "${MAGENTA}╔═════════════════════════════════════════════════════════════╗${NC}"
            ss -tnp 2>/dev/null | grep ESTAB | head -25 | while IFS= read -r line; do
                echo -e "${MAGENTA}║${NC}  ${YELLOW}${line}${NC}"
            done
            echo -e "${MAGENTA}╚═════════════════════════════════════════════════════════════╝${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        8|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
