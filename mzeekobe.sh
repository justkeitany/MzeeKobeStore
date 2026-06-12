#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Main Entry Point
# ============================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

INSTALL_DIR="/usr/local/mzeekobe"

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root."
    echo "Usage: sudo bash mzeekobe.sh"
    exit 1
fi

# Check install
if [ ! -f "$INSTALL_DIR/menu/menu.sh" ]; then
    echo "Error: Mzee Kobe Store panel not found at $INSTALL_DIR"
    echo "Please run the installer first."
    exit 1
fi

cd "$INSTALL_DIR" 2>/dev/null || true
exec bash "$INSTALL_DIR/menu/menu.sh"
