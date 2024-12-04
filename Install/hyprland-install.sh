#!/bin/bash

log() {
    local level=$1
    local message=$2
    local color=${COLORS[GREEN]}

    case $level in
        "INFO") color=${COLORS[GREEN]} ;;
        "WARN") color=${COLORS[YELLOW]} ;;
        "ERROR") color=${COLORS[RED]} ;;
        "DEBUG") color=${COLORS[BLUE]} ;;
    esac

    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message${COLORS[NC]}"
    logger -t "thinkpad-setup" "[$level] $message"
}

# Fonction d'erreur améliorée
error() {
    log "ERROR" "$1"
    exit 1
}

# Fonction de vérification avec retour
verify() {
    if [ $? -ne 0 ]; then
        error "Échec : $1"
        return 1
    else
        log "INFO" "Succès : $1"
        return 0
    fi
}

# Fonction d'avertissement
warn() {
    log "WARN" "$1"
}

# Fonction de création de dossier sécurisée
make_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        verify "Création du dossier $1"
    fi
}

# Fonction d'installation de paquets avec gestion des erreurs
install_packages() {
    local packages=("$@")
    log "INFO" "Installation des paquets : ${packages[*]}"

    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            sudo pacman -S --needed --noconfirm "$pkg" || {
                warn "Échec de l'installation de $pkg, tentative avec yay"
                if command -v yay &>/dev/null; then
                    yay -S --needed --noconfirm "$pkg" || error "Impossible d'installer $pkg"
                else
                    error "yay n'est pas installé et $pkg n'est pas disponible dans les dépôts officiels"
                fi
            }
        else
            log "DEBUG" "$pkg déjà installé"
        fi
    done
}

create_config_file() {
    local file_path=$1
    local content=$2
    local dir_path
    dir_path="$(dirname "$file_path")"  # Ceci est la bonne syntaxe

    # Alternative qui marche aussi :
    # dir_path=$(dirname "$file_path")

    if [[ ! -d "${dir_path}" ]]; then
        sudo mkdir -p "${dir_path}" || error "Impossible de créer le répertoire ${dir_path}"
    fi

    echo "${content}" | sudo tee "${file_path}" > /dev/null

    if [[ $? -ne 0 ]]; then
        error "Impossible de créer le fichier ${file_path}"
        return 1
    fi

    sudo chmod 644 "${file_path}" || error "Impossible de modifier les permissions de ${file_path}"

    log "INFO" "Fichier de configuration créé : ${file_path}"
    return 0
}



# Fonction d'activation des services avec vérification
enable_service() {
    local service_name=$1
    local system_level=${2:-system}  # 'system' ou 'user', par défaut 'system'

    log "INFO" "Activation du service : $service_name (niveau: $system_level)"

    if [ "$system_level" = "user" ]; then
        systemctl --user enable "$service_name" || error "Impossible d'activer le service utilisateur $service_name"
        systemctl --user start "$service_name" || error "Impossible de démarrer le service utilisateur $service_name"

        if ! systemctl --user is-active --quiet "$service_name"; then
            error "Le service utilisateur $service_name n'est pas actif après activation"
            return 1
        fi
    else
        sudo systemctl enable "$service_name" || error "Impossible d'activer le service système $service_name"
        sudo systemctl start "$service_name" || error "Impossible de démarrer le service système $service_name"

        if ! systemctl is-active --quiet "$service_name"; then
            error "Le service système $service_name n'est pas actif après activation"
            return 1
        fi
    fi

    log "INFO" "Service $service_name activé et démarré avec succès"
    return 0
}


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
