#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Port Information
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
PORT_INFO="$INSTALL_DIR/port_info"

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██████╗  ██████╗ ██████╗ ████████╗███████╗${BCYAN}                   ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝${BCYAN}                   ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██████╔╝██║   ██║██████╔╝   ██║   ███████╗${BCYAN}  INFO             ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔═══╝ ██║   ██║██╔══██╗   ██║   ╚════██║${BCYAN}                   ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██║     ╚██████╔╝██║  ██║   ██║   ███████║${BCYAN}                   ${MAGENTA}║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${RED}▌  ★  PORT INFORMATION  ★   Mzee Kobe Store                   ▐${NC}"
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show port_info file content or defaults
if [ -f "$PORT_INFO" ]; then
    echo -e "${RED}▌  CONFIGURED PORTS                                            ▐${NC}"
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    while IFS= read -r line; do
        if [ -z "$line" ]; then echo -e "${MAGENTA}║${NC}"; else
            echo -e "${MAGENTA}║${NC}  ${YELLOW}${line}${NC}"
        fi
    done < "$PORT_INFO"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}▌  DEFAULT PORT REFERENCE                                      ▐${NC}"
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "SSH WS (NTLS)"         "80"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "SSH WSS (TLS)"         "443"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "SSH Dropbear"          "222"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VMess WS TLS"          "443"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VMess WS NTLS"         "80"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VMess Custom TLS"      "2083"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VMess Custom NTLS"     "2082"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VLess WS TLS"          "443"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VLess WS NTLS"         "80"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VLess Custom TLS"      "2087"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "VLess Custom NTLS"     "2086"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "Trojan WS TLS"         "443"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "Trojan WS NTLS"        "80"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "SOCKS WS TLS"          "443"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "OpenVPN TCP"           "1194"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "OpenVPN UDP"           "2200"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "Squid Proxy"           "3128 / 8080"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "OHP TCP"               "8000"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "UDP Custom"            "36712"
    printf "${MAGENTA}║${NC}  ${CYAN}%-30s${NC} : ${YELLOW}%-10s${MAGENTA}║${NC}\n" "BadVPN UDPGW"          "7300"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${RED}▌  CURRENTLY LISTENING PORTS                                   ▐${NC}"
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
ss -tlnp 2>/dev/null | grep -v "^Netid" | awk '{print $4}' | sort -u | while read -r addr; do
    port=$(echo "$addr" | rev | cut -d: -f1 | rev)
    echo -e "${MAGENTA}║${NC}  ${GREEN}●${NC} ${YELLOW}${addr}${NC}"
done | head -30
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -rp "  Press Enter to go back..."
