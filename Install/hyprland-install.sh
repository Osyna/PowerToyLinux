#!/bin/bash

# Source the existing configuration functions
source /path/to/your/original/script.sh

# Additional packages needed for Hyprland setup
declare -A HYPR_PACKAGES=(
    [HYPRLAND]="hyprland xdg-desktop-portal-hyprland qt5-wayland qt6-wayland \
                polkit-kde-agent dunst waybar rofi wofi swaylock-effects \
                swayidle swaybg wl-clipboard grim slurp jq xdg-utils \
                wf-recorder light pamixer brightnessctl"
    
    [LOOKS]="nwg-look kvantum qt5ct qt6ct catppuccin-gtk-theme \
             papirus-icon-theme ttf-jetbrains-mono-nerd \
             ttf-font-awesome noto-fonts-emoji"
)

install_hyprland() {
    log "INFO" "Installing Hyprland and dependencies"
    
    # Install yay if not present
    if ! command -v yay &>/dev/null; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    fi

    # Install all required packages
    for category in "${!HYPR_PACKAGES[@]}"; do
        install_packages ${HYPR_PACKAGES[$category]}
    done

    # Create necessary directories
    mkdir -p ~/.config/{hypr,waybar,rofi,dunst,swaylock}

    # Copy configurations
    setup_hyprland_config
    setup_waybar_config
    setup_rofi_config
    setup_dunst_config
    setup_swaylock_config

    # Set up environment variables
    setup_environment

    log "INFO" "Hyprland installation completed"
}

setup_environment() {
    # Create environment file for Wayland/Hyprland
    create_config_file "$HOME/.config/hypr/environment" "# Environment Variables
export _JAVA_AWT_WM_NONREPARENTING=1
export XCURSOR_SIZE=24
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export MOZ_ENABLE_WAYLAND=1
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export GDK_BACKEND=wayland"
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_hyprland
fi
