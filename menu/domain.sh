#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - Domain / Add/Change Domain
# ============================================================
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\e[41;1;37m'
CYAN='\e[0;36m'
YELLOW='\e[0;33m'
GREEN='\e[0;32m'
MAGENTA='\e[0;35m'
BLUE='\e[0;34m'
WHITE='\e[1;37m'
NC='\e[0m'
BRED='\e[1;31m'
BGREEN='\e[1;32m'
BCYAN='\e[1;36m'

INSTALL_DIR="/usr/local/mzeekobe"
DOMAIN_FILE="/root/.mzeekobe_domain"
NGINX_CONF="/etc/nginx/conf.d/mzeekobe.conf"

show_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BCYAN}██████╗  ██████╗ ███╗   ███╗ █████╗ ██╗███╗   ██╗${BCYAN}          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BCYAN}██╔══██╗██╔═══██╗████╗ ████║██╔══██╗██║████╗  ██║${BCYAN}          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BCYAN}██║  ██║██║   ██║██╔████╔██║███████║██║██╔██╗ ██║${BCYAN}          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BCYAN}██║  ██║██║   ██║██║╚██╔╝██║██╔══██║██║██║╚██╗██║${BCYAN}          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BCYAN}██████╔╝╚██████╔╝██║ ╚═╝ ██║██║  ██║██║██║ ╚████║${BCYAN} CHANGER  ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  DOMAIN SETTINGS  ★   Mzee Kobe Store                    ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    local cur_domain
    cur_domain=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")
    echo -e "  ${CYAN}Current Domain${NC}: ${GREEN}${cur_domain}${NC}"
    echo ""
}

change_domain() {
    local OLD_DOMAIN
    OLD_DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")
    echo -e "${RED}▌  CHANGE DOMAIN                                               ▐${NC}"
    echo -e "  ${CYAN}Current${NC}: ${GREEN}${OLD_DOMAIN}${NC}"
    echo -ne "  ${YELLOW}Enter Domain Name${NC}: "
    read -r NEW_DOMAIN

    if [ -z "$NEW_DOMAIN" ]; then
        echo -e "${BRED}  [!] Domain cannot be empty.${NC}"
        return
    fi

    # Validate DNS
    SERVER_IP=$(curl -s ifconfig.me --max-time 5 2>/dev/null || hostname -I | awk '{print $1}')
    DOMAIN_IP=$(dig +short "$NEW_DOMAIN" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

    if [ -n "$DOMAIN_IP" ] && [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
        echo -e "${YELLOW}  [!] Warning: $NEW_DOMAIN -> $DOMAIN_IP (server is $SERVER_IP)${NC}"
        echo -ne "  ${YELLOW}Continue anyway? [y/N]: ${NC}"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}  Cancelled.${NC}"; return
        fi
    elif [ -n "$DOMAIN_IP" ] && [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
        echo -e "  ${BGREEN}[OK]${NC} DNS verified: $NEW_DOMAIN -> $SERVER_IP"
    else
        echo -e "${YELLOW}  [!] Could not verify DNS. Proceeding anyway.${NC}"
    fi

    # Save domain
    echo "$NEW_DOMAIN" > "$DOMAIN_FILE"
    echo -e "  ${BGREEN}[OK]${NC} Domain saved: $NEW_DOMAIN"

    # Update nginx config
    if [ -f "$NGINX_CONF" ]; then
        sed -i "s/server_name[^;]*/server_name $NEW_DOMAIN *.$NEW_DOMAIN/g" "$NGINX_CONF"
        sed -i "s|/etc/letsencrypt/live/[^/]*/|/etc/letsencrypt/live/$NEW_DOMAIN/|g" "$NGINX_CONF"
        nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null && \
            echo -e "  ${BGREEN}[OK]${NC} Nginx config updated." || \
            echo -e "${BRED}  [!] Nginx reload failed. Check nginx -t${NC}"
    fi

    # Update xray certs if available
    if [ -d "/etc/letsencrypt/live/$NEW_DOMAIN" ]; then
        cp "/etc/letsencrypt/live/$NEW_DOMAIN/fullchain.pem" /etc/xray/xray.crt 2>/dev/null
        cp "/etc/letsencrypt/live/$NEW_DOMAIN/privkey.pem" /etc/xray/xray.key 2>/dev/null
        systemctl restart xray 2>/dev/null
        echo -e "  ${BGREEN}[OK]${NC} Xray certs updated."
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

renew_ssl() {
    local DOMAIN
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "")
    if [ -z "$DOMAIN" ]; then
        echo -e "${BRED}  [!] No domain configured.${NC}"
        echo ""; read -rp "  Press Enter to continue..."; return
    fi
    echo -e "${YELLOW}  [*] Renewing SSL certificate for $DOMAIN...${NC}"
    systemctl stop nginx 2>/dev/null
    certbot certonly --standalone -d "$DOMAIN" --non-interactive \
        --agree-tos --register-unsafely-without-email \
        --preferred-challenges http 2>&1 | tail -10
    systemctl start nginx 2>/dev/null
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt 2>/dev/null
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key 2>/dev/null
        systemctl restart xray 2>/dev/null
        echo -e "  ${BGREEN}[OK]${NC} Certificate renewed and applied."
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

check_ssl() {
    local DOMAIN
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "")
    if [ -z "$DOMAIN" ]; then echo -e "${BRED}  [!] No domain configured.${NC}"; else
        echo -e "${CYAN}  SSL Certificate Info for $DOMAIN:${NC}"
        if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
            openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
                -noout -subject -dates 2>/dev/null | sed 's/^/  /'
        elif [ -f "/etc/xray/xray.crt" ]; then
            openssl x509 -in /etc/xray/xray.crt -noout -subject -dates 2>/dev/null | sed 's/^/  /'
        else
            echo -e "  ${YELLOW}No certificate found.${NC}"
        fi
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

while true; do
    show_header
    echo -e "  ${YELLOW}[1]${NC}.Show Current Domain"
    echo -e "  ${YELLOW}[2]${NC}.Change Domain"
    echo -e "  ${YELLOW}[3]${NC}.Renew SSL Certificate"
    echo -e "  ${YELLOW}[4]${NC}.Check SSL Certificate"
    echo -e "  ${YELLOW}[5]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1)
            echo ""
            echo -e "  ${CYAN}Domain${NC}: ${GREEN}$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")${NC}"
            echo ""; read -rp "  Press Enter to continue..."
            ;;
        2) change_domain ;;
        3) renew_ssl ;;
        4) check_ssl ;;
        5|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
