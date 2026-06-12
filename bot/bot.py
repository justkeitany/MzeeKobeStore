#!/usr/bin/env python3
"""
Mzee Kobe Tunnel - Telegram Bot
Manages VPN users remotely via Telegram.
"""

import os
import sys
import json
import logging
import re
from datetime import datetime

# Add parent dir for core imports
sys.path.insert(0, "/usr/local/mzeekobe/core")

from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application, CommandHandler, CallbackQueryHandler,
    ContextTypes, ConversationHandler, MessageHandler, filters
)

# ─── CONFIG ───────────────────────────────────────────────────────────────────
BOT_CONFIG_FILE = "/root/mzeekobe_bot.json"
TOKEN_FILE = "/root/.mzeekobe_bot_token"
LOG_FILE = "/var/log/mzeekobe_bot.log"

# Conversation states
(W_USERNAME, W_DAYS, W_LIMIT, W_PROTO, W_TARGET, W_RDAYS) = range(6)

# ─── LOGGING ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(message)s",
    level=logging.INFO,
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ─── BOT CONFIG ───────────────────────────────────────────────────────────────
def load_bot_config() -> dict:
    default = {
        "owner_id": None,
        "admins": [],
        "resellers": {},
        "banned": [],
    }
    if os.path.exists(BOT_CONFIG_FILE):
        try:
            with open(BOT_CONFIG_FILE) as f:
                data = json.load(f)
                default.update(data)
        except:
            pass
    return default

def save_bot_config(cfg: dict):
    with open(BOT_CONFIG_FILE, "w") as f:
        json.dump(cfg, f, indent=2)

def get_token() -> str:
    if os.path.exists(TOKEN_FILE):
        return open(TOKEN_FILE).read().strip()
    return os.environ.get("BOT_TOKEN", "")

# ─── PERMISSIONS ──────────────────────────────────────────────────────────────
def is_owner(uid, cfg) -> bool:
    return str(uid) == str(cfg.get("owner_id"))

def is_admin(uid, cfg) -> bool:
    return str(uid) in [str(x) for x in cfg.get("admins", [])] or is_owner(uid, cfg)

def is_reseller(uid, cfg) -> bool:
    return str(uid) in cfg.get("resellers", {}) or is_admin(uid, cfg)

def is_banned(uid, cfg) -> bool:
    return str(uid) in [str(x) for x in cfg.get("banned", [])]

# ─── CORE IMPORTS (lazy — avoids import errors if core not installed) ─────────
def get_ssh():
    try:
        import ssh
        return ssh
    except:
        return None

def get_xray():
    try:
        import xray
        return xray
    except:
        return None

def get_utils():
    try:
        import utils
        return utils
    except:
        return None

# ─── MENU KEYBOARD ────────────────────────────────────────────────────────────
def main_kb(uid, cfg):
    b = []
    if is_admin(uid, cfg):
        b += [
            [InlineKeyboardButton("👤 Add SSH", callback_data="add_ssh"),
             InlineKeyboardButton("🔐 Add XRAY", callback_data="add_xray")],
            [InlineKeyboardButton("❌ Delete User", callback_data="del_user"),
             InlineKeyboardButton("📋 List Users", callback_data="list_users")],
            [InlineKeyboardButton("📊 Server Status", callback_data="status"),
             InlineKeyboardButton("🔄 Renew User", callback_data="renew_user")],
            [InlineKeyboardButton("🔒 Lock", callback_data="lock_user"),
             InlineKeyboardButton("🔓 Unlock", callback_data="unlock_user")],
            [InlineKeyboardButton("⏰ Expiring Soon", callback_data="expiring_soon")],
        ]
        if is_owner(uid, cfg):
            b += [
                [InlineKeyboardButton("👑 Admins", callback_data="admin_panel"),
                 InlineKeyboardButton("🤝 Resellers", callback_data="reseller_panel")],
                [InlineKeyboardButton("🚫 Ban List", callback_data="ban_list")],
            ]
        elif is_reseller(uid, cfg):
            b += [[InlineKeyboardButton("🤝 My Account", callback_data="my_account")]]
    else:
        b = [
            [InlineKeyboardButton("ℹ️ Server Info", callback_data="server_info")],
            [InlineKeyboardButton("📞 Contact Admin", callback_data="contact_admin")],
        ]
    b.append([InlineKeyboardButton("🔄 Refresh", callback_data="refresh")])
    return InlineKeyboardMarkup(b)

