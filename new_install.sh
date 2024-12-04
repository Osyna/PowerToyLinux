#!/bin/bash

################################################################################
#                                                                              #
#                    THINKPAD T14 GEN 5 AMD                                    #
#                    Version: 1.0.0                                            #
#                                                                              #
################################################################################

###############################################################################
#                     CONFIGURATION GLOBALE                                     #
###############################################################################

# Configuration matérielle détaillée
declare -A HARDWARE=(
    [MODEL]="ThinkPad T14 Gen 5 AMD"
    [CPU]="Ryzen 7 PRO 8840U"
    [SCREEN_RES]="2880x1800"
    [REFRESH]="120"
    [RAM]="32"
    [WIFI]="Qualcomm® Wi-Fi 7 NCM825"
    [GPU]="AMD Radeon 780M"
    [DISPLAY]="OLED"
    [BATTERY]="52.5Wh"
    [STORAGE]="1TB NVMe PCIe Gen4"
    [WEBCAM]="5MP IR+RGB"
)

# Paquets par catégorie avec descriptions
declare -A PACKAGES=(
    [BASE]="base-devel git curl wget sudo"

    [SYSTEM]="linux-firmware amd-ucode fprintd libfprint acpi acpid \
              v4l-utils linux-headers dkms lm_sensors powertop s-tui \
              ddcutil inotify-tools irqbalance thermald nvme-cli \
              hdparm smartmontools dmidecode usbutils"

    [GPU]="mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau \
           vulkan-tools libva-utils vdpauinfo glmark2"

    [NETWORK]="networkmanager network-manager-applet bluez bluez-utils blueman \
               qcacld-firmware iwd openssh net-tools wireless-regdb \
               wpa_supplicant"

    [POWER]="tlp tlp-rdw powertop thermald \
             acpi_call tpacpi-bat"

    [AUDIO]="pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
             sof-firmware alsa-utils pavucontrol easyeffects alsa-plugins \
             pipewire-zeroconf"

    [DISPLAY]="brightnessctl autorandr gammastep redshift"

    [SHELL]="zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions \
             kitty alacritty tmux"

    [UTILITIES]="exa bat ripgrep fd htop btop neofetch fzf tmux ranger tree jq \
                 ncdu duf dust bottom procs hyperfine tokei tealdeer \
                 zip unzip p7zip mlocate fdupes progress rsync rclone"

    [APPS_SYSTEM]="gparted timeshift bleachbit gnome-disk-utility baobab \
                   system-config-printer cups"

    [APPS_OFFICE]="firefox chromium libreoffice-fresh obsidian thunderbird \
                   evince okular"

    [APPS_MEDIA]="vlc mpv gimp inkscape audacity kdenlive obs-studio"

    [APPS_FILE]="thunar thunar-archive-plugin thunar-media-tags-plugin \
                 thunar-volman file-roller"

    [DEV]="git gitui lazygit vim neovim docker docker-compose visual-studio-code-bin \
           python-pip nodejs npm"
)

# Services système
declare -a SERVICES=(
    "NetworkManager"
    "bluetooth"
    "tlp"
    "thermald"
    "powertop"
    "acpid"
    "fprintd"
    "docker"
    "cups"
    "irqbalance"
    "systemd-timesyncd"
)

# Services utilisateur
declare -a USER_SERVICES=(
    "pipewire.service"
    "pipewire-pulse.service"
    "wireplumber.service"
)

# Chemins des fichiers de configuration
declare -A CONFIG_FILES=(
    [GPU]="/etc/X11/xorg.conf.d/20-amdgpu.conf"
    [MONITOR]="/etc/X11/xorg.conf.d/10-monitor.conf"
    [WEBCAM]="/etc/modprobe.d/webcam.conf"
    [WIFI]="/etc/modprobe.d/qca6490.conf"
    [TLP]="/etc/tlp.conf"
    [ZRAM]="/etc/systemd/zram-generator.conf"
    [DDC]="/etc/udev/rules.d/90-ddcutil.rules"
    [POWERTOP]="/etc/systemd/system/powertop.service"
    [THERMALD]="/etc/thermald/thermal-conf.xml"
    [ACPI_LID]="/etc/acpi/lid.sh"
    [ACPI_EVENTS]="/etc/acpi/events/lid"
    [PIPEWIRE]="/etc/pipewire/pipewire.conf"
    [BLUETOOTH]="/etc/bluetooth/main.conf"
    [IWD]="/etc/iwd/main.conf"
    [NVME]="/etc/modprobe.d/nvme-powersave.conf"
    [SYSCTL]="/etc/sysctl.d/99-sysctl.conf"
)

