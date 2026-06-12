#!/bin/bash
# ============================================================
#   MZEE KOBE STORE - SSH User Management
# ============================================================
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\e[41;1;37m'
CYAN='\e[0;36m'
YELLOW='\e[0;33m'
GREEN='\e[0;32m'
MAGENTA='\e[0;35m'
WHITE='\e[1;37m'
NC='\e[0m'
BRED='\e[1;31m'
BGREEN='\e[1;32m'
BYELLOW='\e[1;33m'
BCYAN='\e[1;36m'

INSTALL_DIR="/usr/local/mzeekobe"

show_header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗███████╗██╗  ██╗  ███╗   ███╗███████╗███╗   ██╗██╗   ██╗${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}██╔════╝██╔════╝██║  ██║  ████╗ ████║██╔════╝████╗  ██║██║   ██║${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████╗███████╗███████║  ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}╚════██║╚════██║██╔══██║  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${BCYAN}███████║███████║██║  ██║  ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}▌  ★  SSH MENU  ★   Mzee Kobe Store                           ▐${NC}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📅 ${YELLOW}$(date '+%Y-%m-%d')${NC}  📆 ${YELLOW}$(date '+%A')${NC}  🕐 ${YELLOW}$(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ── Add SSH Account ──────────────────────────────────────────
add_ssh() {
    echo ""
    echo -e "${RED}▌  ADD SSH ACCOUNT                                             ▐${NC}"
    echo -ne "  ${YELLOW}Username   : ${NC}"; read -r user
    echo -ne "  ${YELLOW}Password   : ${NC}"; read -r pass
    echo -ne "  ${YELLOW}Days valid : ${NC}"; read -r days
    echo -ne "  ${YELLOW}Max logins : ${NC}"; read -r max_login
    echo ""
    if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$days" ] || [ -z "$max_login" ]; then
        echo -e "${BRED}  [!] All fields required.${NC}"
    else
        python3 "$INSTALL_DIR/core/ssh.py" add --user "$user" --pass "$pass" --days "$days" --limit "$max_login"
        echo ""
        echo -e "${MAGENTA}╔══════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║${NC}  ${BGREEN}SSH Account Created!${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Username ${NC}: ${YELLOW}${user}${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Password ${NC}: ${YELLOW}${pass}${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Days     ${NC}: ${YELLOW}${days}${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Max Login${NC}: ${YELLOW}${max_login}${NC}"
        echo -e "${MAGENTA}╚══════════════════════════════════╝${NC}"
    fi
    echo ""
    read -rp "  Press Enter to continue..."
}

# ── Check Logged In Users ────────────────────────────────────
check_logged_in() {
    echo ""
    echo -e "${RED}▌  LOGGED IN SSH USERS                                         ▐${NC}"
    echo -e "${MAGENTA}╔════════════════════╦════════════════════╦════════╦═══════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${CYAN}Username            ${MAGENTA}║${NC} ${CYAN}User IP             ${MAGENTA}║${NC} ${CYAN}IP Loc  ${MAGENTA}║${NC} ${CYAN}Port   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╠════════════════════╬════════════════════╬════════╬═══════╣${NC}"

    # Parse ss output for sshd connections
    declare -A seen
    while IFS= read -r line; do
        remote_ip=$(echo "$line" | awk '{print $5}' | cut -d: -f1)
        remote_port=$(echo "$line" | awk '{print $5}' | rev | cut -d: -f1 | rev)
        local_port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
        # Get username from who
        uname=$(who 2>/dev/null | awk -v ip="$remote_ip" '$0~ip{print $1}' | head -1)
        [ -z "$uname" ] && uname="unknown"
        loc=$(curl -s "https://ipinfo.io/$remote_ip/country" --max-time 3 2>/dev/null || echo "??")
        printf "${MAGENTA}║${NC} ${YELLOW}%-20s${MAGENTA}║${NC} ${YELLOW}%-20s${MAGENTA}║${NC} ${YELLOW}%-8s${MAGENTA}║${NC} ${YELLOW}%-7s${MAGENTA}║${NC}\n" \
            "$uname" "$remote_ip" "$loc" "$local_port"
    done < <(ss -tnp 2>/dev/null | grep ":22\|:222" | grep ESTAB)

    echo -e "${MAGENTA}╚════════════════════╩════════════════════╩════════╩═══════╝${NC}"
    echo ""
    echo -e "  ${CYAN}Raw sessions (who):${NC}"
    who 2>/dev/null || echo "  No active sessions."
    echo ""
    read -rp "  Press Enter to continue..."
}

# ── Delete SSH Account ───────────────────────────────────────
delete_ssh() {
    echo ""
    echo -e "${RED}▌  DELETE SSH ACCOUNT                                          ▐${NC}"
    echo -ne "  ${YELLOW}Username to delete: ${NC}"; read -r user
    if [ -z "$user" ]; then echo -e "${BRED}  [!] Username required.${NC}"; else
        echo -ne "  ${YELLOW}Confirm delete '$user'? [y/N]: ${NC}"; read -r conf
        if [[ "$conf" =~ ^[Yy]$ ]]; then
            python3 "$INSTALL_DIR/core/ssh.py" delete --user "$user"
            echo -e "  ${BGREEN}[OK]${NC} User $user deleted."
        else
            echo -e "  ${YELLOW}Cancelled.${NC}"
        fi
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

# ── List SSH Accounts ────────────────────────────────────────
list_ssh() {
    echo ""
    echo -e "${RED}▌  SSH ACCOUNT LIST                                            ▐${NC}"
    python3 "$INSTALL_DIR/core/ssh.py" list 2>/dev/null || {
        # Fallback: show from /etc/passwd
        echo -e "${CYAN}  System users with shell access:${NC}"
        echo -e "${MAGENTA}╔═══════════════════╦════════════════╦════════╗${NC}"
        echo -e "${MAGENTA}║${NC} ${CYAN}Username           ${MAGENTA}║${NC} ${CYAN}Expire Date     ${MAGENTA}║${NC} ${CYAN}Status  ${MAGENTA}║${NC}"
        echo -e "${MAGENTA}╠═══════════════════╬════════════════╬════════╣${NC}"
        grep '/home/.*:/bin/.*sh' /etc/passwd | cut -d: -f1 | while read -r u; do
            exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
            lock=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
            [ "$lock" = "L" ] && stat="${BRED}Locked${NC}" || stat="${BGREEN}Active${NC}"
            printf "${MAGENTA}║${NC} ${YELLOW}%-19s${MAGENTA}║${NC} ${YELLOW}%-16s${MAGENTA}║${NC} %-8b${MAGENTA}║${NC}\n" "$u" "${exp:-never}" "$stat"
        done
        echo -e "${MAGENTA}╚═══════════════════╩════════════════╩════════╝${NC}"
    }
    echo ""; read -rp "  Press Enter to continue..."
}

# ── Renew SSH Account ────────────────────────────────────────
renew_ssh() {
    echo ""
    echo -e "${RED}▌  RENEW SSH ACCOUNT                                           ▐${NC}"
    echo -ne "  ${YELLOW}Username: ${NC}"; read -r user
    echo -ne "  ${YELLOW}Days to add: ${NC}"; read -r days
    if [ -z "$user" ] || [ -z "$days" ]; then
        echo -e "${BRED}  [!] Username and days required.${NC}"
    else
        python3 "$INSTALL_DIR/core/ssh.py" renew --user "$user" --days "$days"
        echo -e "  ${BGREEN}[OK]${NC} Account $user renewed for $days days."
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

# ── Trial Account ────────────────────────────────────────────
trial_ssh() {
    echo ""
    echo -e "${RED}▌  TRIAL SSH ACCOUNT (1 Day)                                   ▐${NC}"
    echo -ne "  ${YELLOW}Trial username: ${NC}"; read -r user
    if [ -z "$user" ]; then
        echo -e "${BRED}  [!] Username required.${NC}"
    else
        local pass="trial${RANDOM}"
        python3 "$INSTALL_DIR/core/ssh.py" add --user "$user" --pass "$pass" --days "1" --limit "1"
        echo ""
        echo -e "${MAGENTA}╔══════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║${NC}  ${BGREEN}Trial Account Created!${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Username ${NC}: ${YELLOW}${user}${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Password ${NC}: ${YELLOW}${pass}${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Duration ${NC}: ${YELLOW}1 day${NC}"
        echo -e "${MAGENTA}║${NC}  ${CYAN}Max Login${NC}: ${YELLOW}1${NC}"
        echo -e "${MAGENTA}╚══════════════════════════════════╝${NC}"
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

# ── Change SSH Banner ────────────────────────────────────────
change_banner() {
    echo ""
    echo -e "${RED}▌  CHANGE SSH BANNER                                           ▐${NC}"
    echo -e "  ${CYAN}Current banner (/etc/issue.net):${NC}"
    cat /etc/issue.net 2>/dev/null || echo "  (empty)"
    echo ""
    echo -e "  ${YELLOW}Enter new banner text (blank line to finish):${NC}"
    banner_lines=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        banner_lines+="$line\n"
    done
    if [ -n "$banner_lines" ]; then
        printf "%b" "$banner_lines" > /etc/issue.net
        echo -e "  ${BGREEN}[OK]${NC} Banner updated."
    else
        echo -e "  ${YELLOW}No changes made.${NC}"
    fi
    echo ""; read -rp "  Press Enter to continue..."
}

# ── Main loop ────────────────────────────────────────────────
while true; do
    show_header
    echo ""
    echo -e "  ${YELLOW}[1]${NC}.Add SSH Account       ${YELLOW}[2]${NC}.Check Logged In Users"
    echo -e "  ${YELLOW}[3]${NC}.Delete SSH Account    ${YELLOW}[4]${NC}.List SSH Accounts"
    echo -e "  ${YELLOW}[5]${NC}.Renew SSH Account     ${YELLOW}[6]${NC}.Trial Account (1 day)"
    echo -e "  ${YELLOW}[7]${NC}.Change SSH Banner     ${YELLOW}[8]${NC}.Main Menu"
    echo -e "${BRED}══════════════════════════════════════════════════════════════${NC}"
    echo -ne "  ${YELLOW}[+]Select Operation${NC}: "
    read -r opt

    case "$opt" in
        1) add_ssh ;;
        2) check_logged_in ;;
        3) delete_ssh ;;
        4) list_ssh ;;
        5) renew_ssh ;;
        6) trial_ssh ;;
        7) change_banner ;;
        8|0) break ;;
        *) echo -e "${BRED}  [!] Invalid option.${NC}"; sleep 1 ;;
    esac
done
