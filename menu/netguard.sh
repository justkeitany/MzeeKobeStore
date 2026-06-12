#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Network Guard / Site Blocker
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
BYELLOW='\e[1;33m'
BCYAN='\e[1;36m'

INSTALL_DIR="/usr/local/mzeekobe"
BLOCKED_FILE="$INSTALL_DIR/blocked_domains.txt"
HOSTS_MARKER="# MZEE KOBE BLOCKER START"
HOSTS_MARKER_END="# MZEE KOBE BLOCKER END"

# Ensure blocked_domains.txt exists
[ -f "$BLOCKED_FILE" ] || touch "$BLOCKED_FILE"

show_header() {
    clear
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  ${BYELLOW}███████╗██╗████████╗███████╗${BYELLOW}                                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BYELLOW}██╔════╝██║╚══██╔══╝██╔════╝${BYELLOW}  BLOCKER                       ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BYELLOW}███████╗██║   ██║   █████╗  ${BYELLOW}                                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BYELLOW}╚════██║██║   ██║   ██╔══╝  ${BYELLOW}                                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BYELLOW}███████║██║   ██║   ███████╗${BYELLOW}  ★  Mzee Kobe Store            ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  SITE BLOCKER  ★   Mzee Kobe Store                       ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    # Show block count
    local count
    count=$(grep -c '^' "$BLOCKED_FILE" 2>/dev/null || echo "0")
    echo -e "  ${CYAN}Blocked Domains${NC}: ${YELLOW}${count}${NC}"
    echo ""
}

# ── Apply blocked_domains.txt to /etc/hosts ──────────────────
apply_blocks() {
    # Remove old block section from /etc/hosts
    sed -i "/$HOSTS_MARKER/,/$HOSTS_MARKER_END/d" /etc/hosts 2>/dev/null

    if [ ! -s "$BLOCKED_FILE" ]; then
        echo -e "  ${YELLOW}No domains to block.${NC}"
        return
    fi

    echo "" >> /etc/hosts
    echo "$HOSTS_MARKER" >> /etc/hosts
    while IFS= read -r domain; do
        domain=$(echo "$domain" | xargs)
        [ -z "$domain" ] || [ "${domain:0:1}" = "#" ] && continue
        echo "0.0.0.0 $domain" >> /etc/hosts
        echo "0.0.0.0 www.$domain" >> /etc/hosts
    done < "$BLOCKED_FILE"
    echo "$HOSTS_MARKER_END" >> /etc/hosts
}

# ── Add a domain to blocked list ─────────────────────────────
add_domain() {
    echo ""
    echo -e "${RED}▌  ADD BLOCKED DOMAIN                                          ▐${NC}"
    echo -ne "  ${YELLOW}Enter domain to block (e.g. facebook.com): ${NC}"
    read -r domain
    domain=$(echo "$domain" | xargs | tr '[:upper:]' '[:lower:]')
    if [ -z "$domain" ]; then
        echo -e "${BRED}  [!] Domain cannot be empty.${NC}"
    elif grep -qx "$domain" "$BLOCKED_FILE" 2>/dev/null; then
        echo -e "${YELLOW}  [!] $domain already in block list.${NC}"
    else
        echo "$domain" >> "$BLOCKED_FILE"
        apply_blocks
        echo -e "  ${BGREEN}[OK]${NC} $domain added to block list and applied."
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

# ── List blocked domains ─────────────────────────────────────
list_domains() {
    clear
    echo -e "${BRED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRED}║${NC}  ${BRED}██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗  ${BRED}║${NC}"
    echo -e "${BRED}║${NC}  ${BRED}██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗ ${BRED}║${NC}"
    echo -e "${BRED}║${NC}  ${BRED}██████╔╝██║     ██║   ██║██║     █████╔╝ █████╗  ██║  ██║ ${BRED}║${NC}"
    echo -e "${BRED}║${NC}  ${BRED}██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██║  ██║ ${BRED}║${NC}"
    echo -e "${BRED}║${NC}  ${BRED}██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██████╔╝ ${BRED}║${NC}"
    echo -e "${BRED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌         ★ BLOCKED DOMAINS ★                                 ▐${NC}"
    echo -e "${BRED}╔══════════════════════════════════════════════════════════════╗${NC}"

    if [ -s "$BLOCKED_FILE" ]; then
        local i=1
        while IFS= read -r domain; do
            domain=$(echo "$domain" | xargs)
            [ -z "$domain" ] && continue
            printf "${BRED}║${NC}  ${YELLOW}[%02d]${NC} ${CYAN}%-55s${BRED}║${NC}\n" "$i" "$domain"
            ((i++))
        done < "$BLOCKED_FILE"
    else
        echo -e "${BRED}║${NC}  ${YELLOW}No domains are currently blocked.${BRED}                          ║${NC}"
    fi

    echo -e "${BRED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""; read -rp "  Press Enter to continue..."
}

# ── Remove a domain ──────────────────────────────────────────
remove_domain() {
    echo ""
    echo -e "${RED}▌  REMOVE BLOCKED DOMAIN                                       ▐${NC}"
    if [ ! -s "$BLOCKED_FILE" ]; then
        echo -e "  ${YELLOW}Block list is empty.${NC}"
        echo ""; read -rp "  Press Enter to continue..."; return
    fi
    echo -e "  ${CYAN}Currently blocked:${NC}"
    local i=1
    while IFS= read -r domain; do
        domain=$(echo "$domain" | xargs)
        [ -z "$domain" ] && continue
        printf "  ${YELLOW}[%02d]${NC} ${CYAN}%s${NC}\n" "$i" "$domain"
        ((i++))
    done < "$BLOCKED_FILE"
    echo ""
    echo -ne "  ${YELLOW}Enter domain to remove: ${NC}"
    read -r domain
    domain=$(echo "$domain" | xargs | tr '[:upper:]' '[:lower:]')
    if grep -qx "$domain" "$BLOCKED_FILE" 2>/dev/null; then
        sed -i "/^${domain}$/d" "$BLOCKED_FILE"
        apply_blocks
        echo -e "  ${BGREEN}[OK]${NC} $domain removed from block list."
    else
        echo -e "${BRED}  [!] Domain not found in list.${NC}"
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}. Add a domain to be blocked"
    echo -e "  ${YELLOW}[2]${NC}. List blocked domains"
    echo -e "  ${YELLOW}[3]${NC}. Remove a domain from blocked list"
    echo -e "  ${YELLOW}[4]${NC}. Exit"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1) add_domain ;;
        2) list_domains ;;
        3) remove_domain ;;
        4|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
