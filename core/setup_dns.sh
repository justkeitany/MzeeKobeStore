#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - DNS Configuration
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

RESOLV_CONF="/etc/resolv.conf"

setup_dns() {
    local DNS1="${1:-1.1.1.1}"
    local DNS2="${2:-8.8.8.8}"

    echo -e "${YELLOW}[*] Configuring DNS servers...${NC}"

    # Backup original
    if [ ! -f "${RESOLV_CONF}.bak" ]; then
        cp "$RESOLV_CONF" "${RESOLV_CONF}.bak"
        echo -e "${GREEN}[OK] Backup saved to ${RESOLV_CONF}.bak${NC}"
    fi

    # Remove immutable flag if set
    chattr -i "$RESOLV_CONF" 2>/dev/null

    # Write new DNS config
    cat > "$RESOLV_CONF" << EOF
# Mzee Kobe Store - DNS Configuration
nameserver $DNS1
nameserver $DNS2
nameserver 1.0.0.1
nameserver 8.8.4.4
options timeout:2 attempts:3 rotate
EOF

    # Prevent overwrite by DHCP
    chattr +i "$RESOLV_CONF" 2>/dev/null

    echo -e "${GREEN}[OK] DNS configured: $DNS1, $DNS2${NC}"
}

reset_dns() {
    echo -e "${YELLOW}[*] Resetting DNS to defaults...${NC}"
    chattr -i "$RESOLV_CONF" 2>/dev/null
    if [ -f "${RESOLV_CONF}.bak" ]; then
        cp "${RESOLV_CONF}.bak" "$RESOLV_CONF"
        echo -e "${GREEN}[OK] DNS restored from backup.${NC}"
    else
        cat > "$RESOLV_CONF" << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
        echo -e "${GREEN}[OK] DNS reset to defaults.${NC}"
    fi
}

status_dns() {
    echo -e "${CYAN}[*] Current DNS Configuration:${NC}"
    cat "$RESOLV_CONF"
    echo ""
    echo -e "${CYAN}[*] Testing DNS resolution:${NC}"
    if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
        echo -e "  ${GREEN}DNS working correctly${NC}"
    else
        echo -e "  ${RED}DNS resolution failed${NC}"
    fi
}

case "${1}" in
    setup)
        setup_dns "${2}" "${3}"
        ;;
    reset)
        reset_dns
        ;;
    status)
        status_dns
        ;;
    cloudflare)
        setup_dns "1.1.1.1" "1.0.0.1"
        ;;
    google)
        setup_dns "8.8.8.8" "8.8.4.4"
        ;;
    *)
        # Default: setup with Cloudflare + Google
        setup_dns "1.1.1.1" "8.8.8.8"
        ;;
esac
