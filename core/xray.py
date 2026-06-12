#!/usr/bin/env python3
"""
Mzee Kobe Tunnel - XRAY User Management
Supports: VMess, VLESS, Trojan, SOCKS
Usage: xray.py add|del|list|renew|info <protocol> [args]
"""

import sys
import os
import json
sys.path.insert(0, os.path.dirname(__file__))
from utils import *

PROTOCOLS = {
    "vmess":  {"tag": "vmess-ws",  "port": 10001, "path": "/vmess"},
    "vless":  {"tag": "vless-ws",  "port": 10002, "path": "/vless"},
    "trojan": {"tag": "trojan-ws", "port": 10003, "path": "/trojan"},
    "socks":  {"tag": "socks-ws",  "port": 10004, "path": "/socks"},
}

# ─── XRAY USER OPERATIONS ─────────────────────────────────────────────────────

def add_vmess_user(username: str, days: int) -> dict:
    config = load_xray_config()
    uid = generate_uuid()
    exp = expiry_date(days)

    for inbound in config.get("inbounds", []):
        if inbound.get("tag") == "vmess-ws":
            inbound["settings"]["clients"].append({
                "id": uid, "alterId": 0, "email": username
            })
            break

    save_xray_config(config)
    add_user_record(username, {
        "type": "vmess", "uuid": uid, "expiry": exp,
        "days": days, "path": "/vmess", "status": "active"
    })

    domain = get_domain()
    return {
        "success": True, "protocol": "vmess",
        "username": username, "uuid": uid,
        "expiry": exp, "days": days,
        "link": _vmess_link(username, uid, domain, "/vmess"),
        "host": domain, "path": "/vmess",
        "tls_port": 443, "ntls_port": 80
    }

def add_vless_user(username: str, days: int) -> dict:
    config = load_xray_config()
    uid = generate_uuid()
    exp = expiry_date(days)

    for inbound in config.get("inbounds", []):
        if inbound.get("tag") == "vless-ws":
            inbound["settings"]["clients"].append({
                "id": uid, "email": username
            })
            break

    save_xray_config(config)
    add_user_record(username, {
        "type": "vless", "uuid": uid, "expiry": exp,
        "days": days, "path": "/vless", "status": "active"
    })

    domain = get_domain()
    return {
        "success": True, "protocol": "vless",
        "username": username, "uuid": uid,
        "expiry": exp, "days": days,
        "link": _vless_link(username, uid, domain, "/vless"),
        "host": domain, "path": "/vless",
        "tls_port": 443, "ntls_port": 80
    }

def add_trojan_user(username: str, days: int, password: str = None) -> dict:
    config = load_xray_config()
    if not password:
        password = generate_password(16)
    exp = expiry_date(days)

    for inbound in config.get("inbounds", []):
        if inbound.get("tag") == "trojan-ws":
            inbound["settings"]["clients"].append({
                "password": password, "email": username
            })
            break

    save_xray_config(config)
    add_user_record(username, {
        "type": "trojan", "password": password, "expiry": exp,
        "days": days, "path": "/trojan", "status": "active"
    })

    domain = get_domain()
    return {
        "success": True, "protocol": "trojan",
        "username": username, "password": password,
        "expiry": exp, "days": days,
        "link": _trojan_link(username, password, domain, "/trojan"),
        "host": domain, "path": "/trojan",
        "tls_port": 443, "ntls_port": 80
    }

def add_socks_user(username: str, days: int, password: str = None) -> dict:
    config = load_xray_config()
    if not password:
        password = generate_password(12)
    exp = expiry_date(days)

    for inbound in config.get("inbounds", []):
        if inbound.get("tag") == "socks-ws":
            inbound["settings"]["accounts"].append({
                "user": username, "pass": password
            })
            break

    save_xray_config(config)
    add_user_record(username, {
        "type": "socks", "password": password, "expiry": exp,
        "days": days, "path": "/socks", "status": "active"
    })

    domain = get_domain()
    return {
        "success": True, "protocol": "socks",
        "username": username, "password": password,
        "expiry": exp, "days": days,
        "host": domain, "path": "/socks",
        "tls_port": 443, "ntls_port": 80
    }

