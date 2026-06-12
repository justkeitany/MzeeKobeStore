#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - DNS Settings
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
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██████╗ ███╗   ██╗███████╗${BCYAN}  SETTINGS                         ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔══██╗████╗  ██║██╔════╝${BCYAN}                                   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║  ██║██╔██╗ ██║███████╗${BCYAN}  Mzee Kobe Store                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██║  ██║██║╚██╗██║╚════██║${BCYAN}                                   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██████╔╝██║ ╚████║███████║${BCYAN}                                   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  DNS SETTINGS  ★   Mzee Kobe Store                       ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

set_dns() {
    local dns1="$1" dns2="$2"
    # Handle systemd-resolved
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        mkdir -p /etc/systemd/resolved.conf.d
        cat > /etc/systemd/resolved.conf.d/mzeekobe.conf << EOF
[Resolve]
DNS=$dns1 $dns2
FallbackDNS=1.1.1.1 8.8.8.8
EOF
        systemctl restart systemd-resolved 2>/dev/null
    fi
    # Also write resolv.conf directly
    {
        echo "# Mzee Kobe Store DNS"
        echo "nameserver $dns1"
        echo "nameserver $dns2"
    } > /etc/resolv.conf
    echo -e "  ${BGREEN}[OK]${NC} DNS set to $dns1 / $dns2"
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}.Use Cloudflare DNS (1.1.1.1 / 1.0.0.1)"
    echo -e "  ${YELLOW}[2]${NC}.Use Google DNS (8.8.8.8 / 8.8.4.4)"
    echo -e "  ${YELLOW}[3]${NC}.Custom DNS Servers"
    echo -e "  ${YELLOW}[4]${NC}.Show Current DNS"
    echo -e "  ${YELLOW}[5]${NC}.Reset DNS to Defaults"
    echo -e "  ${YELLOW}[6]${NC}.Test DNS Resolution"
    echo -e "  ${YELLOW}[7]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1)
            set_dns "1.1.1.1" "1.0.0.1"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        2)
            set_dns "8.8.8.8" "8.8.4.4"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        3)
            echo -ne "  ${YELLOW}Primary DNS  : ${NC}"; read -r dns1
            echo -ne "  ${YELLOW}Secondary DNS: ${NC}"; read -r dns2
            if [ -n "$dns1" ]; then
                set_dns "$dns1" "${dns2:-8.8.8.8}"
            else echo -e "${BRED}  [!] Primary DNS required.${NC}"; fi
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        4)
            echo ""
            echo -e "${CYAN}  /etc/resolv.conf:${NC}"
            cat /etc/resolv.conf 2>/dev/null | grep -v "^#" | grep -v "^$" | sed 's/^/  /'
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        5)
            set_dns "1.1.1.1" "8.8.8.8"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        6)
            echo ""
            echo -e "${CYAN}  Testing DNS resolution:${NC}"
            for host in google.com cloudflare.com github.com; do
                if nslookup "$host" >/dev/null 2>&1 || host "$host" >/dev/null 2>&1; then
                    echo -e "  ${BGREEN}[OK  ]${NC} $host"
                else
                    echo -e "  ${BRED}[FAIL]${NC} $host"
                fi
            done
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        7|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
