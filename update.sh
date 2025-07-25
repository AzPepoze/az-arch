#!/bin/bash

#----------------------------------------------------------------------
# Universal System Updater
#
# This script streamlines the update process for the entire system,
# including the configuration repository, official packages, AUR
# packages, and Flatpak applications.
#----------------------------------------------------------------------

#-------------------------------------------------------
# Update Functions
#-------------------------------------------------------

update_repo() {
    echo "============================================================"
    echo " Updating az-arch Repository"
    echo "============================================================"
    if git pull; then
        echo "Repository updated successfully."
    else
        echo "Could not update the repository. Continuing with the script..."
    fi
}

update_system_packages() {
    echo "============================================================"
    echo " Updating System & AUR Packages (paru)"
    echo "============================================================"
    if command -v paru &> /dev/null; then
        paru -Syu --noconfirm
    else
        echo "paru command not found. Skipping system package update."
        echo "Please install paru to enable this feature."
    fi
}

update_flatpak() {
    echo "============================================================"
    echo " Updating Flatpak Packages"
    echo "============================================================"
    if command -v flatpak &> /dev/null; then
        flatpak update -y
    else
        echo "flatpak command not found. Skipping Flatpak update."
    fi
}

update_dots_hyprland() {
    echo "============================================================"
    echo " Updating dots-hyprland"
    echo "============================================================"
    if [ -d "$HOME/dots-hyprland" ]; then
        cd "$HOME/dots-hyprland" && git pull && ./install.sh -c -f
        echo "dots-hyprland updated successfully."
    else
        echo "dots-hyprland directory not found. Skipping dots-hyprland update."
        echo "Please install dots-hyprland first if you wish to update it."
    fi
}

load_configs() {
    echo "============================================================"
    echo " Load Configurations"
    echo "============================================================"

    local monitor_config_path="$HOME/.config/hypr/monitors.conf"
    local temp_dir
    temp_dir=$(mktemp -d)
    local backup_monitor_config_path="$temp_dir/monitors.conf"
    local config_script="./load_configs.sh"

    # Backup monitors.conf if it exists
    if [ -f "$monitor_config_path" ]; then
        echo "Backing up '$monitor_config_path'..."
        cp "$monitor_config_path" "$backup_monitor_config_path"
    else
        echo "Warning: '$monitor_config_path' not found. Nothing to back up."
    fi

    # Load configurations
    if [ -f "$config_script" ]; then
        bash ./load_configs.sh
    else
        echo "'$config_script' not found. Skipping config load."
    fi

    # Restore monitors.conf if it was backed up
    if [ -f "$backup_monitor_config_path" ]; then
        echo "Restoring '$monitor_config_path'..."
        # Ensure the target directory exists
        mkdir -p "$(dirname "$monitor_config_path")"
        cp "$backup_monitor_config_path" "$monitor_config_path"
    fi

    # Cleanup
    rm -rf "$temp_dir"
    echo "Configuration load process finished."
}

#-------------------------------------------------------
# Data-Driven Menu Configuration
#-------------------------------------------------------
menu_items=()
menu_funcs=()
menu_types=()

add_menu_item() {
    local type="$1"
    local func="$2"
    local text="$3"
    menu_items+=("$text")
    menu_funcs+=("$func")
    menu_types+=("$type")
}

populate_menu_data() {
    menu_items=()
    menu_funcs=()
    menu_types=()

    add_menu_item "header" "" "--- Update Suite ---"
    add_menu_item "special" "run_update_suite_all" "Run ALL remaining update tasks"

    add_menu_item "header" "" "
--- Individual Tasks ---"
    add_menu_item "task" "update_system_packages" "Update System & AUR Packages (paru)"
    add_menu_item "task" "update_flatpak" "Update Flatpak Packages"
    add_menu_item "task" "update_dots_hyprland" "Update dots-hyprland"
    add_menu_item "task" "load_configs" "Load/Sync all configurations"
}

#-------------------------------------------------------
# Update Suite Logic
#-------------------------------------------------------
run_update_suite_all() {
    echo "============================================================"
    echo " Starting full system update process (excluding repo update)..."
    echo "============================================================"
    update_system_packages
    update_flatpak
    update_dots_hyprland
    load_configs
    echo "Full system update process has finished."
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
show_menu() {
    clear
    echo "------------------------------------------------------------"
    echo " Az Arch Updater - Main Menu"
    echo "------------------------------------------------------------"
    echo "Please select an option:"

    local option_num=1
    for i in "${!menu_items[@]}"; do
        if [[ "${menu_types[i]}" == "header" ]]; then
            echo "${menu_items[i]}"
        else
            printf " %2d) %s
" "$option_num" "${menu_items[i]}"
            ((option_num++))
        fi
    done

    echo "------------------------------------------------------------"
    echo " $(($option_num))) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    populate_menu_data

    while true; do
        show_menu

        local option_count=0
        for type in "${menu_types[@]}"; do
            if [[ "$type" != "header" ]]; then
                ((option_count++))
            fi
        done
        local exit_option=$((option_count + 1))

        read -p "Enter your choice [1-$exit_option]: " choice
        echo "------------------------------------------------------------"

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid input. Please enter a number."
        elif ((choice > 0 && choice <= option_count)); then
            local current_option=0
            local target_index=-1
            for i in "${!menu_types[@]}"; do
                if [[ "${menu_types[i]}" != "header" ]]; then
                    ((current_option++))
                    if ((current_option == choice)); then
                        target_index=$i
                        break
                    fi
                fi
            done

            if ((target_index != -1)); then
                local func_to_run="${menu_funcs[target_index]}"
                if declare -f "$func_to_run" > /dev/null; then
                    "$func_to_run"
                else
                    echo "Function '$func_to_run' not found."
                fi
            fi
        elif ((choice == exit_option)); then
            echo "Exiting script. Goodbye!"
            break
        else
            echo "Invalid option '$choice'. Please try again."
        fi

        if ((choice != exit_option)); then
            echo "------------------------------------------------------------"
            read -p "Press Enter to return to the menu..."
        fi
    done
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------

# Always update the repository first to ensure the script is the latest version.
update_repo

# Proceed to the main menu.
main_menu