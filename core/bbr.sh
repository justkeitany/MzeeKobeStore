#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - TCP BBR Optimization
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

enable_bbr() {
    echo -e "${YELLOW}[*] Enabling TCP BBR congestion control...${NC}"

    # Check kernel version (BBR requires >= 4.9)
    KERNEL=$(uname -r | cut -d. -f1-2 | tr -d '.')
    if [ "$KERNEL" -lt 49 ]; then
        echo -e "${RED}[!] Kernel $(uname -r) may not support BBR. Proceeding anyway...${NC}"
    fi

    # Load the BBR module
    modprobe tcp_bbr 2>/dev/null

    # Set qdisc and congestion control
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1

    # Make persistent in /etc/sysctl.conf
    # Remove old entries first
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

    # Append new settings
    echo "" >> /etc/sysctl.conf
    echo "# Mzee Kobe Store - TCP BBR" >> /etc/sysctl.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    # Additional performance tweaks
    sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
    echo "net.core.rmem_max=67108864" >> /etc/sysctl.conf
    echo "net.core.wmem_max=67108864" >> /etc/sysctl.conf

    sysctl -p >/dev/null 2>&1

    # Verify
    CURRENT=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    if [ "$CURRENT" = "bbr" ]; then
        echo -e "${GREEN}[OK] BBR enabled successfully!${NC}"
        echo -e "${GREEN}     Congestion control: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')${NC}"
        echo -e "${GREEN}     Queue disc: $(sysctl net.core.default_qdisc | awk '{print $3}')${NC}"
    else
        echo -e "${RED}[!] BBR may not be active. Current: $CURRENT${NC}"
    fi
}

status_bbr() {
    echo -e "${CYAN}[*] BBR Status:${NC}"
    echo -e "  Congestion control : $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')"
    echo -e "  Queue disc         : $(sysctl net.core.default_qdisc 2>/dev/null | awk '{print $3}')"
    echo -e "  Available          : $(sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | awk '{print $3}')"
}

case "${1}" in
    enable)
        enable_bbr
        ;;
    status)
        status_bbr
        ;;
    *)
        enable_bbr
        ;;
esac
