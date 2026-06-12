#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Complete VPN Panel Installer
#   Based on DOTYCAT tunnel panel architecture
#   Install dir: /usr/local/mzeekobe/
#   Panel command: menu
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'

REPO="https://raw.githubusercontent.com/justkeitany/MzeeKobeStore/main"
REPO_GIT="https://github.com/justkeitany/MzeeKobeStore"
INSTALL_DIR="/usr/local/mzeekobe"
SBIN="/usr/local/sbin"
VERSION="1.0.0"

# ── OS detection & compatibility vars ────────────────────────
# Set defaults; detect_os() will override them
CERTBOT_PKG="python3-certbot-nginx"
OS_NAME=""
OS_VER=""
OS_MAJOR=""

# ─── BANNER ──────────────────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║         ★  MZEE KOBE STORE  ★                  ║"
    echo "  ║          VPN Panel Installer v${VERSION}              ║"
    echo "  ║                                                  ║"
    echo "  ║    SSH • VMess • VLESS • Trojan • SOCKS         ║"
    echo "  ║    OpenVPN • Xray-core • BadVPN • Stunnel5      ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ─── HELPERS ─────────────────────────────────────────────────────────────────
log_ok()   { echo -e "  ${GREEN}[OK]${NC} $*"; }
log_info() { echo -e "  ${YELLOW}[*]${NC} $*"; }
log_err()  { echo -e "  ${RED}[!]${NC} $*"; }
log_skip() { echo -e "  ${CYAN}[-]${NC} $*"; }

# ─── CHECKS ──────────────────────────────────────────────────────────────────
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_err "Please run as root."
        exit 1
    fi
}

# ── OS detection with Ubuntu 18-26 and Debian 10-12 support ──
detect_os() {
    if [ ! -f /etc/os-release ]; then
        log_err "Cannot detect OS (/etc/os-release not found)."
        exit 1
    fi
    . /etc/os-release
    OS_NAME=$ID
    OS_VER=$VERSION_ID
    OS_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)

    if [[ "$OS_NAME" == "ubuntu" ]]; then
        if [[ "$OS_MAJOR" -lt 18 ]]; then
            log_err "Ubuntu < 18.04 is not supported. Please use Ubuntu 18.04 or later."
            exit 1
        fi
        # Ubuntu 18.04 ships python-certbot-nginx (no python3- prefix)
        if [[ "$OS_MAJOR" == "18" ]]; then
            CERTBOT_PKG="python-certbot-nginx"
        else
            CERTBOT_PKG="python3-certbot-nginx"
        fi
    elif [[ "$OS_NAME" == "debian" ]]; then
        if [[ "$OS_MAJOR" -lt 10 ]]; then
            log_err "Debian < 10 is not supported. Please use Debian 10+ (Buster)."
            exit 1
        fi
        CERTBOT_PKG="python3-certbot-nginx"
    else
        log_err "Unsupported OS: $OS_NAME $OS_VER. Only Ubuntu 18+ and Debian 10+ supported."
        exit 1
    fi

    log_ok "OS: $OS_NAME $OS_VER (major: $OS_MAJOR) | certbot pkg: $CERTBOT_PKG"
}

check_os() {
    detect_os
}

# ─── NODE.JS INSTALL ─────────────────────────────────────────────────────────
install_nodejs() {
    log_info "Installing Node.js (LTS 18.x from NodeSource)..."
    if command -v node >/dev/null 2>&1; then
        log_skip "Node.js already installed: $(node --version)"
        return
    fi
    # NodeSource setup script works for Ubuntu 18/20/22/24/26 and Debian 10/11/12
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - >/dev/null 2>&1
    apt-get install -y -qq nodejs 2>/dev/null
    if command -v node >/dev/null 2>&1; then
        log_ok "Node.js installed: $(node --version)"
    else
        log_err "Node.js install failed. Check internet connection."
    fi
}