# Groupes système
declare -a GROUPS=(
    "wheel"
    "video"
    "audio"
    "input"
    "docker"
    "i2c"
    "lp"
    "scanner"
)

# Couleurs pour le formatage
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [BLUE]='\033[0;34m'
    [YELLOW]='\033[1;33m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [NC]='\033[0m'
)

###############################################################################
#                          FONCTIONS UTILITAIRES                                #
###############################################################################

# Fonction de journalisation améliorée
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


###############################################################################
#                     FONCTIONS D'INSTALLATION                                  #
###############################################################################

setup_base() {
    log "INFO" "Configuration de base du système"

    # Installation de yay
    if ! command -v yay &>/dev/null; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    fi

    # Mise à jour du système
    sudo pacman -Syu --noconfirm

    # Installation des paquets de base
    install_packages ${PACKAGES[BASE]}
}

setup_gpu() {
    log "INFO" "Configuration GPU AMD"

    create_config_file "${CONFIG_FILES[GPU]}" "Section \"Device\"
    Identifier \"AMD\"
    Driver \"amdgpu\"
    Option \"TearFree\" \"true\"
    Option \"VariableRefresh\" \"true\"
    Option \"DynamicPowerManagement\" \"on\"
    Option \"EnablePageFlip\" \"on\"
    Option \"FreeSync\" \"on\"
    Option \"AsyncFlipSecondaries\" \"true\"
    Option \"ShadowPrimary\" \"true\"
    Option \"GLXVBlank\" \"on\"
    Option \"ColorTiling\" \"on\"
    Option \"ColorTiling2D\" \"on\"
EndSection"

    install_packages ${PACKAGES[GPU]}

    # Configuration du mode performance pour le GPU
    echo "SUBSYSTEM==\"drm\", ACTION==\"change\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}=\"amdgpu-power-management.service\"" | \
        sudo tee /etc/udev/rules.d/99-amdgpu-power.rules

    # Activation du support Vulkan
    sudo sed -i 's/MODULES=()/MODULES=(amdgpu)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
}

setup_display() {
    log "INFO" "Configuration de l'écran OLED"

    # Configuration DPI et taux de rafraîchissement
    create_config_file "${CONFIG_FILES[MONITOR]}" 'Section "Monitor"
    Identifier "eDP"
    Option "UseEdidDpi" "False"
    Option "DPI" "192"
    Option "Primary" "true"
    Option "PreferredMode" "2880x1800"
    Option "RefreshRate" "120"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "AMD"
    Monitor "eDP"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "2880x1800_120.00"
    EndSubSection
EndSection'

    # Protection OLED
    create_config_file "/etc/systemd/system/oled-protection.service" '[Unit]
Description=OLED Screen Protection Service
After=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/xset s 180 180
ExecStart=/usr/bin/xset dpms 300 600 900
ExecStart=/usr/bin/brightnessctl set 70%

[Install]
WantedBy=graphical.target'

    sudo systemctl enable oled-protection.service

    # Installation des outils de gestion d'affichage
    install_packages ${PACKAGES[DISPLAY]}
}