async def send_menu(update: Update, context: ContextTypes.DEFAULT_TYPE, edit=False):
    cfg = load_bot_config()
    uid = update.effective_user.id
    name = update.effective_user.first_name
    u = get_utils()

    server_info = ""
    if u:
        try:
            info = u.get_system_info()
            server_info = f"🌐 {info['domain']}\n📊 Load: {info['load']} | Mem: {info['memory']}"
        except:
            server_info = "🌐 vpn.keitanyfrank.store"

    role = "👑 Owner" if is_owner(uid, cfg) else ("🔑 Admin" if is_admin(uid, cfg) else ("🤝 Reseller" if is_reseller(uid, cfg) else "👤 User"))

    txt = (
        f"🏪 *MZEE KOBE TUNNEL*\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"{server_info}\n\n"
        f"Hello *{name}*! ({role})\n"
        f"🕐 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )

    kb = main_kb(uid, cfg)
    if edit and update.callback_query:
        try:
            await update.callback_query.edit_message_text(txt, reply_markup=kb, parse_mode="Markdown")
        except:
            pass
    else:
        t = update.message or (update.callback_query.message if update.callback_query else None)
        if t:
            await t.reply_text(txt, reply_markup=kb, parse_mode="Markdown")

# ─── /start ───────────────────────────────────────────────────────────────────
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    uid = update.effective_user.id

    if is_banned(uid, cfg):
        await update.message.reply_text("🚫 You are banned from this bot.")
        return

    # First user becomes owner
    if cfg.get("owner_id") is None:
        cfg["owner_id"] = str(uid)
        save_bot_config(cfg)
        await update.message.reply_text(
            f"🎉 *Welcome to Mzee Kobe Tunnel Bot!*\n\n"
            f"You are now the *Owner*.\n"
            f"Your Telegram ID: `{uid}`\n\n"
            f"Use /help to see all commands.",
            parse_mode="Markdown"
        )

    await send_menu(update, context)

# ─── /help ────────────────────────────────────────────────────────────────────
async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "📖 *Commands*\n\n"
        "/start — Main menu\n"
        "/myid — Your Telegram ID\n"
        "/help — This message\n\n"
        "*Owner Only:*\n"
        "/addadmin `<id>` — Add admin\n"
        "/deladmin `<id>` — Remove admin\n"
        "/addreseller `<id> <credits> [name]` — Add reseller\n"
        "/delreseller `<id>` — Remove reseller\n"
        "/addcredits `<id> <amount>` — Top up credits\n"
        "/ban `<id>` — Ban user\n"
        "/unban `<id>` — Unban user\n"
        "/broadcast `<msg>` — Announce to all\n",
        parse_mode="Markdown"
    )

async def myid_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    uid = update.effective_user.id
    await update.message.reply_text(
        f"👤 *Your Info*\n"
        f"Name: {update.effective_user.full_name}\n"
        f"ID: `{uid}`",
        parse_mode="Markdown"
    )

