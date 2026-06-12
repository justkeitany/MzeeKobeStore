# MZEE KOBE STORE

**A complete VPN panel for Ubuntu/Debian servers.**

Supports SSH, VMess, VLESS, Trojan, SOCKS, OpenVPN — all over WebSocket with TLS, managed via a colorful shell menu and an optional Telegram bot.

---

## Features

- **SSH over WebSocket** (TLS port 443, Non-TLS port 80)
- **VMess WS** (TLS/NTLS + Custom ports 2083/2082)
- **VLESS WS** (TLS/NTLS + Custom ports 2087/2086)
- **Trojan WS** (TLS/NTLS)
- **SOCKS WS** (TLS/NTLS)
- **OpenVPN** TCP (1194) and UDP (2200)
- **Xray-core** with all modern transports: WS, HttpUpgrade, gRPC, xHTTP
- **SSH Dropbear** on port 222
- **Squid Proxy** on 3128 / 8080
- **BadVPN UDPGW** on port 7300
- **UDP Custom** on port 36712
- **OHP TCP** on port 8000
- **Let's Encrypt SSL** (auto-renewed monthly)
- **Telegram Bot** for remote user management
- **Network Guard** — blocks ads, torrents, adult content via `/etc/hosts`
- **TCP BBR** congestion control optimization
- **Validator** — cron-based multi-login enforcer
- **Auto-expiry** of users at midnight daily

---

## Installation

**Tested on:** Ubuntu 20.04, 22.04, 24.04 LTS / Debian 11, 12

```bash
apt update -y && apt upgrade -y
apt install -y git curl wget
git clone https://github.com/YOUR_GITHUB/mzeekobe.git /tmp/mzeekobe
chmod +x /tmp/mzeekobe/install.sh
bash /tmp/mzeekobe/install.sh
```

Or one-line:

```bash
wget -O install.sh https://raw.githubusercontent.com/YOUR_GITHUB/mzeekobe/main/install.sh && chmod +x install.sh && bash install.sh
```

---

## Port Reference

| Protocol          | TLS Port | Non-TLS Port |
|-------------------|----------|--------------|
| SSH WS            | 443      | 80           |
| SSH Dropbear      | —        | 222          |
| VMess WS          | 443      | 80           |
| VMess Custom      | 2083     | 2082         |
| VLESS WS          | 443      | 80           |
| VLESS Custom      | 2087     | 2086         |
| Trojan WS         | 443      | 80           |
| SOCKS WS          | 443      | 80           |
| OpenVPN TCP       | —        | 1194         |
| OpenVPN UDP       | —        | 2200         |
| Squid Proxy       | —        | 3128 / 8080  |
| OHP TCP           | —        | 8000         |
| UDP Custom        | —        | 36712        |
| BadVPN UDPGW      | —        | 7300         |

### Xray Inbound Ports (internal)

| Port | Protocol | Transport    | Path         |
|------|----------|--------------|--------------|
| 1001 | Trojan   | WS           | /trojan      |
| 1002 | Trojan   | HttpUpgrade  | /htrojan     |
| 1003 | Trojan   | gRPC         | trojan-grpc  |
| 1004 | Trojan   | xHTTP        | /xtrojan     |
| 2001 | VMess    | WS           | /vmess       |
| 2002 | VMess    | HttpUpgrade  | /hvmess      |
| 2003 | VMess    | gRPC         | vmess-grpc   |
| 2004 | VMess    | xHTTP        | /xvmess      |
| 3001 | VLESS    | WS           | /vless       |
| 3002 | VLESS    | HttpUpgrade  | /hvless      |
| 3003 | VLESS    | gRPC         | vless-grpc   |
| 3004 | VLESS    | xHTTP        | /xvless      |

---

## Usage

After installation, type `menu` as root:

```bash
menu
```

### Main Menu Options

```
[1]  SSH User Management
[2]  VMess Management
[3]  VLESS Management
[4]  Trojan Management
[5]  SOCKS Management
[6]  Server Status
[7]  Expiry Management
[8]  Domain Settings
[9]  DNS Settings
[10] Port Information
[11] View Logs
[12] IP Tools
[13] Network Guard
[14] ZiVPN / Hysteria2
[15] Update Panel
[0]  Exit
```

---

## File Structure

```
/usr/local/mzeekobe/        ← install directory
├── version                 ← panel version
├── port_info               ← port reference
├── users.json              ← user database
├── mzeekobe.sh             ← main entry point
├── core/
│   ├── ssh.py              ← SSH user management
│   ├── xray.py             ← Xray user management
│   ├── menu.py             ← Python menu helper
│   ├── status.py           ← server status
│   ├── expiry.py           ← expiry management
│   ├── utils.py            ← shared utilities
│   ├── bbr.sh              ← TCP BBR optimizer
│   ├── blocker.sh          ← network guard
│   ├── setup_dns.sh        ← DNS configurator
│   ├── setup_udp.sh        ← UDP/BadVPN setup
│   ├── sshws.sh            ← SSH WS service setup
│   ├── validator.sh        ← login limit enforcer
│   ├── vpn.sh              ← OpenVPN setup
│   ├── websocket.sh        ← WS proxies setup
│   ├── xray.sh             ← Xray installer
│   └── ssl_renew.sh        ← SSL auto-renew
├── menu/
│   ├── menu.sh             ← main interactive menu
│   ├── ssh.sh              ← SSH management menu
│   ├── vmess.sh            ← VMess menu
│   ├── vless.sh            ← VLESS menu
│   ├── trojan.sh           ← Trojan menu
│   ├── socks.sh            ← SOCKS menu
│   ├── status.sh           ← server status
│   ├── expiry.sh           ← expiry menu
│   ├── domain.sh           ← domain settings
│   ├── dns.sh              ← DNS settings
│   ├── port.sh             ← port info
│   ├── log.sh              ← log viewer
│   ├── iptools.sh          ← IP tools
│   ├── netguard.sh         ← network guard menu
│   ├── update.sh           ← panel updater
│   └── zivpn.sh            ← Hysteria2 menu
├── module/
│   ├── ws.py               ← SSH WebSocket proxy
│   ├── dropbear-ws.py      ← Dropbear WS proxy
│   ├── openvpn-wss.py      ← OpenVPN WS proxy
│   ├── proxy3.js           ← Node.js proxy bridge
│   ├── nginx.conf          ← Nginx main config
│   ├── mzeekobe.conf       ← Nginx vhost template
│   ├── config.json         ← Xray config template
│   ├── udp_config.json     ← UDP Custom config
│   ├── badvpn.service      ← BadVPN systemd service
│   ├── proxy.service       ← WS proxy service
│   ├── ws-stunnel.service  ← WS stunnel service
│   ├── xray.service        ← Xray systemd service
│   ├── issue.net           ← SSH banner
│   └── hosts               ← blocker hosts file
└── bot/
    └── bot.py              ← Telegram bot
```

---

## Telegram Bot

During installation, provide your bot token. Then use the bot to:

- Add / delete / renew SSH and XRAY users
- Check server status
- View active connections
- Manage expiry

---

## Terms of Service

By using this panel you agree:

- **NO SPAM**
- **NO DDOS**
- **NO TORRENT**
- **NO MULTI LOGIN**
- **NO PORN**
- **NO HACKING / CARDING**

---

## License

MZEE KOBE STORE VPN Panel  
Based on DOTYCAT tunnel panel architecture  
For private / commercial use by the panel owner.