setup_network() {
    log "INFO" "Configuration réseau"

    install_packages ${PACKAGES[NETWORK]}

    # Configuration WiFi optimisée
    create_config_file "${CONFIG_FILES[WIFI]}" "options qca6490 ath11k_override_eeprom=y
options ath11k dyndbg=+p
options ath11k_pci frame_mode=2
options ath11k amsdu_agg=y
options ath11k peer_flow_ctrl=y
options ath11k nss_ratio=1"

    # Configuration iwd
    create_config_file "${CONFIG_FILES[IWD]}" "[General]
EnableNetworkConfiguration=true
AddressRandomization=once
AddressRandomizationRange=full
UseDefaultInterface=true

[Network]
EnableIPv6=true
RoutePriorityOffset=300
EnableHT=true
Enable80211ac=true
Enable80211ax=true
EnableBE=true

[Scan]
DisablePeriodicScan=false
DisableRoamingScan=false
RoamThreshold=-70
RoamThresholdBandwidth=20000"

    # Configuration Bluetooth
    create_config_file "${CONFIG_FILES[BLUETOOTH]}" "[General]
Name = ${HARDWARE[MODEL]}
Class = 0x000100
DiscoverableTimeout = 0
FastConnectable = true
AutoEnable=true

[Policy]
AutoEnable=true
ReconnectAttempts=7
ReconnectIntervals=1,2,4,8,16,32,64"

    # Activation des services réseau
    enable_service "NetworkManager"
    enable_service "bluetooth"
    enable_service "iwd"
}

setup_audio() {
    log "INFO" "Configuration audio"

    install_packages ${PACKAGES[AUDIO]}

    # Configuration PipeWire optimisée
    create_config_file "${CONFIG_FILES[PIPEWIRE]}" "context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 32
    default.clock.max-quantum = 8192
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level = -11
            rt.prio = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-profiler }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-spa-device-factory }
    { name = libpipewire-module-spa-node-factory }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-client-device }
    { name = libpipewire-module-portal }
    { name = libpipewire-module-access }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-link-factory }
    { name = libpipewire-module-session-manager }
]"

    # Activation services audio
    systemctl --user enable --now pipewire.service
    systemctl --user enable --now pipewire-pulse.service
    systemctl --user enable --now wireplumber.service
    # Optimisation des paramètres audio pour la webcam
        create_config_file "${CONFIG_FILES[WEBCAM]}" "options uvcvideo nodrop=1 timeout=5000
    options snd_usb_audio index=0 nrpacks=1"
}