# ─── CALLBACKS ────────────────────────────────────────────────────────────────
async def status_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    uid = update.effective_user.id
    if not is_admin(uid, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return

    await update.callback_query.answer("Fetching status...")
    u = get_utils()

    if u:
        try:
            info = u.get_system_info()
            lines = []
            for svc, state in info["services"].items():
                icon = "✅" if state == "active" else "❌"
                lines.append(f"{icon} {svc.upper()}: {state}")

            txt = (
                "📊 *SERVER STATUS*\n━━━━━━━━━━━━━━━━\n\n"
                + "\n".join(lines) +
                f"\n\n🌐 IP: `{info['ip']}`\n"
                f"🔗 Domain: `{info['domain']}`\n"
                f"⏱ Uptime: {info['uptime']}\n"
                f"⚡ Load: {info['load']}\n"
                f"💾 Memory: {info['memory']}\n"
                f"💿 Disk: {info['disk']}\n"
                f"👥 Online: {info['online_users']}\n"
                f"🕐 {datetime.now().strftime('%H:%M:%S')}"
            )
        except Exception as e:
            txt = f"❌ Error fetching status: {e}"
    else:
        txt = "❌ Core modules not available."

    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

async def list_users_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return

    await update.callback_query.answer("Loading...")
    u = get_utils()
    ssh_m = get_ssh()
    xray_m = get_xray()

    lines = []
    if ssh_m:
        ssh_users = ssh_m.list_ssh_users()
        for usr in ssh_users[:20]:
            icon = "🟢" if usr["status"] == "active" else "🔴"
            lines.append(f"{icon} `{usr['username']}` | SSH | {usr['days_left']}d")

    if xray_m:
        xray_users = xray_m.list_xray_users()
        for usr in xray_users[:20]:
            icon = "🟢" if usr["status"] == "active" else "🔴"
            lines.append(f"{icon} `{usr['username']}` | {usr['protocol']} | {usr['days_left']}d")

    total = len(lines)
    txt = f"📋 *Users* ({total} total)\n━━━━━━━━━━━━━━━━\n\n"
    txt += "\n".join(lines[:30]) if lines else "_No users found._"
    if total > 30:
        txt += f"\n\n_...and {total - 30} more_"

    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

async def expiring_soon_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return
    await update.callback_query.answer()

    u = get_utils()
    if not u:
        await update.callback_query.edit_message_text("❌ Core not available.",
            reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]]))
        return

    users = u.load_users()
    lines = []
    for uname, data in sorted(users.items()):
        d = u.days_remaining(data.get("expiry", ""))
        if 0 < d <= 3:
            lines.append(f"⚠️ `{uname}` ({data.get('type','?')}) — {d} day(s) left")

    txt = "⏰ *Expiring in 3 days*\n━━━━━━━━━━━━━━━━\n\n"
    txt += "\n".join(lines) if lines else "_No users expiring soon._"

    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

async def server_info_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.callback_query.answer()
    await update.callback_query.edit_message_text(
        "🌐 *Server Info*\n━━━━━━━━━━━━━━━━\n\n"
        "🏪 Mzee Kobe Tunnel\n"
        "🇺🇸 US Server\n"
        "🔗 `vpn.keitanyfrank.store`\n\n"
        "📡 *Supported Protocols:*\n"
        "• SSH — Port 22/222\n"
        "• SSH SSL — Port 443\n"
        "• VMess WS — Port 443/80\n"
        "• VLESS WS — Port 443/80\n"
        "• Trojan — Port 443/80\n"
        "• SOCKS — Port 443/80\n"
        "• OpenVPN — Port 1194\n"
        "• SQUID Proxy — Port 3128\n"
        "• OHP — Port 8000",
        parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]]))

async def admin_panel_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.callback_query.answer("Owner only!", show_alert=True)
        return
    admins = cfg.get("admins", [])
    txt = "👑 *Admin Panel*\n\n*Current Admins:*\n"
    txt += "\n".join([f"• `{a}`" for a in admins]) if admins else "_None_"
    txt += "\n\nUse /addadmin or /deladmin"
    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

async def reseller_panel_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.callback_query.answer("Owner only!", show_alert=True)
        return
    resellers = cfg.get("resellers", {})
    lines = [f"• `{k}` — {v.get('name','?')} | 💳 {v.get('credits',0)}" for k, v in resellers.items()]
    txt = "🤝 *Reseller Panel*\n\n"
    txt += "\n".join(lines) if lines else "_No resellers._"
    txt += "\n\n/addreseller ID credits name\n/delreseller ID\n/addcredits ID amount"
    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

async def ban_list_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.callback_query.answer("Owner only!", show_alert=True)
        return
    banned = cfg.get("banned", [])
    txt = "🚫 *Banned Users*\n\n"
    txt += "\n".join([f"• `{b}`" for b in banned]) if banned else "_None banned._"
    txt += "\n\n/ban ID | /unban ID"
    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