def delete_xray_user(username: str, protocol: str = None) -> dict:
    """Delete XRAY user from config and DB."""
    config = load_xray_config()
    user_data = get_user(username)
    if not user_data:
        return {"success": False, "error": f"User '{username}' not found"}

    proto = protocol or user_data.get("type", "")
    tag_map = {"vmess": "vmess-ws", "vless": "vless-ws", "trojan": "trojan-ws", "socks": "socks-ws"}
    tag = tag_map.get(proto)

    removed = False
    for inbound in config.get("inbounds", []):
        if inbound.get("tag") == tag:
            clients_key = "clients" if proto != "socks" else "accounts"
            id_key = "id" if proto in ("vmess", "vless") else ("user" if proto == "socks" else "password")
            match_val = user_data.get("uuid") if proto in ("vmess", "vless") else (
                username if proto == "socks" else user_data.get("password"))
            
            original = inbound["settings"].get(clients_key, [])
            field = "id" if proto in ("vmess", "vless") else ("user" if proto == "socks" else "password")
            inbound["settings"][clients_key] = [
                c for c in original
                if c.get(field) != match_val and c.get("email") != username
            ]
            removed = True
            break

    if removed:
        save_xray_config(config)

    remove_user_record(username)
    return {"success": True, "username": username, "protocol": proto}

def renew_xray_user(username: str, days: int) -> dict:
    """Renew XRAY user expiry in DB (Xray doesn't have native expiry)."""
    users = load_users()
    if username not in users:
        return {"success": False, "error": f"User '{username}' not found"}

    exp = expiry_date(days)
    users[username]["expiry"] = exp
    users[username]["days"] = days
    save_users(users)

    return {"success": True, "username": username, "new_expiry": exp}

def list_xray_users(protocol: str = None) -> list:
    """List XRAY users."""
    users = load_users()
    result = []
    xray_types = ["vmess", "vless", "trojan", "socks"]

    for uname, data in users.items():
        utype = data.get("type", "")
        if utype not in xray_types:
            continue
        if protocol and utype != protocol:
            continue

        remaining = days_remaining(data.get("expiry", ""))
        status = data.get("status", "active")
        if is_expired(data.get("expiry", "")) and status == "active":
            status = "expired"

        result.append({
            "username": uname,
            "protocol": utype,
            "expiry": data.get("expiry", "-"),
            "days_left": remaining,
            "status": status
        })

    return sorted(result, key=lambda x: (x["protocol"], x["username"]))

# ─── LINK GENERATORS ──────────────────────────────────────────────────────────
def _vmess_link(name, uid, host, path) -> str:
    import base64
    config = {
        "v": "2", "ps": name, "add": host, "port": "443",
        "id": uid, "aid": "0", "net": "ws", "type": "none",
        "host": host, "path": path, "tls": "tls"
    }
    encoded = base64.b64encode(json.dumps(config).encode()).decode()
    return f"vmess://{encoded}"

def _vless_link(name, uid, host, path) -> str:
    return f"vless://{uid}@{host}:443?encryption=none&security=tls&type=ws&host={host}&path={path}#{name}"

def _trojan_link(name, password, host, path) -> str:
    return f"trojan://{password}@{host}:443?security=tls&type=ws&host={host}&path={path}#{name}"

# ─── CLI ──────────────────────────────────────────────────────────────────────
# ─── CLI ──────────────────────────────────────────────────────────────────────
PROTO_MAP = {
    "vmess": add_vmess_user,
    "vless": add_vless_user,
    "trojan": add_trojan_user,
    "socks": add_socks_user,
}

