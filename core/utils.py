#!/usr/bin/env python3
"""
Mzee Kobe Tunnel - Shared Utilities
"""

import os
import json
import subprocess
import hashlib
import random
import string
from datetime import datetime, timedelta

INSTALL_DIR = "/usr/local/mzeekobe"
CONFIG_FILE = "/root/mzeekobe_config.json"
USERS_FILE = f"{INSTALL_DIR}/users.json"
XRAY_CONFIG = "/usr/local/etc/xray/config.json"

# ─── COLORS ───────────────────────────────────────────────────────────────────
RED    = '\033[0;31m'
GREEN  = '\033[0;32m'
YELLOW = '\033[1;33m'
CYAN   = '\033[0;36m'
WHITE  = '\033[1;37m'
NC     = '\033[0m'

def color(text, c): return f"{c}{text}{NC}"
def red(t): return color(t, RED)
def green(t): return color(t, GREEN)
def yellow(t): return color(t, YELLOW)
def cyan(t): return color(t, CYAN)

# ─── SYSTEM ───────────────────────────────────────────────────────────────────
def run(cmd, input_data=None):
    """Run a shell command and return (stdout, stderr, returncode)."""
    env = os.environ.copy()
    env["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True,
                           input=input_data, timeout=60, env=env)
        return r.stdout.strip(), r.stderr.strip(), r.returncode
    except subprocess.TimeoutExpired:
        return "", "Timeout", 1
    except Exception as e:
        return "", str(e), 1

def get_server_ip():
    out, _, _ = run("curl -s ifconfig.me --max-time 5")
    return out or "unknown"

def get_domain():
    if os.path.exists("/root/.mzeekobe_domain"):
        return open("/root/.mzeekobe_domain").read().strip()
    if os.path.exists(CONFIG_FILE):
        return json.load(open(CONFIG_FILE)).get("domain", "")
    return ""

# ─── PASSWORD ─────────────────────────────────────────────────────────────────
def generate_password(length=12):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choices(chars, k=length))

def generate_uuid():
    out, _, _ = run("cat /proc/sys/kernel/random/uuid")
    return out or "00000000-0000-0000-0000-000000000000"

# ─── DATE HELPERS ─────────────────────────────────────────────────────────────
def expiry_date(days: int) -> str:
    return (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")

def days_remaining(date_str: str) -> int:
    try:
        exp = datetime.strptime(date_str, "%Y-%m-%d")
        delta = exp - datetime.now()
        return max(0, delta.days)
    except:
        return 0

def is_expired(date_str: str) -> bool:
    return days_remaining(date_str) <= 0

# ─── USER DATABASE ────────────────────────────────────────────────────────────
def load_users() -> dict:
    """Load users DB. Structure: {username: {type, password, expiry, max_login, created_at, ...}}"""
    if os.path.exists(USERS_FILE):
        try:
            return json.load(open(USERS_FILE))
        except:
            pass
    return {}

def save_users(users: dict):
    os.makedirs(INSTALL_DIR, exist_ok=True)
    with open(USERS_FILE, "w") as f:
        json.dump(users, f, indent=2)

def add_user_record(username: str, data: dict):
    users = load_users()
    if username not in users:
        users[username] = {}
    users[username].update(data)
    users[username]["created_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    save_users(users)

def remove_user_record(username: str):
    users = load_users()
    users.pop(username, None)
    save_users(users)

def get_user(username: str) -> dict:
    return load_users().get(username, {})

# ─── XRAY CONFIG ──────────────────────────────────────────────────────────────
def load_xray_config() -> dict:
    if os.path.exists(XRAY_CONFIG):
        return json.load(open(XRAY_CONFIG))
    return {}

def save_xray_config(config: dict):
    with open(XRAY_CONFIG, "w") as f:
        json.dump(config, f, indent=2)
    run("systemctl restart xray")

def get_xray_inbound(tag: str) -> dict:
    config = load_xray_config()
    for inbound in config.get("inbounds", []):
        if inbound.get("tag") == tag:
            return inbound
    return {}

# ─── SYSTEM INFO ──────────────────────────────────────────────────────────────
def get_system_info() -> dict:
    uptime, _, _ = run("uptime -p")
    load, _, _ = run("cat /proc/loadavg | awk '{print $1,$2,$3}'")
    mem_used, _, _ = run("free -h | awk '/^Mem/{print $3}'")
    mem_total, _, _ = run("free -h | awk '/^Mem/{print $2}'")
    disk_used, _, _ = run("df -h / | awk 'NR==2{print $3}'")
    disk_total, _, _ = run("df -h / | awk 'NR==2{print $2}'")
    disk_pct, _, _ = run("df -h / | awk 'NR==2{print $5}'")
    online, _, _ = run("who | wc -l")

    services = {}
    for svc in ["nginx", "xray", "openvpn", "ssh", "dropbear", "squid"]:
        out, _, _ = run(f"systemctl is-active {svc} 2>/dev/null")
        services[svc] = out

    return {
        "uptime": uptime,
        "load": load,
        "memory": f"{mem_used}/{mem_total}",
        "disk": f"{disk_used}/{disk_total} ({disk_pct})",
        "online_users": online,
        "services": services,
        "ip": get_server_ip(),
        "domain": get_domain(),
    }

# ─── PRINT HELPERS ────────────────────────────────────────────────────────────
def line(char="━", width=50):
    return char * width

def header(title):
    w = 50
    pad = (w - len(title) - 2) // 2
    return f"\n{cyan('┏' + '━'*w + '┓')}\n{cyan('┃')}{' '*pad} {yellow(title)} {' '*pad}{cyan('┃')}\n{cyan('┗' + '━'*w + '┛')}\n"

def box(lines, width=50):
    result = cyan("┏" + "━"*width + "┓\n")
    for l in lines:
        pad = width - len(l) - 1
        result += cyan("┃") + f" {l}" + " "*max(0, pad) + cyan("┃\n")
    result += cyan("┗" + "━"*width + "┛")
    return result