setup_power() {
        log "INFO" "Configuration optimisée de la gestion d'énergie"

        install_packages ${PACKAGES[POWER]}

        # Configuration TLP optimisée pour Ryzen 7 PRO 8840U
        create_config_file "${CONFIG_FILES[TLP]}" "# Configuration optimisée ${HARDWARE[MODEL]}
    # Paramètres CPU
    CPU_DRIVER_OPMODE_ON_AC=active
    CPU_DRIVER_OPMODE_ON_BAT=active
    CPU_SCALING_GOVERNOR_ON_AC=performance
    CPU_SCALING_GOVERNOR_ON_BAT=powersave
    CPU_ENERGY_PERF_POLICY_ON_AC=performance
    CPU_ENERGY_PERF_POLICY_ON_BAT=power
    CPU_MIN_PERF_ON_AC=0
    CPU_MAX_PERF_ON_AC=100
    CPU_MIN_PERF_ON_BAT=0
    CPU_MAX_PERF_ON_BAT=80
    CPU_BOOST_ON_AC=1
    CPU_BOOST_ON_BAT=0
    CPU_HWP_DYN_BOOST_ON_AC=1
    CPU_HWP_DYN_BOOST_ON_BAT=0

    # Paramètres Platform
    PLATFORM_PROFILE_ON_AC=performance
    PLATFORM_PROFILE_ON_BAT=low-power

    # Paramètres GPU AMD
    RADEON_DPM_PERF_LEVEL_ON_AC=auto
    RADEON_DPM_PERF_LEVEL_ON_BAT=low
    RADEON_DPM_STATE_ON_AC=performance
    RADEON_DPM_STATE_ON_BAT=battery
    RADEON_POWER_PROFILE_ON_AC=high
    RADEON_POWER_PROFILE_ON_BAT=low

    # Paramètres Réseau
    WIFI_PWR_ON_AC=off
    WIFI_PWR_ON_BAT=on
    WOL_DISABLE=Y
    WAKE_ON_PLUG=Y

    # Paramètres USB
    USB_AUTOSUSPEND=1
    USB_DENYLIST=\"045e:02ff\" # Exemple pour une souris Microsoft
    USB_EXCLUDE_AUDIO=1
    USB_EXCLUDE_BTUSB=1
    USB_EXCLUDE_PRINTER=1
    USB_EXCLUDE_WWAN=1

    # Paramètres Runtime PM
    RUNTIME_PM_ON_AC=auto
    RUNTIME_PM_ON_BAT=auto
    PCIE_ASPM_ON_AC=performance
    PCIE_ASPM_ON_BAT=powersupersave

    # Paramètres Disque
    DISK_DEVICES=\"nvme0n1\"
    DISK_APM_LEVEL_ON_AC=\"254 254\"
    DISK_APM_LEVEL_ON_BAT=\"128 128\"
    DISK_SPINDOWN_TIMEOUT_ON_AC=\"0 0\"
    DISK_SPINDOWN_TIMEOUT_ON_BAT=\"0 0\"
    DISK_IOSCHED=\"none none\"
    SATA_LINKPWR_ON_AC=\"med_power_with_dipm\"
    SATA_LINKPWR_ON_BAT=\"min_power\"
    AHCI_RUNTIME_PM_ON_AC=on
    AHCI_RUNTIME_PM_ON_BAT=auto

    # Paramètres NVMe
    NVME_DIPM_ON_AC=performance
    NVME_DIPM_ON_BAT=powersave"

        # Configuration spécifique pour le SSD NVMe PCIe Gen4
        create_config_file "${CONFIG_FILES[NVME]}" "options nvme_core default_ps_max_latency_us=200
    options nvme_core mp_ns_lpol=2
    options nvme_core apst_enabled=1"

        # Configuration thermald optimisée
        create_config_file "${CONFIG_FILES[THERMALD]}" '<?xml version="1.0"?>
    <ThermalConfiguration>
        <Platform>
            <Name>Laptop</Name>
            <ProductName>ThinkPad T14 Gen 5</ProductName>
            <Preference>QUIET</Preference>
            <ThermalZones>
                <ThermalZone>
                    <Type>cpu</Type>
                    <TripPoints>
                        <TripPoint>
                            <SensorType>x86_pkg_temp</SensorType>
                            <Temperature>75000</Temperature>
                            <type>passive</type>
                            <ControlType>PARALLEL</ControlType>
                            <CoolingDevice>
                                <Type>rapl_controller</Type>
                                <SamplingPeriod>5</SamplingPeriod>
                                <TargetState>10000000</TargetState>
                            </CoolingDevice>
                        </TripPoint>
                    </TripPoints>
                </ThermalZone>
            </ThermalZones>
        </Platform>
    </ThermalConfiguration>'

        # Configuration powertop
        create_config_file "${CONFIG_FILES[POWERTOP]}" '[Unit]
    Description=PowerTop Auto Tune
    After=suspend.target
    After=hibernate.target
    After=hybrid-sleep.target

    [Service]
    Type=oneshot
    Environment="TERM=dumb"
    ExecStart=/usr/bin/powertop --auto-tune

    [Install]
    WantedBy=multi-user.target
    WantedBy=suspend.target
    WantedBy=hibernate.target
    WantedBy=hybrid-sleep.target'

        # Activation des services
        enable_service "tlp"
        enable_service "thermald"
        enable_service "powertop"
}

setup_system() {
        log "INFO" "Configuration système finale"

        # Configuration GRUB optimisée
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_pstate=active amdgpu.runpm=1 amdgpu.ppfeaturemask=0xffffffff rd.udev.log_level=3 zswap.enabled=0 nvidia-drm.modeset=1 modprobe.blacklist=nouveau,pcspkr"/' /etc/default/grub

        # Optimisation système
        create_config_file "${CONFIG_FILES[SYSCTL]}" "# I/O Scheduler
    vm.dirty_bytes = 8388608
    vm.dirty_background_bytes = 4194304
    vm.dirty_expire_centisecs = 3000
    vm.dirty_writeback_centisecs = 300
    vm.swappiness = 10
    vm.vfs_cache_pressure = 50
    vm.page-cluster = 0
    vm.laptop_mode = 5

    # Network
    net.core.netdev_max_backlog = 16384
    net.core.somaxconn = 8192
    net.ipv4.tcp_fastopen = 3
    net.ipv4.tcp_max_syn_backlog = 8192
    net.ipv4.tcp_max_tw_buckets = 2000000
    net.ipv4.tcp_tw_reuse = 1
    net.ipv4.tcp_slow_start_after_idle = 0

    # Memory Management
    vm.mmap_min_addr = 65536
    vm.oom_kill_allocating_task = 0
    vm.overcommit_memory = 1
    vm.overcommit_ratio = 50

    # ZRAM Configuration
    vm.zram.enabled = 1
    vm.watermark_boost_factor = 0
    vm.watermark_scale_factor = 125
    vm.max_map_count = 2147483642"

        # Configuration ZRAM
        create_config_file "${CONFIG_FILES[ZRAM]}" "[zram0]
    zram-size = ram/${HARDWARE[RAM]}
    compression-algorithm = zstd
    max-zram-size = 16384"

        # Configuration des règles udev pour les périphériques
        create_config_file "${CONFIG_FILES[DDC]}" 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"'

        # Optimisation des timers
        sudo systemctl enable systemd-timesyncd.service

        # Configuration du lecteur d'empreintes
        sudo sed -i 's/#RuntimePowerSaving=true/RuntimePowerSaving=true/' /etc/fprintd.conf
}

