#!/usr/bin/env bash

# =====================================================
# Android Wi-Fi Provisioning Automation Script
# Clean Lab Provisioning Tool (ADB)
# =====================================================

set -euo pipefail

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
