#!/bin/bash

#-------------------------------------------------------
# Group: CLI Tools
#-------------------------------------------------------

install_gemini_cli() {
    if ! command -v pnpm &> /dev/null; then
        _log ERROR "pnpm is not installed. Please install it first."
        if ask_yes_no "Do you want to install pnpm now?"; then
            install_pnpm
        else
            echo "Skipping Gemini CLI installation."
            return 1
        fi
    fi
    echo "Installing Gemini CLI globally using pnpm..."
    pnpm add -g @google/gemini-cli
    _log SUCCESS "Gemini CLI installation completed successfully."
}

#-------------------------------------------------------
# Fisher Installation
#-------------------------------------------------------
install_fisher() {
    echo "Installing Fisher (fish shell plugin manager)..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    _log SUCCESS "Fisher installed."
}

#-------------------------------------------------------
# jq Installation
#-------------------------------------------------------
install_jq() {
    echo "Installing jq..."
    install_paru_package "jq" "jq"
    _log SUCCESS "jq installation completed successfully."
}
