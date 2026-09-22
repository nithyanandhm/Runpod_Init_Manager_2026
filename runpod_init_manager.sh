#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────

BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
WHITE='\033[97m'

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

pause() {
    echo
    read -r -p "Press Enter to continue..." < /dev/tty
}

header() {
    clear
    echo
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║${WHITE}                  RUNPOD SSH MANAGER                    ${CYAN}║${RESET}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo
}

show_connection() {
    header

    echo -e "${BOLD}RunPod Connection${RESET}"
    echo
    echo -e "  ${DIM}Public IP${RESET}     : ${GREEN}${RUNPOD_PUBLIC_IP:-unknown}${RESET}"
    echo -e "  ${DIM}SSH Port${RESET}      : ${GREEN}${RUNPOD_TCP_PORT_22:-unknown}${RESET}"
    echo -e "  ${DIM}Ollama Port${RESET}   : ${GREEN}11434${RESET}"
    echo
    echo -e "  ${DIM}SSH command:${RESET}"
    echo

    printf '%b\n' "  ${YELLOW}ssh -i ~/.ssh/id_ed25519_runpod \\${RESET}"
    printf '%b\n' "  ${YELLOW}    -p ${RUNPOD_TCP_PORT_22:-<SSH_PORT>} \\${RESET}"
    printf '%b\n' "  ${YELLOW}    root@${RUNPOD_PUBLIC_IP:-<PUBLIC_IP>}${RESET}"

    echo

    pause
}

install_sshd() {
    header

    echo -e "${BOLD}Install / Start SSH Server${RESET}"
    echo

    if command -v sshd >/dev/null 2>&1; then
        echo -e "${GREEN}✓${RESET} openssh-server is already installed."
    else
        echo -e "${YELLOW}→${RESET} Installing openssh-server..."
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
        echo -e "${GREEN}✓${RESET} openssh-server installed."
    fi

    mkdir -p /run/sshd
    /usr/sbin/sshd

    echo -e "${GREEN}✓${RESET} sshd started."
    echo

    pause
}

add_key() {
    header

    echo -e "${BOLD}Add SSH Public Key${RESET}"
    echo
    echo -e "${DIM}Paste the complete SSH public key below.${RESET}"
    echo

    printf "${CYAN}Public key:${RESET} "
    read -r PUBKEY < /dev/tty

    if [ -z "$PUBKEY" ]; then
        echo
        echo -e "${RED}✗ No public key supplied.${RESET}"
        pause
        return 1
    fi

    mkdir -p /root/.ssh
    chmod 700 /root/.ssh

    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys

    if grep -qxF "$PUBKEY" /root/.ssh/authorized_keys 2>/dev/null; then
        echo
        echo -e "${YELLOW}!${RESET} Key already exists."
    else
        echo "$PUBKEY" >> /root/.ssh/authorized_keys
        echo
        echo -e "${GREEN}✓${RESET} SSH public key added."
    fi

    echo
    pause
}

clean_keys() {
    header

    echo -e "${BOLD}Remove Authorized SSH Keys${RESET}"
    echo

    echo -e "${YELLOW}→${RESET} Removing authorized_keys files..."

    rm -f /root/.ssh/authorized_keys
    find /home -type f -name authorized_keys -delete 2>/dev/null || true

    FOUND=$(find /root /home -type f -name authorized_keys 2>/dev/null || true)

    echo

    if [ -n "$FOUND" ]; then
        echo -e "${RED}✗ WARNING: authorized_keys files still exist:${RESET}"
        echo "$FOUND"
    else
        echo -e "${GREEN}✓ All authorized SSH keys cleaned.${RESET}"
    fi

    pause
}

remove_sshd() {
    header

    echo -e "${BOLD}Remove SSH Server${RESET}"
    echo

    echo -e "${YELLOW}→${RESET} Stopping sshd..."

    pkill -x sshd 2>/dev/null || true

    if dpkg-query -W -f='${Status}' openssh-server 2>/dev/null |
       grep -q "install ok installed"; then

        echo -e "${YELLOW}→${RESET} Removing openssh-server..."

        DEBIAN_FRONTEND=noninteractive apt-get purge -y openssh-server
        apt-get autoremove -y
    else
        echo -e "${DIM}openssh-server is not installed.${RESET}"
    fi

    echo

    if command -v sshd >/dev/null 2>&1; then
        echo -e "${RED}✗ WARNING: sshd is still installed.${RESET}"
    else
        echo -e "${GREEN}✓ SSH server removed.${RESET}"
    fi

    pause
}

# ─────────────────────────────────────────────────────────────
# Main Menu
# ─────────────────────────────────────────────────────────────

while true; do

    header

    echo -e "${BOLD}SSH Configuration${RESET}"
    echo
    echo -e "  ${CYAN}[1]${RESET}  Install / start SSH server"
    echo -e "  ${CYAN}[2]${RESET}  Add SSH public key"
    echo -e "  ${CYAN}[3]${RESET}  Remove authorized SSH keys"
    echo -e "  ${CYAN}[4]${RESET}  Remove SSH server"
    echo -e "  ${CYAN}[5]${RESET}  Show RunPod connection details"
    echo -e "  ${CYAN}[6]${RESET}  Exit"
    echo
    echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
    echo

    read -r -p "$(echo -e "${BOLD}Select an option [1-6]:${RESET} ")" OPTION < /dev/tty

    case "$OPTION" in
        1)
            install_sshd
            ;;
        2)
            add_key
            ;;
        3)
            clean_keys
            ;;
        4)
            remove_sshd
            ;;
        5)
            show_connection
            ;;
        6)
            echo
            echo -e "${GREEN}Goodbye.${RESET}"
            echo
            exit 0
            ;;
        *)
            echo
            echo -e "${RED}✗ Invalid option.${RESET}"
            sleep 1
            ;;
    esac

done
