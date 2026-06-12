#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Panel Updater
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
GITHUB_REPO="https://raw.githubusercontent.com/justkeitany/MzeeKobeStore/main"
VERSION_FILE="$INSTALL_DIR/version"
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")

clear
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  ${BCYAN}          ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  ${BCYAN}         ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}  ${BCYAN}╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗${BCYAN} PANEL    ${MAGENTA}║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${RED}▌  ★  UPDATE PANEL  ★   Mzee Kobe Store                       ▐${NC}"
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Current version${NC}: ${YELLOW}$CURRENT_VERSION${NC}"
echo ""

# ── Check for update ─────────────────────────────────────────
echo -e "${YELLOW}  [*] Checking for updates...${NC}"
REMOTE_VERSION=$(curl -s --max-time 10 "$GITHUB_REPO/version" 2>/dev/null | tr -d '[:space:]')

if [ -z "$REMOTE_VERSION" ]; then
    echo -e "${BRED}  [!] Could not reach update server. Check internet connection.${NC}"
    echo ""
    read -rp "  Press Enter to go back..."
    exit 0
fi

echo -e "  ${CYAN}Remote version ${NC}: ${GREEN}$REMOTE_VERSION${NC}"
echo ""

if [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo -e "${BGREEN}  [OK] You are running the latest version!${NC}"
    echo ""
    read -rp "  Press Enter to go back..."
    exit 0
fi

echo -e "${YELLOW}  [!] Update available: ${BRED}$CURRENT_VERSION${NC} → ${BGREEN}$REMOTE_VERSION${NC}"
echo ""
echo -ne "  ${YELLOW}Update now? [y/N]: ${NC}"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}  Update cancelled.${NC}"
    echo ""; read -rp "  Press Enter to go back..."; exit 0
fi

echo ""
echo -e "${YELLOW}  [*] Downloading update...${NC}"

dl_ok() { echo -e "  ${BGREEN}[OK  ]${NC} $1"; }
dl_fail() { echo -e "  ${BRED}[FAIL]${NC} $1"; }
dl_skip() { echo -e "  ${CYAN}[SKIP]${NC} $1"; }

# ── Update core Python scripts ────────────────────────────────
for script in ssh.py xray.py menu.py status.py expiry.py utils.py validator.py; do
    wget -q "$GITHUB_REPO/core/$script" -O "$INSTALL_DIR/core/$script.new" --timeout=15 2>/dev/null
    if [ -s "$INSTALL_DIR/core/$script.new" ]; then
        mv "$INSTALL_DIR/core/$script.new" "$INSTALL_DIR/core/$script"
        dl_ok "core/$script"
    else
        rm -f "$INSTALL_DIR/core/$script.new"
        dl_skip "core/$script"
    fi
done

# ── Update menu scripts ───────────────────────────────────────
for script in menu.sh ssh.sh vmess.sh vless.sh trojan.sh socks.sh status.sh expiry.sh \
              domain.sh dns.sh port.sh log.sh iptools.sh netguard.sh update.sh zivpn.sh; do
    wget -q "$GITHUB_REPO/menu/$script" -O "$INSTALL_DIR/menu/$script.new" --timeout=15 2>/dev/null
    if [ -s "$INSTALL_DIR/menu/$script.new" ]; then
        mv "$INSTALL_DIR/menu/$script.new" "$INSTALL_DIR/menu/$script"
        chmod +x "$INSTALL_DIR/menu/$script"
        dl_ok "menu/$script"
    else
        rm -f "$INSTALL_DIR/menu/$script.new"
        dl_skip "menu/$script"
    fi
done

# ── Update version ────────────────────────────────────────────
echo "$REMOTE_VERSION" > "$VERSION_FILE"

echo ""
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}  ${BGREEN}Panel updated successfully!${NC}"
echo -e "${MAGENTA}║${NC}  ${CYAN}Version${NC}: ${YELLOW}$CURRENT_VERSION${NC} → ${BGREEN}$REMOTE_VERSION${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
read -rp "  Press Enter to go back..."