# ─── DEPENDENCIES ────────────────────────────────────────────────────────────
install_deps() {
    log_info "Updating package list..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq 2>/dev/null

    log_info "Installing base dependencies..."
    apt-get install -y -qq \
        curl wget git unzip zip \
        net-tools dnsutils \
        jq \
        cron \
        openssl ca-certificates gnupg lsb-release \
        apt-transport-https \
        python3 python3-pip python3-venv \
        2>/dev/null

    # uuid-runtime may not be in minimal Ubuntu 18 repos; install separately
    apt-get install -y -qq uuid-runtime 2>/dev/null || true

    log_info "Installing networking tools..."
    apt-get install -y -qq \
        nginx \
        certbot "$CERTBOT_PKG" \
        dropbear \
        squid \
        openvpn easy-rsa \
        fail2ban \
        2>/dev/null

    # Node.js from NodeSource (works on Ubuntu 18-26 and Debian 10-12)
    install_nodejs

    # Python packages
    log_info "Installing Python packages..."
    pip3 install -q python-telegram-bot==20.7 aiohttp requests 2>/dev/null

    log_ok "All dependencies installed."
}

# ─── USER INPUT ──────────────────────────────────────────────────────────────
get_domain() {
    echo ""
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    echo -ne "  ${YELLOW}Enter your domain (e.g. vpn.example.com): ${NC}"
    read -r DOMAIN

    if [ -z "$DOMAIN" ]; then
        log_err "Domain cannot be empty."
        get_domain
        return
    fi

    SERVER_IP=$(curl -s ifconfig.me --max-time 5)
    DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

    if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
        log_err "Domain $DOMAIN resolves to $DOMAIN_IP but server IP is $SERVER_IP"
        echo -e "  ${YELLOW}Fix DNS before running. Continuing anyway...${NC}"
    else
        log_ok "Domain verified: $DOMAIN -> $SERVER_IP"
    fi

    echo "$DOMAIN" > /root/.mzeekobe_domain
}

get_bot_token() {
    echo ""
    echo -ne "  ${YELLOW}Telegram Bot Token (leave blank to skip): ${NC}"
    read -r BOT_TOKEN
    if [ -n "$BOT_TOKEN" ]; then
        echo "$BOT_TOKEN" > /root/.mzeekobe_bot_token
        log_ok "Bot token saved."
    else
        log_skip "Skipping bot setup."
    fi
}

# ─── SSL ─────────────────────────────────────────────────────────────────────
setup_ssl() {
    DOMAIN=$(cat /root/.mzeekobe_domain)
    log_info "Obtaining SSL certificate for $DOMAIN..."

    # Stop nginx first to free port 80
    systemctl stop nginx 2>/dev/null

    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --preferred-challenges http \
        2>/dev/null

    if [ $? -eq 0 ]; then
        log_ok "SSL certificate obtained from Let's Encrypt."
        CERT_PATH="/etc/letsencrypt/live/$DOMAIN"
    else
        log_err "Certbot failed. Generating self-signed certificate..."
        CERT_PATH="/etc/letsencrypt/live/$DOMAIN"
        mkdir -p "$CERT_PATH"
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout "$CERT_PATH/privkey.pem" \
            -out "$CERT_PATH/fullchain.pem" \
            -subj "/CN=$DOMAIN/O=MzeeKobe/C=US" 2>/dev/null
        log_ok "Self-signed certificate generated."
    fi

    # Copy to /etc/xray/
    mkdir -p /etc/xray
    cp "$CERT_PATH/fullchain.pem" /etc/xray/xray.crt
    cp "$CERT_PATH/privkey.pem" /etc/xray/xray.key
    chmod 644 /etc/xray/xray.crt
    chmod 600 /etc/xray/xray.key
    log_ok "SSL cert installed at /etc/xray/"
}

