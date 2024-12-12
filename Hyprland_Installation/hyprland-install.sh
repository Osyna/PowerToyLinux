#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}Starting Hyprland setup...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install paru if not present
if ! command_exists paru; then
    echo -e "${BLUE}Installing paru...${NC}"
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

# Required packages based on the configuration files
echo -e "${BLUE}Installing required packages...${NC}"
PACKAGES=(
    # Core Hyprland packages
    "hyprland" 
    "hyprpm"
    "waybar"
    
    # Utilities mentioned in config
    "polkit-gnome"          # Authentication agent
    "kitty"                 # Terminal
    "firefox"               # Browser
    "avizo"                 # OSD notifications
    "swww"                  # Wallpaper daemon
    "wlsunset"             # Blue light filter
    "network-manager-applet" # nm-applet
    "thunar"               # File manager
    "rofi"                 # Application launcher
    "wlogout"             # Logout menu
    
    # Multimedia controls
    "playerctl"            # Media player control
    "pamixer"             # Volume control
    "light"               # Brightness control
    
    # Screenshot and OCR utilities
    "grim"                # Screenshot utility
    "slurp"               # Area selection
    "tesseract"           # OCR engine
    "tesseract-data-eng"  # English language data for OCR
    "wl-clipboard"        # Wayland clipboard utility
)

# Install packages using paru
paru -S --needed "${PACKAGES[@]}"

# Backup existing configurations
echo -e "${BLUE}Backing up existing configurations...${NC}"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/config_backup_$BACKUP_DATE"
mkdir -p "$BACKUP_DIR"

# Backup existing configurations if they exist
for dir in gtk-3.0 gtk-4.0 hypr kitty thunar rofi waybar; do
    if [ -d "$HOME/.config/$dir" ]; then
        mv "$HOME/.config/$dir" "$BACKUP_DIR/"
    fi
done

# Create necessary directories
echo -e "${BLUE}Creating necessary directories...${NC}"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/Scripts"
mkdir -p "$HOME/Pictures/wallpapers"  # For wallpaper scripts

# Copy configuration files
echo -e "${BLUE}Copying configuration files...${NC}"
# Copy all configuration directories
cp -r "$SCRIPT_DIR/Config/"* "$HOME/.config/"

# Copy scripts
echo -e "${BLUE}Copying scripts...${NC}"
cp -r "$SCRIPT_DIR/Scripts/"* "$HOME/Scripts/"

# Set executable permissions for scripts
chmod +x "$HOME/Scripts/"*.sh

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Configuration backup can be found at: $BACKUP_DIR${NC}"
echo -e "${BLUE}Please log out and select Hyprland as your session to start using it.${NC}"

# Optional: Source the new configuration
echo -e "${BLUE}Would you like to reload Hyprland configuration? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    hyprctl reload
fi
