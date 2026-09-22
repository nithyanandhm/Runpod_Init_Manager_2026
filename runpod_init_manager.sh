#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────

BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
BLUE=$'\033[34m'
WHITE=$'\033[97m'

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
    printf '%s\n' "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
    printf '%s\n' "${CYAN}${BOLD}║${WHITE}                  RUNPOD SSH MANAGER                    ${CYAN}║${RESET}"
    printf '%s\n' "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo
}

show_connection() {
    header

    printf '%s\n' "${BOLD}RunPod Connection${RESET}"
    echo

    printf '%s\n' "  ${DIM}Public IP${RESET}     : ${GREEN}${RUNPOD_PUBLIC_IP:-unknown}${RESET}"
    printf '%s\n' "  ${DIM}SSH Port${RESET}      : ${GREEN}${RUNPOD_TCP_PORT_22:-unknown}${RESET}"
    printf '%s\n' "  ${DIM}Ollama Port${RESET}   : ${GREEN}11434${RESET}"

    echo
    printf '%s\n' "  ${DIM}SSH command:${RESET}"
    echo

    printf '%s\n' "  ssh -i ~/.ssh/id_ed25519_runpod \\"
    printf '%s\n' "      -p ${RUNPOD_TCP_PORT_22:-<SSH_PORT>} \\"
    printf '%s\n' "      root@${RUNPOD_PUBLIC_IP:-<PUBLIC_IP>}"

    echo

    pause
}

install_sshd() {
    header

    printf '%s\n' "${BOLD}Install / Start SSH Server${RESET}"
    echo

    if command -v sshd >/dev/null 2>&1; then
        printf '%s\n' "${GREEN}✓${RESET} openssh-server is already installed."
    else
        printf '%s\n' "${YELLOW}→${RESET} Installing openssh-server..."

        apt-get update

        DEBIAN_FRONTEND=noninteractive \
            apt-get install -y openssh-server

        printf '%s\n' "${GREEN}✓${RESET} openssh-server installed."
    fi

    mkdir -p /run/sshd

    /usr/sbin/sshd

    printf '%s\n' "${GREEN}✓${RESET} sshd started."
    echo

    pause
}

add_key() {
    header

    printf '%s\n' "${BOLD}Add SSH Public Key${RESET}"
    echo
    printf '%s\n' "${DIM}Paste the complete SSH public key below.${RESET}"
    echo

    printf '%s' "${CYAN}Public key:${RESET} "
    read -r PUBKEY < /dev/tty

    if [ -z "$PUBKEY" ]; then
        echo
        printf '%s\n' "${RED}✗ No public key supplied.${RESET}"
        pause
        return 1
    fi

    mkdir -p /root/.ssh
    chmod 700 /root/.ssh

    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys

    if grep -qxF "$PUBKEY" /root/.ssh/authorized_keys 2>/dev/null; then
        echo
        printf '%s\n' "${YELLOW}!${RESET} Key already exists."
    else
        echo "$PUBKEY" >> /root/.ssh/authorized_keys

        echo
        printf '%s\n' "${GREEN}✓${RESET} SSH public key added."
    fi

    echo

    pause
}

clean_keys() {
    header

    printf '%s\n' "${BOLD}Remove Authorized SSH Keys${RESET}"
    echo

    printf '%s\n' "${YELLOW}→${RESET} Removing authorized_keys files..."

    rm -f /root/.ssh/authorized_keys

    find /home \
        -type f \
        -name authorized_keys \
        -delete 2>/dev/null || true

    FOUND=$(find /root /home \
        -type f \
        -name authorized_keys \
        2>/dev/null || true)

    echo

    if [ -n "$FOUND" ]; then
        printf '%s\n' "${RED}✗ WARNING: authorized_keys files still exist:${RESET}"
        echo "$FOUND"
    else
        printf '%s\n' "${GREEN}✓ All authorized SSH keys cleaned.${RESET}"
    fi

    pause
}

remove_sshd() {
    header

    printf '%s\n' "${BOLD}Remove SSH Server${RESET}"
    echo

    printf '%s\n' "${YELLOW}→${RESET} Stopping sshd..."

    pkill -x sshd 2>/dev/null || true

    if dpkg-query -W -f='${Status}' openssh-server 2>/dev/null |
        grep -q "install ok installed"; then

        printf '%s\n' "${YELLOW}→${RESET} Removing openssh-server..."

        DEBIAN_FRONTEND=noninteractive \
            apt-get purge -y openssh-server

        apt-get autoremove -y
    else
        printf '%s\n' "${DIM}openssh-server is not installed.${RESET}"
    fi

    echo

    if command -v sshd >/dev/null 2>&1; then
        printf '%s\n' "${RED}✗ WARNING: sshd is still installed.${RESET}"
    else
        printf '%s\n' "${GREEN}✓ SSH server removed.${RESET}"
    fi

    pause
}

# ─────────────────────────────────────────────────────────────
# Utility / Network Tools
# ─────────────────────────────────────────────────────────────

install_utilities() {
    header

    printf '%s\n' "${BOLD}Install Utility / Network Tools${RESET}"
    echo

    printf '%s\n' "${YELLOW}→${RESET} Installing utility packages..."
    echo

    apt-get update

    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        nano \
        nmap \
        iputils-ping \
        openssh-client \
        zstd

    echo

    printf '%s\n' "${GREEN}✓${RESET} Utility installation complete."
    echo

    printf '%s\n' "  nano : $(command -v nano || echo 'not found')"
    printf '%s\n' "  nmap : $(command -v nmap || echo 'not found')"
    printf '%s\n' "  ping : $(command -v ping || echo 'not found')"
    printf '%s\n' "  ssh  : $(command -v ssh || echo 'not found')"
    printf '%s\n' "  scp  : $(command -v scp || echo 'not found')"
    printf '%s\n' "  sftp : $(command -v sftp || echo 'not found')"
    printf '%s\n' "  zstd : $(command -v zstd || echo 'not found')"

    echo

    pause
}

# ─────────────────────────────────────────────────────────────
# Main Menu
# ─────────────────────────────────────────────────────────────

while true; do

    header

    printf '%s\n' "${BOLD}SSH Configuration${RESET}"
    echo

    printf '%s\n' "  ${CYAN}[1]${RESET}  Install / start SSH server"
    printf '%s\n' "  ${CYAN}[2]${RESET}  Add SSH public key"
    printf '%s\n' "  ${CYAN}[3]${RESET}  Remove authorized SSH keys"
    printf '%s\n' "  ${CYAN}[4]${RESET}  Remove SSH server"
    printf '%s\n' "  ${CYAN}[5]${RESET}  Install utility / network tools"
    printf '%s\n' "  ${CYAN}[6]${RESET}  Show RunPod connection details"
    printf '%s\n' "  ${CYAN}[7]${RESET}  Exit"

    echo

    printf '%s\n' "${DIM}────────────────────────────────────────────────────────────${RESET}"

    echo

    printf '%s' "${BOLD}Select an option [1-7]:${RESET} "
    read -r OPTION < /dev/tty

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
            install_utilities
            ;;

        6)
            show_connection
            ;;

        7)
            echo
            printf '%s\n' "${GREEN}Goodbye.${RESET}"
            echo
            exit 0
            ;;

        *)
            echo
            printf '%s\n' "${RED}✗ Invalid option.${RESET}"
            sleep 1
            ;;

    esac

done