# ─── XRAY ────────────────────────────────────────────────────────────────────
install_xray() {
    log_info "Installing Xray-core..."

    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>/dev/null

    if ! command -v xray >/dev/null 2>&1 && [ ! -f /usr/local/bin/xray ]; then
        # Manual fallback
        ARCH=$(uname -m)
        [ "$ARCH" = "x86_64" ] && XARCH="64" || XARCH="arm64-v8a"
        XVER=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        XVER="${XVER:-v25.1.1}"
        wget -q "https://github.com/XTLS/Xray-core/releases/download/$XVER/Xray-linux-$XARCH.zip" -O /tmp/xray.zip
        unzip -o /tmp/xray.zip xray -d /tmp/xray_dir/ 2>/dev/null
        install -m 755 /tmp/xray_dir/xray /usr/local/bin/xray
        rm -rf /tmp/xray.zip /tmp/xray_dir
    fi

    log_ok "Xray-core installed: $(/usr/local/bin/xray version 2>/dev/null | head -1)"
}

setup_xray_config() {
    log_info "Setting up Xray configuration..."
    mkdir -p /etc/xray /var/log/xray

    # Install config from module
    cp "$INSTALL_DIR/module/config.json" /etc/xray/config.json

    # Create www-data user access to logs
    chown -R www-data:www-data /var/log/xray 2>/dev/null

    # Install systemd service
    cp "$INSTALL_DIR/module/xray.service" /etc/systemd/system/xray.service

    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray

    sleep 2
    if systemctl is-active --quiet xray; then
        log_ok "Xray service running."
    else
        log_err "Xray failed to start. Check: journalctl -u xray -n 20"
    fi
}

# ─── NGINX ───────────────────────────────────────────────────────────────────
setup_nginx() {
    DOMAIN=$(cat /root/.mzeekobe_domain)
    log_info "Configuring Nginx..."

    # Install custom nginx.conf (main config)
    cp "$INSTALL_DIR/module/nginx.conf" /etc/nginx/nginx.conf

    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    rm -f /etc/nginx/conf.d/default.conf

    # Install vhost config with domain substituted
    sed "s/xxxxxx/$DOMAIN/g" "$INSTALL_DIR/module/mzeekobe.conf" \
        > /etc/nginx/conf.d/mzeekobe.conf

    # Create web root
    mkdir -p /home/vps/public_html
    cat > /home/vps/public_html/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>Mzee Kobe Store</title></head>
<body style="background:#000;color:#0f0;font-family:monospace;text-align:center;padding:50px">
<h1>MZEE KOBE STORE</h1>
<p>VPN Server Running</p>
</body></html>
EOF

    nginx -t 2>/dev/null && systemctl enable nginx && systemctl start nginx
    if systemctl is-active --quiet nginx; then
        log_ok "Nginx running."
    else
        log_err "Nginx failed. Check: nginx -t"
    fi
}

# ─── WEBSOCKET PROXIES ────────────────────────────────────────────────────────
setup_websocket_proxies() {
    log_info "Setting up WebSocket proxy services..."

    # ws.py - SSH WS proxy (port 700)
    cat > /etc/systemd/system/mzeekobe-ws.service << EOF
[Unit]
Description=Mzee Kobe WS Proxy (port 700)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $INSTALL_DIR/module/ws.py -b 127.0.0.1 -p 700
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # dropbear-ws.py - Dropbear WS proxy (port 8880)
    cat > /etc/systemd/system/mzeekobe-dropbear-ws.service << EOF
[Unit]
Description=Mzee Kobe Dropbear WS Proxy (port 8880)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $INSTALL_DIR/module/dropbear-ws.py -b 0.0.0.0 -p 8880
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # openvpn-wss.py (port 900)
    cat > /etc/systemd/system/mzeekobe-ovpn-ws.service << EOF
[Unit]
Description=Mzee Kobe OpenVPN WSS Proxy (port 900)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $INSTALL_DIR/module/openvpn-wss.py -b 0.0.0.0 -p 900
Restart=always
RestartSec=5
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    for svc in mzeekobe-ws mzeekobe-dropbear-ws mzeekobe-ovpn-ws; do
        systemctl enable "$svc" 2>/dev/null
        systemctl start "$svc" 2>/dev/null
        if systemctl is-active --quiet "$svc"; then
            log_ok "$svc started."
        else
            log_err "$svc failed to start."
        fi
    done
}

