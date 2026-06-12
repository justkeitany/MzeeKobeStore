#!/usr/bin/env python3
"""
Mzee Kobe Tunnel - SSH User Management
Usage: ssh.py add|del|list|renew|lock|unlock|info [args]
"""

import sys
import os
import subprocess
from datetime import datetime
sys.path.insert(0, os.path.dirname(__file__))
from utils import *

# ─── SSH USER OPERATIONS ──────────────────────────────────────────────────────

def create_ssh_user(username: str, days: int, max_login: int = 2, password: str = None) -> dict:
    """Create a new SSH user."""
    if not password:
        password = username  # default password = username

    # Check if user already exists
    out, _, _ = run(f"id {username} 2>/dev/null")
    if out:
        return {"success": False, "error": f"User '{username}' already exists"}

    # Create system user with expiry
    exp = expiry_date(days)
    exp_shadow = (datetime.now() + __import__('datetime').timedelta(days=days)).strftime("%Y-%m-%d")

    # Add user
    _, err, rc = run(f"useradd -m -s /bin/bash -e {exp} {username}")
    if rc != 0:
        _, err, rc = run(f"adduser --disabled-password --gecos '' {username}")
        if rc != 0:
            return {"success": False, "error": err}

    # Set password
    _, err, rc = run(f"echo '{username}:{password}' | chpasswd")
    if rc != 0:
        return {"success": False, "error": f"Failed to set password: {err}"}

    # Set expiry
    run(f"chage -E {exp} {username}")

    # Store in DB
    add_user_record(username, {
        "type": "ssh",
        "password": password,
        "expiry": exp,
        "days": days,
        "max_login": max_login,
        "status": "active"
    })

    domain = get_domain()
    ip = get_server_ip()

    return {
        "success": True,
        "username": username,
        "password": password,
        "expiry": exp,
        "days": days,
        "max_login": max_login,
        "host": domain or ip,
        "ip": ip,
        "ports": {
            "ssh": "22",
            "dropbear": "22",
            "ssl": "443",
            "ws": "80"
        }
    }

def delete_ssh_user(username: str) -> dict:
    """Delete an SSH user."""
    out, _, _ = run(f"id {username} 2>/dev/null")
    if not out:
        return {"success": False, "error": f"User '{username}' not found"}

    run(f"pkill -u {username} 2>/dev/null")
    _, err, rc = run(f"userdel -r {username} 2>/dev/null")
    remove_user_record(username)

    return {"success": True, "username": username}

def renew_ssh_user(username: str, days: int) -> dict:
    """Renew SSH user expiry."""
    out, _, _ = run(f"id {username} 2>/dev/null")
    if not out:
        return {"success": False, "error": f"User '{username}' not found"}

    exp = expiry_date(days)
    _, err, rc = run(f"chage -E {exp} {username}")
    if rc != 0:
        return {"success": False, "error": err}

    users = load_users()
    if username in users:
        users[username]["expiry"] = exp
        users[username]["days"] = days
        save_users(users)

    return {"success": True, "username": username, "new_expiry": exp, "days": days}

def lock_ssh_user(username: str) -> dict:
    """Lock SSH user."""
    _, err, rc = run(f"passwd -l {username}")
    if rc != 0:
        return {"success": False, "error": err}

    users = load_users()
    if username in users:
        users[username]["status"] = "locked"
        save_users(users)

    return {"success": True, "username": username, "status": "locked"}

def unlock_ssh_user(username: str) -> dict:
    """Unlock SSH user."""
    _, err, rc = run(f"passwd -u {username}")
    if rc != 0:
        return {"success": False, "error": err}

    users = load_users()
    if username in users:
        users[username]["status"] = "active"
        save_users(users)

    return {"success": True, "username": username, "status": "active"}

def list_ssh_users() -> list:
    """List all SSH users from DB."""
    users = load_users()
    result = []
    for uname, data in users.items():
        if data.get("type") == "ssh":
            remaining = days_remaining(data.get("expiry", ""))
            status = data.get("status", "active")
            if is_expired(data.get("expiry", "")) and status == "active":
                status = "expired"
            result.append({
                "username": uname,
                "expiry": data.get("expiry", "-"),
                "days_left": remaining,
                "max_login": data.get("max_login", 2),
                "status": status
            })
    return sorted(result, key=lambda x: x["username"])

def get_online_users() -> list:
    """Get currently logged-in SSH users."""
    out, _, _ = run("who | awk '{print $1}' | sort | uniq -c | sort -rn")
    result = []
    for line_str in out.splitlines():
        parts = line_str.strip().split()
        if len(parts) >= 2:
            result.append({"count": parts[0], "username": parts[1]})
    return result

def get_user_info(username: str) -> dict:
    """Get detailed info for a user."""
    data = get_user(username)
    if not data:
        return {"error": f"User '{username}' not found in DB"}

    # Check if logged in
    out, _, _ = run(f"who | grep -c {username} 2>/dev/null")
    sessions = int(out) if out.isdigit() else 0

    return {
        "username": username,
        "type": data.get("type", "ssh"),
        "password": data.get("password", "-"),
        "expiry": data.get("expiry", "-"),
        "days_left": days_remaining(data.get("expiry", "")),
        "max_login": data.get("max_login", 2),
        "active_sessions": sessions,
        "status": data.get("status", "active"),
        "created_at": data.get("created_at", "-"),
    }

