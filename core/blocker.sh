#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Ad/Torrent/Porn Blocker
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/usr/local/mzeekobe"
HOSTS_SRC="$INSTALL_DIR/module/hosts"
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.mzeekobe.bak"
MARKER_START="# === MZEE KOBE BLOCKER START ==="
MARKER_END="# === MZEE KOBE BLOCKER END ==="

banner() {
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║     MZEE KOBE STORE - NetGuard       ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

backup_hosts() {
    if [ ! -f "$BACKUP_FILE" ]; then
        cp "$HOSTS_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}[OK] Hosts backup created at $BACKUP_FILE${NC}"
    fi
}

remove_blocker() {
    # Remove existing blocker section
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
}

enable_ads() {
    backup_hosts
    remove_blocker

    echo -e "${YELLOW}[*] Enabling ad blocking...${NC}"
    {
        echo ""
        echo "$MARKER_START"
        echo "# Ad Network Blocks - Mzee Kobe Store"
        grep -v "^#" "$HOSTS_SRC" | grep "google\|doubleclick\|adnxs\|criteo\|taboola\|outbrain\|pubmatic\|rubicon\|scorecardresearch\|quantserve\|segment\|mixpanel\|hotjar\|newrelic\|analytics\|ads\." | grep "^0.0.0.0"
        echo "$MARKER_END"
    } >> "$HOSTS_FILE"

    echo -e "${GREEN}[OK] Ad blocking enabled.${NC}"
}

enable_torrent() {
    backup_hosts
    remove_blocker

    echo -e "${YELLOW}[*] Enabling torrent site blocking...${NC}"
    {
        echo ""
        echo "$MARKER_START"
        echo "# Torrent Site Blocks - Mzee Kobe Store"
        grep -v "^#" "$HOSTS_SRC" | grep "piratebay\|kickass\|1337x\|rarbg\|extratorrent\|torrentz\|yts\|nyaa\|limetorrent\|zooqle\|bittorrent\|demonoid\|mininova\|btdb" | grep "^0.0.0.0"
        echo "$MARKER_END"
    } >> "$HOSTS_FILE"

    echo -e "${GREEN}[OK] Torrent blocking enabled.${NC}"
}

enable_porn() {
    backup_hosts
    remove_blocker

    echo -e "${YELLOW}[*] Enabling adult content blocking...${NC}"
    {
        echo ""
        echo "$MARKER_START"
        echo "# Adult Content Blocks - Mzee Kobe Store"
        grep -v "^#" "$HOSTS_SRC" | grep "pornhub\|xvideos\|xhamster\|xnxx\|redtube\|youporn\|tube8\|beeg\|brazzers\|bangbros\|naughtyamerica\|onlyfans\|spankbang\|eporner\|hclips\|tnaflix\|drtuber\|slutload\|fuq\." | grep "^0.0.0.0"
        echo "$MARKER_END"
    } >> "$HOSTS_FILE"

    echo -e "${GREEN}[OK] Adult content blocking enabled.${NC}"
}

enable_all() {
    backup_hosts
    remove_blocker

    echo -e "${YELLOW}[*] Enabling all blockers (ads + torrent + adult)...${NC}"
    {
        echo ""
        echo "$MARKER_START"
        echo "# Full Block List - Mzee Kobe Store"
        grep -v "^#" "$HOSTS_SRC" | grep "^0.0.0.0"
        echo "$MARKER_END"
    } >> "$HOSTS_FILE"

    echo -e "${GREEN}[OK] All blocking enabled.${NC}"
}

disable_all() {
    echo -e "${YELLOW}[*] Disabling all blockers...${NC}"
    remove_blocker
    echo -e "${GREEN}[OK] All blocking disabled.${NC}"
}

restore_hosts() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$HOSTS_FILE"
        echo -e "${GREEN}[OK] Hosts file restored from backup.${NC}"
    else
        echo -e "${RED}[!] No backup found.${NC}"
    fi
}

status_blocker() {
    echo -e "${CYAN}[*] Blocker Status:${NC}"
    if grep -q "$MARKER_START" "$HOSTS_FILE" 2>/dev/null; then
        COUNT=$(grep "^0.0.0.0" "$HOSTS_FILE" | wc -l)
        echo -e "  Status  : ${GREEN}ACTIVE${NC}"
        echo -e "  Blocked : ${YELLOW}$COUNT domains${NC}"
    else
        echo -e "  Status  : ${RED}INACTIVE${NC}"
    fi
}

banner

case "${1}" in
    ads)       enable_ads ;;
    torrent)   enable_torrent ;;
    porn)      enable_porn ;;
    all)       enable_all ;;
    disable)   disable_all ;;
    restore)   restore_hosts ;;
    status)    status_blocker ;;
    *)
        echo -e "Usage: $0 {ads|torrent|porn|all|disable|restore|status}"
        ;;
esac