# ─── STUNNEL5 ────────────────────────────────────────────────────────────────
install_stunnel() {
    log_info "Installing Stunnel5..."

    if command -v stunnel5 >/dev/null 2>&1 || command -v stunnel >/dev/null 2>&1; then
        log_skip "Stunnel already installed."
        return
    fi

    # Check if binary exists in module
    if [ -f "$INSTALL_DIR/core/stunnel-5.77.tar.gz" ]; then
        log_info "Building Stunnel5 from source..."
        apt-get install -y -qq build-essential libssl-dev 2>/dev/null
        tar -xzf "$INSTALL_DIR/core/stunnel-5.77.tar.gz" -C /tmp/ 2>/dev/null
        cd /tmp/stunnel-5.77 && ./configure --prefix=/usr >/dev/null 2>&1 && \
            make >/dev/null 2>&1 && make install >/dev/null 2>&1
        cd /
        rm -rf /tmp/stunnel-5.77
        log_ok "Stunnel5 built and installed."
    else
        apt-get install -y -qq stunnel4 2>/dev/null
        log_ok "Stunnel4 installed (stunnel5 not found)."
    fi

    DOMAIN=$(cat /root/.mzeekobe_domain)
    mkdir -p /etc/stunnel

    cat > /etc/stunnel/stunnel.conf << EOF
; Mzee Kobe Store - Stunnel Config
pid = /var/run/stunnel4/stunnel4.pid
setuid = nobody
setgid = nogroup

[https]
accept = 443
connect = 127.0.0.1:80
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
EOF
}

# ─── DROPBEAR ────────────────────────────────────────────────────────────────
setup_dropbear() {
    log_info "Configuring Dropbear SSH (port 22)..."

    if [ -f /etc/default/dropbear ]; then
        sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear 2>/dev/null
        sed -i '/DROPBEAR_PORT/d' /etc/default/dropbear
        sed -i '/DROPBEAR_EXTRA_ARGS/d' /etc/default/dropbear
        sed -i '/DROPBEAR_BANNER/d' /etc/default/dropbear
        echo 'DROPBEAR_PORT=22' >> /etc/default/dropbear
        echo 'DROPBEAR_EXTRA_ARGS="-p 22"' >> /etc/default/dropbear
        echo 'DROPBEAR_BANNER="/etc/issue.net"' >> /etc/default/dropbear
    else
        # Create config for newer systems
        cat > /etc/default/dropbear << 'EOF'
NO_START=0
DROPBEAR_PORT=22
DROPBEAR_EXTRA_ARGS="-p 22"
DROPBEAR_BANNER="/etc/issue.net"
EOF
    fi

    systemctl enable dropbear 2>/dev/null
    systemctl restart dropbear 2>/dev/null

    if systemctl is-active --quiet dropbear; then
        log_ok "Dropbear running on port 222."
    else
        log_err "Dropbear failed. Check: systemctl status dropbear"
    fi
}

# ─── SQUID ───────────────────────────────────────────────────────────────────
setup_squid() {
    log_info "Configuring Squid proxy..."

    cat > /etc/squid/squid.conf << 'EOF'
# Mzee Kobe Store - Squid Proxy
http_port 3128
http_port 8080

acl all src 0.0.0.0/0
acl localhost src 127.0.0.1/32

http_access allow all
visible_hostname MzeeKobeProxy

# Disable caching to act as transparent proxy
cache deny all
access_log /var/log/squid/access.log squid
cache_log /dev/null

# Connection timeouts
connect_timeout 60 seconds
request_timeout 60 seconds
EOF

    systemctl enable squid 2>/dev/null
    systemctl restart squid 2>/dev/null

    if systemctl is-active --quiet squid; then
        log_ok "Squid running on ports 3128 and 8080."
    else
        log_err "Squid failed."
    fi
}