async def my_account_cb(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    uid = str(update.callback_query.from_user.id)
    rdata = cfg.get("resellers", {}).get(uid, {})
    if not rdata:
        await update.callback_query.answer("Not a reseller.", show_alert=True)
        return
    users_created = rdata.get("users_created", [])
    txt = (
        f"🤝 *Your Reseller Account*\n\n"
        f"👤 Name: {rdata.get('name','?')}\n"
        f"💳 Credits: {rdata.get('credits', 0)}\n"
        f"👥 Users Created: {len(users_created)}\n"
    )
    if users_created:
        txt += f"📋 Last 5: {', '.join(users_created[-5:])}"
    kb = InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])
    await update.callback_query.edit_message_text(txt, parse_mode="Markdown", reply_markup=kb)

# ─── CONVERSATION: ADD SSH ────────────────────────────────────────────────────
async def add_ssh_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return ConversationHandler.END
    context.user_data.update({"action": "add_ssh"})
    await update.callback_query.edit_message_text(
        "👤 *Add SSH User*\n\nEnter *username* (3-32 chars):",
        parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("❌ Cancel", callback_data="back")]]))
    return W_USERNAME

async def add_xray_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return ConversationHandler.END
    context.user_data.update({"action": "add_xray"})
    await update.callback_query.edit_message_text(
        "🔐 *Add XRAY User*\n\nEnter *username* (3-32 chars):",
        parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("❌ Cancel", callback_data="back")]]))
    return W_USERNAME

async def got_username(update: Update, context: ContextTypes.DEFAULT_TYPE):
    u = update.message.text.strip()
    if not re.match(r'^[a-zA-Z0-9_-]{3,32}$', u):
        await update.message.reply_text("❌ Invalid. Use 3-32 chars (a-z, 0-9, _, -).")
        return W_USERNAME
    context.user_data["username"] = u
    await update.message.reply_text(f"✅ Username: `{u}`\n\nEnter *days* (1-365):", parse_mode="Markdown")
    return W_DAYS

async def got_days(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        d = int(update.message.text.strip())
        if not 1 <= d <= 365: raise ValueError
    except:
        await update.message.reply_text("❌ Enter 1-365.")
        return W_DAYS

    context.user_data["days"] = d
    action = context.user_data.get("action")

    if action == "add_xray":
        await update.message.reply_text(
            "🔐 Select *protocol*:",
            parse_mode="Markdown",
            reply_markup=InlineKeyboardMarkup([
                [InlineKeyboardButton("VMess", callback_data="p_vmess"),
                 InlineKeyboardButton("VLESS", callback_data="p_vless")],
                [InlineKeyboardButton("Trojan", callback_data="p_trojan"),
                 InlineKeyboardButton("SOCKS", callback_data="p_socks")],
            ]))
        return W_PROTO

    if action == "renew":
        return await do_renew(update, context)

    await update.message.reply_text(f"✅ Days: `{d}`\n\nEnter *max logins* (1-10):", parse_mode="Markdown")
    return W_LIMIT

async def got_limit(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        lim = int(update.message.text.strip())
        if not 1 <= lim <= 100: raise ValueError
    except:
        await update.message.reply_text("❌ Enter 1-100.")
        return W_LIMIT

    username = context.user_data["username"]
    days = context.user_data["days"]
    uid = str(update.effective_user.id)
    msg = await update.message.reply_text("⏳ Creating SSH user...")

    ssh_m = get_ssh()
    if not ssh_m:
        await msg.edit_text("❌ Core SSH module not available.")
        context.user_data.clear()
        return ConversationHandler.END

    result = ssh_m.create_ssh_user(username, days, lim)

    if result["success"]:
        cfg = load_bot_config()
        if uid in cfg.get("resellers", {}):
            cfg["resellers"][uid].setdefault("users_created", []).append(username)
            if cfg["resellers"][uid].get("credits", 0) > 0:
                cfg["resellers"][uid]["credits"] -= 1
            save_bot_config(cfg)

        await msg.edit_text(
            f"✅ *SSH User Created!*\n\n"
            f"👤 User: `{result['username']}`\n"
            f"🔑 Pass: `{result['password']}`\n"
            f"📅 Expiry: {result['expiry']} ({result['days']}d)\n"
            f"🔢 Max Logins: {lim}\n\n"
            f"🌐 Host: `{result['host']}`\n"
            f"🔌 Ports: SSH=22 | DBear=222 | SSL=443",
            parse_mode="Markdown"
        )
    else:
        await msg.edit_text(f"❌ Failed: {result.get('error', 'Unknown')}")

    context.user_data.clear()
    return ConversationHandler.END

async def got_protocol(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.callback_query.answer()
    proto = update.callback_query.data.replace("p_", "")
    username = context.user_data["username"]
    days = context.user_data["days"]

    await update.callback_query.edit_message_text(f"⏳ Creating {proto.upper()} user...")

    xray_m = get_xray()
    if not xray_m:
        await update.callback_query.edit_message_text("❌ XRAY core not available.")
        context.user_data.clear()
        return ConversationHandler.END

    fn_map = {
        "vmess": xray_m.add_vmess_user,
        "vless": xray_m.add_vless_user,
        "trojan": xray_m.add_trojan_user,
        "socks": xray_m.add_socks_user,
    }
    result = fn_map[proto](username, days)

    if result["success"]:
        txt = (
            f"✅ *{proto.upper()} User Created!*\n\n"
            f"👤 User: `{result['username']}`\n"
        )
        if "uuid" in result:
            txt += f"🔑 UUID: `{result['uuid']}`\n"
        elif "password" in result:
            txt += f"🔑 Pass: `{result['password']}`\n"
        txt += (
            f"📅 Expiry: {result['expiry']} ({result['days']}d)\n"
            f"🌐 Host: `{result['host']}`\n"
            f"📂 Path: `{result['path']}`\n"
            f"🔌 TLS: 443 | NTLS: 80"
        )
        if "link" in result:
            txt += f"\n\n🔗 Link:\n`{result['link']}`"
        await update.callback_query.edit_message_text(txt, parse_mode="Markdown")
    else:
        await update.callback_query.edit_message_text(f"❌ Failed: {result.get('error','Unknown')}")

    context.user_data.clear()
    return ConversationHandler.END

# ─── CONVERSATION: DELETE / LOCK / UNLOCK / RENEW ────────────────────────────
async def del_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return ConversationHandler.END
    context.user_data["action"] = "del"
    await update.callback_query.edit_message_text("❌ *Delete User*\n\nEnter username:", parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("Cancel", callback_data="back")]]))
    return W_TARGET

