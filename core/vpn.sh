#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - OpenVPN Setup
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VPN_DIR="/etc/openvpn"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
CLIENT_DIR="/etc/openvpn/clients"
DOMAIN_FILE="/root/.mzeekobe_domain"

get_domain() {
    [ -f "$DOMAIN_FILE" ] && cat "$DOMAIN_FILE" || hostname -I | awk '{print $1}'
}

install_openvpn() {
    echo -e "${YELLOW}[*] Installing OpenVPN...${NC}"
    apt-get install -y -qq openvpn easy-rsa 2>/dev/null
    echo -e "${GREEN}[OK] OpenVPN installed.${NC}"
}

setup_pki() {
    echo -e "${YELLOW}[*] Setting up PKI...${NC}"
    mkdir -p "$EASYRSA_DIR"
    cp -r /usr/share/easy-rsa/* "$EASYRSA_DIR/" 2>/dev/null

    cd "$EASYRSA_DIR" || return 1

    ./easyrsa init-pki <<< "yes" 2>/dev/null
    ./easyrsa build-ca nopass <<< "MzeeKobe-CA" 2>/dev/null
    ./easyrsa gen-req server nopass <<< "server" 2>/dev/null
    ./easyrsa sign-req server server <<< "yes" 2>/dev/null
    ./easyrsa gen-dh 2>/dev/null
    openvpn --genkey --secret pki/ta.key 2>/dev/null

    echo -e "${GREEN}[OK] PKI setup complete.${NC}"
}

configure_server_tcp() {
    echo -e "${YELLOW}[*] Configuring OpenVPN TCP server (port 1194)...${NC}"

    local SERVER_IP
    SERVER_IP=$(curl -s ifconfig.me --max-time 5)

    cat > "$VPN_DIR/server-tcp.conf" << EOF
# Mzee Kobe Store - OpenVPN TCP Configuration
port 1194
proto tcp
dev tun0
ca $EASYRSA_DIR/pki/ca.crt
cert $EASYRSA_DIR/pki/issued/server.crt
key $EASYRSA_DIR/pki/private/server.key
dh $EASYRSA_DIR/pki/dh.pem
tls-auth $EASYRSA_DIR/pki/ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
explicit-exit-notify 1
EOF

    echo -e "${GREEN}[OK] TCP server config created.${NC}"
}

configure_server_udp() {
    echo -e "${YELLOW}[*] Configuring OpenVPN UDP server (port 2200)...${NC}"

    cat > "$VPN_DIR/server-udp.conf" << EOF
# Mzee Kobe Store - OpenVPN UDP Configuration
port 2200
proto udp
dev tun1
ca $EASYRSA_DIR/pki/ca.crt
cert $EASYRSA_DIR/pki/issued/server.crt
key $EASYRSA_DIR/pki/private/server.key
dh $EASYRSA_DIR/pki/dh.pem
tls-auth $EASYRSA_DIR/pki/ta.key 0
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp-udp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-udp-status.log
log-append /var/log/openvpn/openvpn-udp.log
verb 3
explicit-exit-notify 1
EOF

    echo -e "${GREEN}[OK] UDP server config created.${NC}"
}

enable_ip_forwarding() {
    echo -e "${YELLOW}[*] Enabling IP forwarding...${NC}"
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1

    # iptables NAT
    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$IFACE" -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o "$IFACE" -j MASQUERADE

    # Save iptables
    if command -v iptables-save >/dev/null 2>&1; then
        iptables-save > /etc/iptables.rules 2>/dev/null
    fi

    echo -e "${GREEN}[OK] IP forwarding enabled.${NC}"
}

start_openvpn() {
    mkdir -p /var/log/openvpn
    systemctl enable openvpn@server-tcp 2>/dev/null
    systemctl enable openvpn@server-udp 2>/dev/null
    systemctl start openvpn@server-tcp 2>/dev/null
    systemctl start openvpn@server-udp 2>/dev/null

    echo -e "${GREEN}[OK] OpenVPN started.${NC}"
    echo -e "  TCP: port 1194"
    echo -e "  UDP: port 2200"
}

generate_client() {
    local CLIENT_NAME="${1:-mzeekobe-client}"
    local DOMAIN
    DOMAIN=$(get_domain)

    echo -e "${YELLOW}[*] Generating client config: $CLIENT_NAME...${NC}"

    mkdir -p "$CLIENT_DIR"
    cd "$EASYRSA_DIR" || return 1

    ./easyrsa gen-req "$CLIENT_NAME" nopass <<< "$CLIENT_NAME" 2>/dev/null
    ./easyrsa sign-req client "$CLIENT_NAME" <<< "yes" 2>/dev/null

    # Build .ovpn file
    cat > "$CLIENT_DIR/$CLIENT_NAME.ovpn" << EOF
# Mzee Kobe Store Client Config
client
dev tun
proto tcp
remote $DOMAIN 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
verb 3
key-direction 1

<ca>
$(cat $EASYRSA_DIR/pki/ca.crt)
</ca>

<cert>
$(sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' $EASYRSA_DIR/pki/issued/$CLIENT_NAME.crt)
</cert>

<key>
$(cat $EASYRSA_DIR/pki/private/$CLIENT_NAME.key)
</key>

<tls-auth>
$(cat $EASYRSA_DIR/pki/ta.key)
</tls-auth>
EOF

    echo -e "${GREEN}[OK] Client config saved to $CLIENT_DIR/$CLIENT_NAME.ovpn${NC}"
}

status_vpn() {
    echo -e "${CYAN}[*] OpenVPN Status:${NC}"
    for svc in openvpn@server-tcp openvpn@server-udp; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  $svc: ${GREEN}RUNNING${NC}"
        else
            echo -e "  $svc: ${RED}STOPPED${NC}"
        fi
    done
}

case "${1}" in
    install)
        install_openvpn
        setup_pki
        configure_server_tcp
        configure_server_udp
        enable_ip_forwarding
        start_openvpn
        ;;
    client)
        generate_client "${2:-mzeekobe-client}"
        ;;
    status)
        status_vpn
        ;;
    start)
        start_openvpn
        ;;
    *)
        install_openvpn
        setup_pki
        configure_server_tcp
        configure_server_udp
        enable_ip_forwarding
        start_openvpn
        ;;
esac