# ─── OHP ─────────────────────────────────────────────────────────────────────
install_ohp() {
    log_info "Installing OHP (Open HTTP Puncher)..."

    OHP_BIN="$INSTALL_DIR/module/ohp"
    if [ -f "$OHP_BIN" ]; then
        cp "$OHP_BIN" /usr/bin/ohp
        chmod +x /usr/bin/ohp

        cat > /etc/systemd/system/ohp.service << 'EOF'
[Unit]
Description=OHP TCP - Mzee Kobe Store
After=network.target

[Service]
User=root
ExecStart=/usr/bin/ohp --port 8000 --proto tcp
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable ohp 2>/dev/null
        systemctl start ohp 2>/dev/null
        log_ok "OHP installed on port 8000."
    else
        log_skip "OHP binary not found in module. Skipping."
    fi
}

# ─── BADVPN ──────────────────────────────────────────────────────────────────
install_badvpn() {
    log_info "Installing BadVPN UDPGW..."

    BADVPN_SRC="$INSTALL_DIR/module/badvpn-udpgw"
    if [ -f "$BADVPN_SRC" ]; then
        cp "$BADVPN_SRC" /usr/bin/badvpn
        chmod +x /usr/bin/badvpn
    else
        BADVPN_NEW="$INSTALL_DIR/module/newudpgw"
        if [ -f "$BADVPN_NEW" ]; then
            cp "$BADVPN_NEW" /usr/bin/badvpn
            chmod +x /usr/bin/badvpn
        else
            log_skip "BadVPN binary not found. Skipping."
            return
        fi
    fi

    cp "$INSTALL_DIR/module/badvpn.service" /etc/systemd/system/badvpn.service

    systemctl daemon-reload
    systemctl enable badvpn
    systemctl start badvpn

    if systemctl is-active --quiet badvpn; then
        log_ok "BadVPN UDPGW running on port 7300."
    else
        log_err "BadVPN failed to start."
    fi
}

# ─── TCP BBR ─────────────────────────────────────────────────────────────────
setup_bbr() {
    log_info "Enabling TCP BBR..."
    bash "$INSTALL_DIR/core/bbr.sh" enable 2>/dev/null
    log_ok "BBR optimization applied."
}

# ─── SSH BANNER ───────────────────────────────────────────────────────────────
setup_banner() {
    log_info "Setting up SSH banner..."

    cp "$INSTALL_DIR/module/issue.net" /etc/issue.net

    # Configure sshd to show banner
    if grep -q "^Banner" /etc/ssh/sshd_config; then
        sed -i "s|^Banner.*|Banner /etc/issue.net|" /etc/ssh/sshd_config
    else
        echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    fi

    # Disable MOTD (cleaner)
    sed -i 's/^PrintMotd yes/PrintMotd no/' /etc/ssh/sshd_config 2>/dev/null

    systemctl restart ssh 2>/dev/null
    log_ok "SSH banner configured."
}

