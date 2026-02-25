#!/usr/bin/bash

# =====================================================
# Android Wi-Fi Provisioning Automation Script
# Clean Lab Provisioning Tool (ADB)
# =====================================================

set -euo pipefail
HOTSPOT_UUID=""
SECURITY="wpa2"
WIDTH=70

# ---------- Colors ----------
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
YELLOW="\e[33m"
BOLD="\e[1m"
RESET="\e[0m"

# ---------- UI ----------
line() {
    printf "%${WIDTH}s\n" | tr ' ' '='
}

section() {
    line
    printf "%*s\n" $(( (${#1} + WIDTH) / 2 )) "$1"
    line
}

success() { echo -e "${GREEN}[✓] $1${RESET}"; }
warn()    { echo -e "${YELLOW}[!] $1${RESET}"; }
error()   { echo -e "${RED}[✗] $1${RESET}"; }

# ---------- NETWORK MANAGER CHECK ----------
check_nmcli() {
    section "Checking NetworkManager"

    if ! command -v nmcli >/dev/null 2>&1; then
        error "nmcli not found. Install NetworkManager."
        exit 1
    fi

    if ! systemctl is-active --quiet NetworkManager; then
        error "NetworkManager is not running."
        exit 1
    fi

    success "NetworkManager ready."
}

# ---------- ADB Check ----------
check_adb() {
    section "Checking ADB Connection"

    if ! command -v adb >/dev/null 2>&1; then
        error "ADB is not installed."
        exit 1
    fi

    if ! adb get-state >/dev/null 2>&1; then
        error "No device detected."
        exit 1
    fi

    success "Device detected."
}

# ---------- Hotspot Creation ----------
create_hotspot() {
    section "Hotspot Configuration"

    echo "Available wireless interfaces:"
    nmcli device status | grep wifi | fold -s -w $WIDTH
    echo

    read -rp "Interface to use (e.g. wlan0): " INTERFACE
    read -rp "Hotspot SSID: " SSID
    read -rsp "Hotspot Password (min 8 chars): " PASSWORD
    echo

    if [[ -z "$INTERFACE" || -z "$SSID" || -z "$PASSWORD" ]]; then
        error "All fields are required."
        exit 1
    fi

    section "Starting Hotspot"

    # Create the hotspot with WPA2 security
    nmcli dev wifi hotspot ifname "$INTERFACE" ssid "$SSID" password "$PASSWORD" >/dev/null

    # Capture the UUID of the active hotspot bound to the selected interface
    HOTSPOT_UUID=$(nmcli -t -f UUID,DEVICE connection show --active \
      | awk -F: -v iface="$INTERFACE" '$2==iface {print $1}')

    if [[ -z "$HOTSPOT_UUID" ]]; then
        error "Failed to capture hotspot UUID."
        exit 1
    fi

    # Remove BSSID handling since we’re not using it anymore
    BSSID=""

    sleep 3
    success "Hotspot active."

    echo
    success "Hotspot Credentials:"
    echo "SSID: $SSID"
    echo "Password: $PASSWORD"
}

# ---------- Provision Network ----------
provision_network() {
    section "Provisioning Network"

    # Build the command using the fixed WPA2 security type
    CMD=(adb shell cmd wifi connect-network "$SSID" "$SECURITY")

    if [[ "$SECURITY" != "open" ]]; then
        CMD+=("$PASSWORD")
    fi

    "${CMD[@]}"

    sleep 5
    success "Provision command sent."
}

# ---------- Enable Wi-Fi ----------
enable_wifi() {
    section "Ensuring Wi-Fi Enabled"

    adb shell cmd wifi set-wifi-enabled enabled >/dev/null 2>&1
    sleep 3

    success "Wi-Fi enabled."
}

# ---------- Verify Connection ----------
verify_connection() {
    section "Connection Verification"

    MAX_ATTEMPTS=60
    SLEEP_INTERVAL=2
    TOTAL_TIME=$((MAX_ATTEMPTS * SLEEP_INTERVAL))

    ATTEMPTS=0
    IP_STATUS=""

    echo "Waiting for IP assignment..."

    while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
        REMAINING=$((TOTAL_TIME - (ATTEMPTS * SLEEP_INTERVAL)))

        # Print countdown on same line
        printf "\r⏳ Time remaining: %2ds " "$REMAINING"

        # Check for IP (non-loopback)
        IP_STATUS=$(adb shell ip -f inet addr show wlan0 2>/dev/null \
            | tr -d '\r' \
            | grep "inet " || true)

        if [[ -n "$IP_STATUS" ]]; then
            break
        fi

        sleep $SLEEP_INTERVAL
        ATTEMPTS=$((ATTEMPTS + 1))
    done

    echo  # move to next line after countdown

    if [[ -n "$IP_STATUS" ]]; then
        success "Assigned IP:"
        echo "$IP_STATUS" | fold -s -w $WIDTH
    else
        warn "No IP address assigned after $TOTAL_TIME seconds."
    fi
}

# ---------- Cleanup ----------
cleanup_hotspot() {
    section "Stopping Hotspot"

    if [[ -n "$HOTSPOT_UUID" ]]; then
        nmcli connection down uuid "$HOTSPOT_UUID"
        success "Hotspot stopped."
    else
        warn "No active hotspot UUID found."
    fi
}

# ---------- Main ----------
clear
section "Android Wi-Fi Provisioning Tool"

check_nmcli
check_adb
create_hotspot

# Since we created WPA2 hotspot, define security automatically
SECURITY="wpa2"
BSSID=""

enable_wifi
provision_network
verify_connection

section "Provisioning Complete"
success "Operation finished."

echo
read -rp "Stop hotspot? (y/n): " STOP
case "${STOP,,}" in
    y|yes)
        cleanup_hotspot
        ;;
    n|no)
        warn "Hotspot left running."
        ;;
    *)
        warn "Invalid input. Hotspot left running."
        ;;
esac