# ─── CLI ──────────────────────────────────────────────────────────────────────
def parse_args(argv):
    """Parse both positional and --flag style arguments."""
    import argparse
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("cmd", nargs="?", default="")
    p.add_argument("--user", "-u", default=None)
    p.add_argument("--pass", "--password", dest="password", default=None)
    p.add_argument("--days", "-d", default=None)
    p.add_argument("--limit", "--max", dest="limit", default=None)
    # Allow positional fallback: ssh add username days limit [password]
    p.add_argument("pos1", nargs="?", default=None)
    p.add_argument("pos2", nargs="?", default=None)
    p.add_argument("pos3", nargs="?", default=None)
    p.add_argument("pos4", nargs="?", default=None)
    args, _ = p.parse_known_args(argv)

    # Resolve positional fallbacks
    user = args.user or args.pos1
    days_val = args.days or args.pos2
    limit_val = args.limit or args.pos3
    password = args.password or args.pos4

    return args.cmd, user, days_val, limit_val, password

def print_user_table(users: list):
    if not users:
        print(yellow("  No SSH users found."))
        return
    print(cyan(f"\n  {'USERNAME':<20} {'EXPIRY':<12} {'DAYS':<6} {'LOGINS':<8} {'STATUS':<10}"))
    print(cyan("  " + "─" * 60))
    for u in users:
        days = u["days_left"]
        status = u["status"]
        color_fn = green if status == "active" and days > 3 else (yellow if days <= 3 else red)
        print(f"  {u['username']:<20} {u['expiry']:<12} {days:<6} {u['max_login']:<8} {color_fn(status):<10}")
    print()

def cli():
    if len(sys.argv) < 2:
        print(f"\n  Usage: ssh add|delete|list|renew|lock|unlock|info|online [args]\n")
        return

    cmd = sys.argv[1].lower()
    _, user, days_val, limit_val, password = parse_args(sys.argv[2:])

    if cmd in ("add", "create"):
        if not user:
            print("  Usage: ssh add --user <name> --pass <pass> --days <n> --limit <n>")
            return
        days = int(days_val or 30)
        limit = int(limit_val or 2)
        result = create_ssh_user(user, days, limit, password)
        if result["success"]:
            print(green(f"\n  ✓ SSH User Created!\n"))
            print(f"  Username  : {result['username']}")
            print(f"  Password  : {result['password']}")
            print(f"  Expiry    : {result['expiry']} ({result['days']} days)")
            print(f"  Max Login : {result['max_login']}")
            print(f"  Host      : {result['host']}")
            print(f"  Ports     : SSH=22 | Dropbear=22 | SSL=443 | WS=80")
        else:
            print(red(f"\n  ✗ Error: {result['error']}\n"))

    elif cmd in ("del", "delete", "remove"):
        if not user:
            print("  Usage: ssh delete --user <name>")
            return
        result = delete_ssh_user(user)
        print(green(f"\n  ✓ User '{user}' deleted.\n") if result["success"] else red(f"\n  ✗ {result['error']}\n"))

    elif cmd == "renew":
        if not user or not days_val:
            print("  Usage: ssh renew --user <name> --days <n>")
            return
        result = renew_ssh_user(user, int(days_val))
        print(green(f"\n  ✓ Renewed until {result['new_expiry']}.\n") if result["success"] else red(f"\n  ✗ {result['error']}\n"))

    elif cmd == "lock":
        if not user:
            print("  Usage: ssh lock --user <name>"); return
        result = lock_ssh_user(user)
        print(green(f"\n  ✓ User '{user}' locked.\n") if result["success"] else red(f"\n  ✗ {result['error']}\n"))

    elif cmd == "unlock":
        if not user:
            print("  Usage: ssh unlock --user <name>"); return
        result = unlock_ssh_user(user)
        print(green(f"\n  ✓ User '{user}' unlocked.\n") if result["success"] else red(f"\n  ✗ {result['error']}\n"))

    elif cmd == "list":
        users = list_ssh_users()
        print(header("SSH USERS"))
        print_user_table(users)
        print(f"  Total: {green(str(len(users)))} users\n")

    elif cmd == "info":
        if not user:
            print("  Usage: ssh info --user <name>"); return
        info = get_user_info(user)
        if "error" in info:
            print(red(f"\n  ✗ {info['error']}\n"))
        else:
            print(header(f"USER: {info['username']}"))
            for k, v in info.items():
                print(f"  {k:<20}: {v}")
            print()

    elif cmd == "online":
        users = get_online_users()
        print(header("ONLINE SSH USERS"))
        if not users:
            print(yellow("  No users currently online.\n"))
        else:
            for u in users:
                print(f"  {u['username']:<20} Sessions: {u['count']}")
        print()

    else:
        print(f"  Unknown command: {cmd}")

if __name__ == "__main__":
    cli()