# ─── PANEL INSTALL ────────────────────────────────────────────────────────────
install_panel() {
    log_info "Cloning Mzee Kobe Store panel from GitHub..."

    # Remove any old install
    rm -rf "$INSTALL_DIR"

    # Clone the repo
    git clone --depth=1 https://github.com/justkeitany/MzeeKobeStore.git "$INSTALL_DIR" 2>/dev/null

    if [ ! -d "$INSTALL_DIR/menu" ]; then
        log_err "Git clone failed. Trying wget fallback..."

        mkdir -p "$INSTALL_DIR/core" "$INSTALL_DIR/menu" "$INSTALL_DIR/module" "$INSTALL_DIR/bot"

        # Download each file individually
        BASE="https://raw.githubusercontent.com/justkeitany/MzeeKobeStore/main"

        for f in version port_info mzeekobe.sh; do
            wget -q "$BASE/$f" -O "$INSTALL_DIR/$f"
        done
        for f in ssh.py xray.py expiry.py status.py utils.py bbr.sh blocker.sh setup_dns.sh \
                  setup_udp.sh sshws.sh ssl_renew.sh validator.sh vpn.sh websocket.sh xray.sh; do
            wget -q "$BASE/core/$f" -O "$INSTALL_DIR/core/$f"
        done
        for f in menu.sh ssh.sh vmess.sh vless.sh trojan.sh socks.sh status.sh expiry.sh \
                  domain.sh dns.sh port.sh log.sh iptools.sh netguard.sh update.sh zivpn.sh; do
            wget -q "$BASE/menu/$f" -O "$INSTALL_DIR/menu/$f"
        done
        for f in ws.py dropbear-ws.py openvpn-wss.py proxy3.js nginx.conf mzeekobe.conf \
                  config.json udp_config.json xray.service proxy.service badvpn.service \
                  ws-stunnel.service issue.net hosts; do
            wget -q "$BASE/module/$f" -O "$INSTALL_DIR/module/$f"
        done
        wget -q "$BASE/bot/bot.py" -O "$INSTALL_DIR/bot/bot.py"

        log_ok "Files downloaded via wget fallback."
    else
        log_ok "Repository cloned successfully."
    fi

    # Make all scripts executable
    chmod +x "$INSTALL_DIR/core/"*.sh 2>/dev/null
    chmod +x "$INSTALL_DIR/menu/"*.sh 2>/dev/null
    chmod +x "$INSTALL_DIR/mzeekobe.sh" 2>/dev/null

    # Install the 'menu' command in PATH
    cat > "$SBIN/menu" << EOF
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ "\$EUID" -ne 0 ]; then echo "Run as root: sudo menu"; exit 1; fi
exec bash $INSTALL_DIR/menu/menu.sh
EOF
    chmod +x "$SBIN/menu"
    log_ok "Command 'menu' installed to $SBIN/menu"

    # Create users.json if it doesn't exist
    [ -f "$INSTALL_DIR/users.json" ] || echo '{}' > "$INSTALL_DIR/users.json"

    log_ok "Panel installed at $INSTALL_DIR"
}

# ─── BOT ─────────────────────────────────────────────────────────────────────
install_bot() {
    if [ ! -f /root/.mzeekobe_bot_token ]; then
        log_skip "No bot token. Skipping Telegram bot."
        return
    fi

    BOT_TOKEN=$(cat /root/.mzeekobe_bot_token)
    log_info "Setting up Telegram bot..."

    cat > /etc/systemd/system/mzeekobe-bot.service << EOF
[Unit]
Description=Mzee Kobe Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment=BOT_TOKEN=$BOT_TOKEN
Environment=INSTALL_DIR=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/bot/bot.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/mzeekobe_bot.log
StandardError=append:/var/log/mzeekobe_bot.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mzeekobe-bot
    systemctl start mzeekobe-bot

    sleep 2
    if systemctl is-active --quiet mzeekobe-bot; then
        log_ok "Telegram bot started."
    else
        log_err "Bot failed to start. Check: journalctl -u mzeekobe-bot"
    fi
}

# ─── CRON JOBS ────────────────────────────────────────────────────────────────
setup_cron() {
    log_info "Setting up cron jobs..."

    # Remove old cron entries
    crontab -l 2>/dev/null | grep -v "mzeekobe\|expiry\|validator" | crontab -

    # Add new entries
    (
        crontab -l 2>/dev/null
        echo "# Mzee Kobe Store - Auto management"
        echo "* * * * * bash $INSTALL_DIR/core/validator.sh >> /var/log/mzeekobe_validator.log 2>&1"
        echo "0 0 * * * python3 $INSTALL_DIR/core/expiry.py --auto-delete >> /var/log/mzeekobe_expiry.log 2>&1"
        echo "0 3 1 * * bash $INSTALL_DIR/core/ssl_renew.sh renew >> /var/log/mzeekobe_ssl.log 2>&1"
    ) | crontab -

    log_ok "Cron jobs configured."
}

# ─── DNS ─────────────────────────────────────────────────────────────────────
setup_dns() {
    log_info "Configuring DNS..."
    bash "$INSTALL_DIR/core/setup_dns.sh" 2>/dev/null
    log_ok "DNS configured."
}

# ─── IP FORWARDING ────────────────────────────────────────────────────────────
setup_forwarding() {
    log_info "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    log_ok "IP forwarding enabled."
}

