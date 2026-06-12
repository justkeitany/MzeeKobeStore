#!/usr/bin/env python3
"""
Mzee Kobe Tunnel - Server Status
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from utils import *

def show_status():
    info = get_system_info()
    users = load_users()

    ssh_users = sum(1 for u in users.values() if u.get("type") == "ssh")
    xray_users = sum(1 for u in users.values() if u.get("type") in ["vmess","vless","trojan","socks"])
    expired = sum(1 for u in users.values() if is_expired(u.get("expiry","")))

    print(header("SERVER STATUS"))

    # Services
    print(cyan("  Services:"))
    for svc, state in info["services"].items():
        icon = green("●") if state == "active" else red("●")
        print(f"  {icon} {svc.upper():<12} {state}")

    print()
    print(cyan("  System:"))
    print(f"  {'IP':<14}: {info['ip']}")
    print(f"  {'Domain':<14}: {info['domain']}")
    print(f"  {'Uptime':<14}: {info['uptime']}")
    print(f"  {'Load':<14}: {info['load']}")
    print(f"  {'Memory':<14}: {info['memory']}")
    print(f"  {'Disk':<14}: {info['disk']}")
    print(f"  {'Online Users':<14}: {info['online_users']}")

    print()
    print(cyan("  Users:"))
    print(f"  {'SSH Users':<14}: {green(str(ssh_users))}")
    print(f"  {'XRAY Users':<14}: {green(str(xray_users))}")
    print(f"  {'Expired':<14}: {red(str(expired)) if expired > 0 else green('0')}")
    print()

if __name__ == "__main__":
    show_status()