def cli():
    """
    Supports two calling styles:
      New (from menus):   xray.py add --proto vmess --user alice --days 30
      Old (positional):   xray.py vmess add alice 30
    """
    import argparse
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("cmd", nargs="?", default=None)
    p.add_argument("--proto", "-P", default=None)
    p.add_argument("--user", "-u", default=None)
    p.add_argument("--days", "-d", default=None)
    p.add_argument("--list", action="store_true")
    p.add_argument("pos1", nargs="?", default=None)  # old style: proto
    p.add_argument("pos2", nargs="?", default=None)  # old style: subcommand
    p.add_argument("pos3", nargs="?", default=None)  # old style: user
    p.add_argument("pos4", nargs="?", default=None)  # old style: days
    args, _ = p.parse_known_args(sys.argv[1:])

    # Resolve old positional style: xray vmess add alice 30
    if args.cmd and args.cmd in PROTO_MAP:
        proto = args.cmd
        cmd = args.pos1 or "list"
        user = args.user or args.pos2
        days_val = args.days or args.pos3
    else:
        cmd = args.cmd or "list"
        proto = args.proto or args.pos1
        user = args.user or args.pos2
        days_val = args.days or args.pos3

    if not proto and cmd not in ("list",):
        print(red(f"\n  Usage: xray.py <cmd> --proto <vmess|vless|trojan|socks> --user <name> --days <n>\n"))
        return

    if proto and proto not in PROTO_MAP and proto != "all":
        print(red(f"\n  Unknown protocol: {proto}\n"))
        return

    if cmd in ("add", "create"):
        if not user or not days_val:
            print(f"  Usage: xray add --proto {proto} --user <name> --days <n>"); return
        fn = PROTO_MAP[proto]
        result = fn(user, int(days_val))
        if result["success"]:
            print(green(f"\n  ✓ {proto.upper()} User Created!\n"))
            print(f"  Username : {result['username']}")
            if "uuid" in result:
                print(f"  UUID     : {result['uuid']}")
            else:
                print(f"  Password : {result['password']}")
            print(f"  Expiry   : {result['expiry']} ({result['days']} days)")
            print(f"  Host     : {result['host']}")
            print(f"  Path     : {result['path']}")
            print(f"  TLS Port : 443  NTLS Port : 80")
            if "link" in result:
                print(f"\n  Link:\n  {result['link']}\n")
        else:
            print(red(f"\n  ✗ {result.get('error', 'Unknown error')}\n"))

    elif cmd in ("del", "delete", "remove"):
        if not user:
            print(f"  Usage: xray delete --proto {proto} --user <name>"); return
        result = delete_xray_user(user, proto)
        print(green(f"\n  ✓ User '{user}' deleted.\n") if result["success"] else red(f"\n  ✗ {result.get('error')}\n"))

    elif cmd == "renew":
        if not user or not days_val:
            print(f"  Usage: xray renew --proto {proto} --user <name> --days <n>"); return
        result = renew_xray_user(user, int(days_val))
        print(green(f"\n  ✓ User '{user}' renewed until {result.get('new_expiry')}.\n") if result["success"] else red(f"\n  ✗ {result.get('error')}\n"))

    elif cmd == "list":
        users = list_xray_users(None if proto == "all" else proto)
        print(header(f"XRAY USERS{' - ' + proto.upper() if proto and proto != 'all' else ''}"))
        if not users:
            print(yellow("  No users found.\n"))
        else:
            print(cyan(f"  {'USERNAME':<20} {'PROTOCOL':<10} {'EXPIRY':<12} {'DAYS':<6} {'STATUS'}"))
            print(cyan("  " + "─" * 60))
            for u in users:
                d = u["days_left"]; s = u["status"]
                cf = green if s == "active" and d > 3 else (yellow if d <= 3 else red)
                print(f"  {u['username']:<20} {u['protocol']:<10} {u['expiry']:<12} {d:<6} {cf(s)}")
            print(f"\n  Total: {green(str(len(users)))} users\n")

    else:
        print(f"  Unknown command: {cmd}")

if __name__ == "__main__":
    cli()

