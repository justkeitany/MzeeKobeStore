#!/usr/bin/env python3
"""
Mzee Kobe Tunnel - Auto Expiry Manager
Runs via cron daily. Deletes expired users.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from utils import *
from ssh import delete_ssh_user
from xray import delete_xray_user

def check_and_delete_expired():
    users = load_users()
    deleted = []
    warned = []

    for username, data in list(users.items()):
        expiry = data.get("expiry", "")
        if not expiry:
            continue

        remaining = days_remaining(expiry)

        if remaining <= 0:
            utype = data.get("type", "ssh")
            if utype == "ssh":
                result = delete_ssh_user(username)
            else:
                result = delete_xray_user(username, utype)

            deleted.append({"username": username, "type": utype, "expiry": expiry})
            print(f"[DELETED] {username} ({utype}) expired on {expiry}")

        elif remaining <= 2:
            warned.append({"username": username, "days_left": remaining})
            print(f"[WARNING] {username} expires in {remaining} day(s)")

    return {"deleted": deleted, "warned": warned}

def cli():
    args = sys.argv[1:]

    if "--auto-delete" in args or not args:
        print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Running expiry check...")
        result = check_and_delete_expired()
        print(f"\nDeleted: {len(result['deleted'])} users")
        print(f"Expiring soon: {len(result['warned'])} users\n")

    elif "--list-expired" in args:
        users = load_users()
        print(header("EXPIRED USERS"))
        found = False
        for uname, data in users.items():
            if is_expired(data.get("expiry", "")):
                print(f"  {uname:<20} {data.get('type','?'):<10} Expired: {data.get('expiry','-')}")
                found = True
        if not found:
            print(yellow("  No expired users.\n"))

    elif "--list-expiring" in args:
        users = load_users()
        days = 3
        if "--days" in args:
            idx = args.index("--days")
            if idx + 1 < len(args):
                days = int(args[idx+1])
        print(header(f"EXPIRING IN {days} DAYS"))
        found = False
        for uname, data in users.items():
            remaining = days_remaining(data.get("expiry", ""))
            if 0 < remaining <= days:
                print(f"  {uname:<20} {data.get('type','?'):<10} Days left: {remaining}")
                found = True
        if not found:
            print(yellow(f"  No users expiring in {days} days.\n"))

if __name__ == "__main__":
    cli()