setup_shell() {
        log "INFO" "Configuration shell et terminal"

        install_packages ${PACKAGES[SHELL]}

        # Installation Oh-My-Zsh si non installé
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi

        # Configuration ZSH
        create_config_file "$HOME/.zshrc" "# Configuration ZSH pour ${HARDWARE[MODEL]}
    export ZSH=\"\$HOME/.oh-my-zsh\"
    ZSH_THEME=\"robbyrussell\"

    # Plugins
    plugins=(
        git
        docker
        sudo
        zsh-autosuggestions
        zsh-syntax-highlighting
        fzf
        tmux
        command-not-found
        dirhistory
        history
        web-search
        colored-man-pages
        extract
        nvm
        npm
        python
        pip
    )

    source \$ZSH/oh-my-zsh.sh

    # Aliases modernes
    alias ls='exa --icons'
    alias ll='exa -l --icons'
    alias la='exa -la --icons'
    alias lt='exa --tree --icons'
    alias cat='bat'
    alias top='btop'
    alias du='duf'
    alias find='fd'
    alias ps='procs'
    alias grep='rg'
    alias df='duf'
    alias vim='nvim'
    alias diff='delta'
    alias cd..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'

    # Environment
    export EDITOR='nvim'
    export VISUAL='nvim'
    export PAGER='less'
    export MANPAGER='bat -l man -p'
    export BAT_THEME='Dracula'
    export LANG=fr_FR.UTF-8
    export LC_ALL=fr_FR.UTF-8

    # FZF
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

    # Completion
    autoload -Uz compinit
    compinit

    # Path
    export PATH=\$HOME/.local/bin:\$PATH"

        # Configuration Alacritty
        mkdir -p ~/.config/alacritty
        create_config_file "$HOME/.config/alacritty/alacritty.yml" "window:
      padding:
        x: 5
        y: 5
      opacity: 0.95
      decorations: full
      startup_mode: Maximized

    scrolling:
      history: 10000
      multiplier: 3

    font:
      normal:
        family: JetBrainsMono Nerd Font
        style: Regular
      bold:
        family: JetBrainsMono Nerd Font
        style: Bold
      italic:
        family: JetBrainsMono Nerd Font
        style: Italic
      size: 11.0
      offset:
        x: 0
        y: 0
      glyph_offset:
        x: 0
        y: 0

    colors:
      primary:
        background: '#282a36'
        foreground: '#f8f8f2'
      cursor:
        text: CellBackground
        cursor: CellForeground
      normal:
        black:   '#000000'
        red:     '#ff5555'
        green:   '#50fa7b'
        yellow:  '#f1fa8c'
        blue:    '#bd93f9'
        magenta: '#ff79c6'
        cyan:    '#8be9fd'
        white:   '#bfbfbf'

    selection:
      save_to_clipboard: true

    cursor:
      style:
        shape: Block
        blinking: On
      blink_interval: 750

    mouse:
      double_click: { threshold: 300 }
      triple_click: { threshold: 300 }
      hide_when_typing: true"

        # Configuration tmux
        create_config_file "$HOME/.tmux.conf" "# Configuration tmux
    set -g default-terminal \"screen-256color\"
    set -ga terminal-overrides \",xterm-256color:Tc\"
    set -g mouse on
    set -g history-limit 10000
    set -g base-index 1
    setw -g pane-base-index 1
    set -g renumber-windows on
    set -s escape-time 0
    set -g status-interval 5
    set -g status-position top"
    }

    setup_applications() {
        log "INFO" "Installation des applications"

        # Installation par catégorie
        install_packages ${PACKAGES[APPS_SYSTEM]}
        install_packages ${PACKAGES[APPS_OFFICE]}
        install_packages ${PACKAGES[APPS_MEDIA]}
        install_packages ${PACKAGES[APPS_FILE]}
        install_packages ${PACKAGES[DEV]}

        # Configuration Thunar
        mkdir -p ~/.config/Thunar
        create_config_file "$HOME/.config/Thunar/uca.xml" '<?xml version="1.0" encoding="UTF-8"?>
    <actions>
        <action>
            <icon>utilities-terminal</icon>
            <name>Ouvrir dans Terminal</name>
            <command>alacritty --working-directory %f</command>
            <patterns>*</patterns>
            <startup-notify/>
            <directories/>
        </action>
        <action>
            <icon>system-file-manager</icon>
            <name>Ouvrir en tant que root</name>
            <command>pkexec thunar %f</command>
            <patterns>*</patterns>
            <startup-notify/>
            <directories/>
        </action>
    </actions>'

        # Configuration git
        git config --global init.defaultBranch main
        git config --global core.editor nvim
        git config --global pull.rebase true
        git config --global fetch.prune true
    }

    ###############################################################################
    #                    FONCTIONS DE VÉRIFICATION                                 #
    ###############################################################################