# ─── FIREWALL ─────────────────────────────────────────────────────────────────
setup_firewall() {
    log_info "Configuring firewall rules..."

    # UFW if available
    if command -v ufw >/dev/null 2>&1; then
        ufw --force reset >/dev/null 2>&1
        ufw default deny incoming >/dev/null 2>&1
        ufw default allow outgoing >/dev/null 2>&1
        for port in 22 80 222 443 900 1194 2082 2083 2086 2087 2200 3128 7300 8000 8080 8880 36712; do
            ufw allow "$port" >/dev/null 2>&1
        done
        ufw allow 1194/udp >/dev/null 2>&1
        ufw allow 2200/udp >/dev/null 2>&1
        ufw allow 36712/udp >/dev/null 2>&1
        ufw --force enable >/dev/null 2>&1
        log_ok "UFW firewall configured."
    else
        # iptables fallback
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
        iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null
        iptables -I INPUT -p tcp --dport 222 -j ACCEPT 2>/dev/null
        log_ok "iptables rules added."
    fi
}

# ─── SAVE CONFIG ──────────────────────────────────────────────────────────────
save_config() {
    DOMAIN=$(cat /root/.mzeekobe_domain)
    SERVER_IP=$(curl -s ifconfig.me --max-time 5)
    cat > /root/mzeekobe_config.json << EOF
{
    "domain": "$DOMAIN",
    "server_ip": "$SERVER_IP",
    "install_dir": "$INSTALL_DIR",
    "panel_command": "menu",
    "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "version": "$VERSION"
}
EOF
    log_ok "Config saved to /root/mzeekobe_config.json"
}

# ─── SUMMARY ─────────────────────────────────────────────────────────────────
print_summary() {
    DOMAIN=$(cat /root/.mzeekobe_domain)
    SERVER_IP=$(curl -s ifconfig.me --max-time 5)

    echo ""
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║         MZEE KOBE STORE - INSTALLED!            ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${GREEN}Domain   :${NC} $DOMAIN"
    echo -e "  ${GREEN}Server IP:${NC} $SERVER_IP"
    echo ""
    echo -e "  ${YELLOW}Port Reference:${NC}"
    echo -e "  SSH OpenSSH    : 22"
    echo -e "  SSH Dropbear   : 22"
    echo -e "  SSH WS / WSS   : 80 / 443"
    echo -e "  SSH Dropbear   : 22"
    echo -e "  VMess WS       : 443 (TLS) / 80 (NTLS)"
    echo -e "  VMess Custom   : 2083 (TLS) / 2082 (NTLS)"
    echo -e "  VLESS WS       : 443 (TLS) / 80 (NTLS)"
    echo -e "  VLESS Custom   : 2087 (TLS) / 2086 (NTLS)"
    echo -e "  Trojan WS      : 443 (TLS) / 80 (NTLS)"
    echo -e "  SOCKS WS       : 443 (TLS) / 80 (NTLS)"
    echo -e "  OpenVPN        : 1194 (TCP) / 2200 (UDP)"
    echo -e "  Squid Proxy    : 3128 / 8080"
    echo -e "  OHP TCP        : 8000"
    echo -e "  UDP Custom     : 36712"
    echo -e "  BadVPN UDPGW   : 7300"
    echo ""
    echo -e "  ${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}menu${NC}   - Open main panel"
    echo ""
    echo -e "  ${CYAN}Thank you for using MZEE KOBE STORE!${NC}"
    echo ""
}

# ─── MAIN ────────────────────────────────────────────────────────────────────
main() {
    banner
    check_root
    check_os

    echo -e "${WHITE}  ── STARTING INSTALLATION ────────────────────────${NC}"
    echo ""

    install_deps
    get_domain
    get_bot_token

    echo ""
    echo -e "${WHITE}  ── INSTALLING SERVICES ──────────────────────────${NC}"
    echo ""

    install_panel
    setup_ssl
    install_xray
    setup_xray_config
    setup_nginx
    setup_websocket_proxies
    install_stunnel
    setup_dropbear
    setup_squid
    install_ohp
    install_badvpn
    setup_bbr
    setup_forwarding
    setup_firewall
    setup_dns
    setup_banner
    install_bot
    setup_cron
    save_config
    print_summary
}

main