async def lock_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return ConversationHandler.END
    context.user_data["action"] = "lock"
    await update.callback_query.edit_message_text("🔒 *Lock User*\n\nEnter username:", parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("Cancel", callback_data="back")]]))
    return W_TARGET

async def unlock_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return ConversationHandler.END
    context.user_data["action"] = "unlock"
    await update.callback_query.edit_message_text("🔓 *Unlock User*\n\nEnter username:", parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("Cancel", callback_data="back")]]))
    return W_TARGET

async def renew_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_admin(update.effective_user.id, cfg):
        await update.callback_query.answer("Admins only!", show_alert=True)
        return ConversationHandler.END
    context.user_data["action"] = "renew"
    await update.callback_query.edit_message_text("🔄 *Renew User*\n\nEnter username:", parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("Cancel", callback_data="back")]]))
    return W_TARGET

async def got_target(update: Update, context: ContextTypes.DEFAULT_TYPE):
    username = update.message.text.strip()
    action = context.user_data.get("action", "del")
    ssh_m = get_ssh()
    xray_m = get_xray()

    if action == "renew":
        context.user_data["username"] = username
        await update.message.reply_text(f"Enter *days* to renew `{username}`:", parse_mode="Markdown")
        return W_RDAYS

    elif action == "lock":
        result = ssh_m.lock_ssh_user(username) if ssh_m else {"success": False, "error": "No core"}
        await update.message.reply_text(
            f"✅ User `{username}` locked 🔒" if result["success"] else f"❌ {result.get('error','Failed')}",
            parse_mode="Markdown")

    elif action == "unlock":
        result = ssh_m.unlock_ssh_user(username) if ssh_m else {"success": False, "error": "No core"}
        await update.message.reply_text(
            f"✅ User `{username}` unlocked 🔓" if result["success"] else f"❌ {result.get('error','Failed')}",
            parse_mode="Markdown")

    elif action == "del":
        msg = await update.message.reply_text(f"⏳ Deleting `{username}`...", parse_mode="Markdown")
        deleted_from = []
        if ssh_m:
            r = ssh_m.delete_ssh_user(username)
            if r["success"]: deleted_from.append("SSH")
        if xray_m:
            r = xray_m.delete_xray_user(username)
            if r["success"]: deleted_from.append(r.get("protocol", "XRAY").upper())
        if deleted_from:
            await msg.edit_text(f"✅ `{username}` deleted from: {', '.join(deleted_from)}", parse_mode="Markdown")
        else:
            await msg.edit_text(f"⚠️ User `{username}` not found.", parse_mode="Markdown")

    context.user_data.clear()
    return ConversationHandler.END

