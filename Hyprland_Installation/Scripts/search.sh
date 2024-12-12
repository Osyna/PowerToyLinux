#!/bin/bash
# Save as ~/.local/bin/quicksearch

CACHE_DIR="$HOME/.cache/quicksearch"
CACHE_FILE="$CACHE_DIR/file_cache"
mkdir -p "$CACHE_DIR"

update_cache() {
    # Using fd to find all files, excluding common unwanted directories
    fd --hidden --no-ignore \
       --exclude .git \
       --exclude node_modules \
       --exclude .cache \
       --exclude .local/share/Trash \
       --exclude lost+found \
       . /home > "$CACHE_FILE"
}

# Update cache if it doesn't exist or is older than 1 hour
if [ ! -f "$CACHE_FILE" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -gt 3600 ]; then
    update_cache
fi

# Use wayland-based rofi command
selection=$(cat "$CACHE_FILE" | rofi -dmenu -i -p "Search Files" \
    -theme ~/.config/rofi/config/search.rasi \
    -kb-custom-1 "Alt+Return" \
    -kb-custom-2 "Alt+r" \
    -kb-custom-3 "Alt+c")

exit_value=$?

if [ -n "$selection" ]; then
    case $exit_value in
        0) # Normal Return - Open parent directory
            if [ -d "$selection" ]; then
                # If it's a directory, open it directly
                thunar "$selection"
            else
                # If it's a file, open parent directory
                thunar "$(dirname "$selection")"
            fi
            ;;
        10) # Alt+Return - Open file directly
            xdg-open "$selection" ;;
        11) # Alt+r - Refresh cache
            update_cache
            exec "$0" ;;
        12) # Alt+c - Copy path to clipboard
            echo -n "$selection" | wl-copy
            notify-send "Path copied to clipboard" "$selection" ;;
    esac
fi