verify_system() {
        log "INFO" "Vérification du système"

        # Vérification utilisateur
        if [[ $EUID -eq 0 ]]; then
            error "Ne pas exécuter en tant que root, utilisez sudo"
        fi

        # Vérification connexion Internet
        if ! ping -c 1 archlinux.org &> /dev/null; then
            error "Pas de connexion Internet"
        fi

        # Vérification espace disque
        local free_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
        if (( ${free_space%.*} < 20 )); then
            error "Espace disque insuffisant (< 20GB)"
        fi

        # Vérification RAM
        local total_ram=$(free -g | awk 'NR==2 {print $2}')
        if (( total_ram < 4 )); then
            error "RAM insuffisante (< 4GB)"
        fi
    }

verify_hardware() {
        log "INFO" "Vérification du matériel"
        # Vérifications détaillées du matériel
            local -A checks=(
                [GPU]="lspci | grep -i 'VGA' | grep -i 'AMD'"
                [CPU]="lscpu | grep -i '8840U'"
                [WIFI]="lspci | grep -i 'Network' | grep -i 'Qualcomm'"
                [RAM]="free -g | awk 'NR==2 {print \$2}' | grep -E '^(2[4-9]|3[0-2])$'"
                [DISPLAY]="xrandr 2>/dev/null | grep '2880x1800'"
                [STORAGE]="lsblk | grep -i 'nvme'"
                [WEBCAM]="lsusb | grep -i 'camera'"
                [FINGERPRINT]="lsusb | grep -i 'fingerprint'"
                [BLUETOOTH]="lsusb | grep -i 'bluetooth'"
            )

            for component in "${!checks[@]}"; do
                if eval "${checks[$component]}" &>/dev/null; then
                    log "INFO" "✓ $component détecté et conforme"
                else
                    warn "⚠ $component non détecté ou non conforme"
                fi
            done

            # Vérification des capteurs
            if ! sensors &>/dev/null; then
                warn "⚠ Capteurs non détectés, installation de lm_sensors nécessaire"
            fi
        }

verify_services() {
            log "INFO" "Vérification des services"

            # Vérification services système
            for service in "${SERVICES[@]}"; do
                if systemctl is-active --quiet "$service"; then
                    log "INFO" "✓ Service $service actif"
                else
                    error "✗ Service $service inactif"
                fi
            done

            # Vérification services utilisateur
            for service in "${USER_SERVICES[@]}"; do
                if systemctl --user is-active --quiet "$service"; then
                    log "INFO" "✓ Service utilisateur $service actif"
                else
                    error "✗ Service utilisateur $service inactif"
                fi
            done
        }