async def got_renew_days(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        days = int(update.message.text.strip())
        if not 1 <= days <= 365: raise ValueError
    except:
        await update.message.reply_text("❌ Enter 1-365.")
        return W_RDAYS

    username = context.user_data.get("username")
    ssh_m = get_ssh()
    xray_m = get_xray()

    result = {"success": False, "error": "User not found"}
    if ssh_m:
        result = ssh_m.renew_ssh_user(username, days)
    if not result["success"] and xray_m:
        result = xray_m.renew_xray_user(username, days)

    await update.message.reply_text(
        f"✅ `{username}` renewed until {result.get('new_expiry', '?')}" if result["success"]
        else f"❌ {result.get('error', 'Failed')}",
        parse_mode="Markdown"
    )
    context.user_data.clear()
    return ConversationHandler.END

async def do_renew(update, context):
    """Called from got_days when action=renew (shouldn't normally reach here)."""
    context.user_data.clear()
    return ConversationHandler.END

# ─── OWNER COMMANDS ───────────────────────────────────────────────────────────
async def addadmin(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if not context.args:
        await update.message.reply_text("Usage: /addadmin <telegram_id>")
        return
    new_id = str(context.args[0])
    if new_id not in [str(x) for x in cfg["admins"]]:
        cfg["admins"].append(new_id)
        save_bot_config(cfg)
    await update.message.reply_text(f"✅ Admin `{new_id}` added.", parse_mode="Markdown")

async def deladmin(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if not context.args: return
    cfg["admins"] = [x for x in cfg["admins"] if str(x) != str(context.args[0])]
    save_bot_config(cfg)
    await update.message.reply_text("✅ Admin removed.")

async def addreseller(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if len(context.args) < 2:
        await update.message.reply_text("Usage: /addreseller <id> <credits> [name]")
        return
    rid, cred = str(context.args[0]), int(context.args[1])
    name = " ".join(context.args[2:]) or f"Reseller_{rid}"
    cfg.setdefault("resellers", {})[rid] = {"name": name, "credits": cred, "users_created": []}
    save_bot_config(cfg)
    await update.message.reply_text(f"✅ Reseller `{rid}` ({name}) added with {cred} credits.", parse_mode="Markdown")

async def delreseller(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if not context.args: return
    cfg.get("resellers", {}).pop(str(context.args[0]), None)
    save_bot_config(cfg)
    await update.message.reply_text("✅ Reseller removed.")

async def addcredits(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if len(context.args) < 2: return
    rid, amt = str(context.args[0]), int(context.args[1])
    if rid in cfg.get("resellers", {}):
        cfg["resellers"][rid]["credits"] = cfg["resellers"][rid].get("credits", 0) + amt
        save_bot_config(cfg)
        await update.message.reply_text(f"✅ +{amt} credits. Total: {cfg['resellers'][rid]['credits']}")
    else:
        await update.message.reply_text("❌ Reseller not found.")

async def ban(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if not context.args: return
    bid = str(context.args[0])
    if bid not in [str(x) for x in cfg["banned"]]:
        cfg["banned"].append(bid)
        save_bot_config(cfg)
    await update.message.reply_text(f"🚫 User `{bid}` banned.", parse_mode="Markdown")

async def unban(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if not context.args: return
    cfg["banned"] = [x for x in cfg["banned"] if str(x) != str(context.args[0])]
    save_bot_config(cfg)
    await update.message.reply_text("✅ User unbanned.")

async def broadcast(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cfg = load_bot_config()
    if not is_owner(update.effective_user.id, cfg):
        await update.message.reply_text("❌ Owner only.")
        return
    if not context.args: return
    txt = " ".join(context.args)
    all_ids = list(cfg.get("admins", [])) + list(cfg.get("resellers", {}).keys())
    sent = 0
    for uid in set(all_ids):
        try:
            await context.bot.send_message(int(uid), f"📢 *Broadcast*\n\n{txt}", parse_mode="Markdown")
            sent += 1
        except:
            pass
    await update.message.reply_text(f"✅ Sent to {sent} users.")

# ─── CALLBACK ROUTER ──────────────────────────────────────────────────────────
async def cb_router(update: Update, context: ContextTypes.DEFAULT_TYPE):
    d = update.callback_query.data
    await update.callback_query.answer()

    routes = {
        "back": lambda: send_menu(update, context, edit=True),
        "refresh": lambda: send_menu(update, context, edit=True),
        "status": lambda: status_cb(update, context),
        "list_users": lambda: list_users_cb(update, context),
        "expiring_soon": lambda: expiring_soon_cb(update, context),
        "server_info": lambda: server_info_cb(update, context),
        "admin_panel": lambda: admin_panel_cb(update, context),
        "reseller_panel": lambda: reseller_panel_cb(update, context),
        "ban_list": lambda: ban_list_cb(update, context),
        "my_account": lambda: my_account_cb(update, context),
        "contact_admin": lambda: update.callback_query.edit_message_text(
            "📞 Contact the admin to purchase an account.",
            reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Back", callback_data="back")]])),
    }

    if d in routes:
        await routes[d]()

async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data.clear()
    await update.message.reply_text("❌ Cancelled.")
    return ConversationHandler.END

# ─── MAIN ─────────────────────────────────────────────────────────────────────
def main():
    token = get_token()
    if not token:
        logger.error("No bot token found! Set it in /root/.mzeekobe_bot_token")
        sys.exit(1)

    app = Application.builder().token(token).build()

    conv = ConversationHandler(
        entry_points=[
            CallbackQueryHandler(add_ssh_start, pattern="^add_ssh$"),
            CallbackQueryHandler(add_xray_start, pattern="^add_xray$"),
            CallbackQueryHandler(del_start, pattern="^del_user$"),
            CallbackQueryHandler(lock_start, pattern="^lock_user$"),
            CallbackQueryHandler(unlock_start, pattern="^unlock_user$"),
            CallbackQueryHandler(renew_start, pattern="^renew_user$"),
        ],
        states={
            W_USERNAME: [MessageHandler(filters.TEXT & ~filters.COMMAND, got_username)],
            W_DAYS: [MessageHandler(filters.TEXT & ~filters.COMMAND, got_days)],
            W_LIMIT: [MessageHandler(filters.TEXT & ~filters.COMMAND, got_limit)],
            W_PROTO: [CallbackQueryHandler(got_protocol, pattern="^p_")],
            W_TARGET: [MessageHandler(filters.TEXT & ~filters.COMMAND, got_target)],
            W_RDAYS: [MessageHandler(filters.TEXT & ~filters.COMMAND, got_renew_days)],
        },
        fallbacks=[
            CommandHandler("cancel", cancel),
            CallbackQueryHandler(lambda u, c: send_menu(u, c, edit=True), pattern="^back$"),
        ],
        per_user=True,
        per_chat=True,
        allow_reentry=True,
    )

    app.add_handler(conv)
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("myid", myid_cmd))
    app.add_handler(CommandHandler("addadmin", addadmin))
    app.add_handler(CommandHandler("deladmin", deladmin))
    app.add_handler(CommandHandler("addreseller", addreseller))
    app.add_handler(CommandHandler("delreseller", delreseller))
    app.add_handler(CommandHandler("addcredits", addcredits))
    app.add_handler(CommandHandler("ban", ban))
    app.add_handler(CommandHandler("unban", unban))
    app.add_handler(CommandHandler("broadcast", broadcast))
    app.add_handler(CallbackQueryHandler(cb_router))

    logger.info("🤖 Mzee Kobe Bot started!")
    app.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
