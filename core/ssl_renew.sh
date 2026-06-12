#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - SSL Certificate Auto-Renewal
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

XRAY_CERT="/etc/xray/xray.crt"
XRAY_KEY="/etc/xray/xray.key"
DOMAIN_FILE="/root/.mzeekobe_domain"

get_domain() {
    if [ -f "$DOMAIN_FILE" ]; then
        cat "$DOMAIN_FILE"
    else
        echo ""
    fi
}

renew_certbot() {
    local DOMAIN
    DOMAIN=$(get_domain)
    echo -e "${YELLOW}[*] Renewing SSL certificate for $DOMAIN via certbot...${NC}"

    systemctl stop nginx 2>/dev/null

    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --preferred-challenges http

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK] Certificate renewed.${NC}"

        # Copy to xray directory
        mkdir -p /etc/xray
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$XRAY_CERT"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$XRAY_KEY"
        chmod 644 "$XRAY_CERT"
        chmod 600 "$XRAY_KEY"

        systemctl restart xray 2>/dev/null
        systemctl restart nginx 2>/dev/null
        echo -e "${GREEN}[OK] Xray and Nginx restarted with new cert.${NC}"
    else
        echo -e "${RED}[!] Certbot renewal failed.${NC}"
        systemctl start nginx 2>/dev/null
        return 1
    fi
}

renew_acme() {
    local DOMAIN
    DOMAIN=$(get_domain)
    echo -e "${YELLOW}[*] Renewing SSL via acme.sh for $DOMAIN...${NC}"

    if [ ! -f ~/.acme.sh/acme.sh ]; then
        curl https://get.acme.sh | sh -s email=admin@"$DOMAIN"
    fi

    ~/.acme.sh/acme.sh --issue --standalone -d "$DOMAIN"

    if [ $? -eq 0 ]; then
        mkdir -p /etc/xray
        ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
            --cert-file "$XRAY_CERT" \
            --key-file "$XRAY_KEY" \
            --fullchain-file "$XRAY_CERT" \
            --reloadcmd "systemctl restart xray nginx"
        echo -e "${GREEN}[OK] acme.sh renewal complete.${NC}"
    else
        echo -e "${RED}[!] acme.sh renewal failed.${NC}"
        return 1
    fi
}

check_cert() {
    local DOMAIN
    DOMAIN=$(get_domain)
    echo -e "${CYAN}[*] Certificate Status for $DOMAIN:${NC}"

    if [ -f "$XRAY_CERT" ]; then
        EXPIRY=$(openssl x509 -enddate -noout -in "$XRAY_CERT" 2>/dev/null | cut -d= -f2)
        echo -e "  Certificate: ${GREEN}FOUND${NC}"
        echo -e "  Expires    : $EXPIRY"

        # Days until expiry
        EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY" +%s 2>/dev/null)
        NOW_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

        if [ "$DAYS_LEFT" -lt 30 ]; then
            echo -e "  Days left  : ${RED}$DAYS_LEFT (renewal needed!)${NC}"
        else
            echo -e "  Days left  : ${GREEN}$DAYS_LEFT${NC}"
        fi
    else
        echo -e "  Certificate: ${RED}NOT FOUND${NC}"
    fi
}

setup_cron_renewal() {
    # Add monthly renewal cron
    (crontab -l 2>/dev/null | grep -v "ssl_renew"; echo "0 3 1 * * /usr/local/mzeekobe/core/ssl_renew.sh renew >> /var/log/mzeekobe_ssl.log 2>&1") | crontab -
    echo -e "${GREEN}[OK] Auto-renewal cron set (1st of each month at 3am).${NC}"
}

case "${1}" in
    renew)
        renew_certbot
        ;;
    acme)
        renew_acme
        ;;
    check)
        check_cert
        ;;
    cron)
        setup_cron_renewal
        ;;
    *)
        check_cert
        ;;
esac
