#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Max Login Enforcer (runs via cron)
#   Designed to run every minute: * * * * * /path/validator.sh
# ============================================================

INSTALL_DIR="/usr/local/mzeekobe"
USERS_JSON="$INSTALL_DIR/users.json"
LOG_FILE="/var/log/mzeekobe_validator.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Requires python3 and jq
if ! command -v python3 >/dev/null 2>&1; then
    log "[ERROR] python3 not found"
    exit 1
fi

if [ ! -f "$USERS_JSON" ]; then
    # No users file yet, nothing to validate
    exit 0
fi

# Get list of users with max_login limits using python3
python3 << 'PYEOF'
import json
import subprocess
import os
import sys

USERS_JSON = "/usr/local/mzeekobe/users.json"
LOG_FILE = "/var/log/mzeekobe_validator.log"

def log_msg(msg):
    import datetime
    ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a') as f:
        f.write(f"{ts} {msg}\n")

try:
    with open(USERS_JSON, 'r') as f:
        users = json.load(f)
except Exception as e:
    log_msg(f"[ERROR] Could not read {USERS_JSON}: {e}")
    sys.exit(0)

# Get all active SSH sessions
try:
    result = subprocess.run(['who'], capture_output=True, text=True)
    sessions_raw = result.stdout.strip().split('\n')
except Exception as e:
    log_msg(f"[ERROR] Could not run 'who': {e}")
    sys.exit(0)

# Count sessions per user
session_count = {}
for line in sessions_raw:
    if line.strip():
        parts = line.split()
        if parts:
            username = parts[0]
            session_count[username] = session_count.get(username, 0) + 1

# Check each user against their limit
for username, user_data in users.items():
    if not isinstance(user_data, dict):
        continue

    max_login = user_data.get('max_login', 0)
    if max_login <= 0:
        continue

    active = session_count.get(username, 0)
    if active > max_login:
        excess = active - max_login
        log_msg(f"[KICK] {username}: {active}/{max_login} sessions, killing {excess} excess")

        # Kill excess sessions (oldest first via pkill)
        try:
            subprocess.run(
                ['pkill', '-u', username, '-o', '-KILL'],
                capture_output=True
            )
            log_msg(f"[KICK] Killed session for {username}")
        except Exception as e:
            log_msg(f"[ERROR] Could not kill session for {username}: {e}")

PYEOF

exit 0