verify_installation() {
            log "INFO" "Vérification de l'installation"

            # Vérification des paquets installés
            for category in "${!PACKAGES[@]}"; do
                local packages=(${PACKAGES[$category]})
                for package in "${packages[@]}"; do
                    if pacman -Qi "$package" &>/dev/null || yay -Qi "$package" &>/dev/null; then
                        log "INFO" "✓ $package installé"
                    else
                        warn "⚠ $package non installé"
                    fi
                done
            done

            # Vérification des fichiers de configuration
            for file in "${CONFIG_FILES[@]}"; do
                if [[ -f "$file" ]]; then
                    log "INFO" "✓ Fichier de configuration $file présent"
                else
                    warn "⚠ Fichier de configuration $file manquant"
                fi
            done
        }

generate_report() {
            local report_file="installation_report_${HARDWARE[MODEL]// /_}_$(date +%Y%m%d_%H%M%S).txt"

            {
                echo "=== Rapport d'installation pour ${HARDWARE[MODEL]} ==="
                echo "Date: $(date)"
                echo -e "\n=== Configuration matérielle ==="
                for key in "${!HARDWARE[@]}"; do
                    echo "$key: ${HARDWARE[$key]}"
                done

                echo -e "\n=== Services actifs ==="
                systemctl list-units --type=service --state=active

                echo -e "\n=== Services utilisateur actifs ==="
                systemctl --user list-units --type=service --state=active

                echo -e "\n=== Paquets installés ==="
                pacman -Q

                echo -e "\n=== Configuration système ==="
                echo "Kernel: $(uname -r)"
                echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
                echo "GPU Driver: $(lspci -k | grep -A 2 'VGA')"

                echo -e "\n=== Performances ==="
                echo "CPU Info:"
                lscpu
                echo -e "\nMémoire:"
                free -h
                echo -e "\nTempératures:"
                sensors

                echo -e "\n=== Journaux d'installation ==="
                journalctl -b -t "thinkpad-setup"

            } > "$report_file"

            log "INFO" "Rapport généré : $report_file"
        }

        ###############################################################################
        #                    FONCTION PRINCIPALE                                        #
        ###############################################################################

main() {
            log "INFO" "Début de l'installation pour ${HARDWARE[MODEL]}"

            # Vérifications initiales
            verify_system
            verify_hardware

            # Installation composants
            setup_base
            setup_gpu
            setup_display
            setup_network
            setup_audio
            setup_power

            # Configuration utilisateur
            setup_shell
            setup_applications

            # Configuration système
            setup_system

            # Vérifications finales
            verify_services
            verify_installation

            # Génération rapport
            generate_report

            log "INFO" "Installation terminée avec succès!"

            # Instructions finales
            echo -e "\n${COLORS[BLUE]}Actions post-installation nécessaires :${COLORS[NC]}"
            echo "1. Changer le shell par défaut : chsh -s $(which zsh)"
            echo "2. Redémarrer le système : sudo reboot"
            echo "3. Vérifier les services : systemctl --failed"
            echo "4. Tests matériels recommandés :"
            echo "   - GPU : glxinfo | grep \"OpenGL renderer\""
            echo "   - Audio : pactl info"
            echo "   - WiFi : nmcli device show"
            echo "   - Bluetooth : bluetoothctl show"
            echo "   - Webcam : v4l2-ctl --list-devices"
            echo "   - Capteurs : sensors"
            echo "   - Performances : s-tui"
            echo "   - Batterie : tlp-stat -b"
            echo "5. Vérifier les logs : journalctl -b -p 3"
        }

        ###############################################################################
        #                    EXÉCUTION                                                 #
        ###############################################################################

        # Gestion des erreurs
        set -e
        trap 'error "Erreur à la ligne $LINENO"' ERR

        # Création du journal
        exec 1> >(tee "setup_${HARDWARE[MODEL]// /_}_$(date +%Y%m%d_%H%M%S).log")
        exec 2>&1

        # Démarrage du script
        main

        exit 0
