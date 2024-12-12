#!/bin/bash

# Initialize swww if not already running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init
fi

# Function to get a random wallpaper
get_random_wallpaper() {
    find "$HOME/Pictures/wallpapers" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1
}

# Function to change wallpaper with transition
change_wallpaper() {
    local wallpaper=$(get_random_wallpaper)
    swww img "$wallpaper" \
        --transition-fps 60 \
        --transition-type random \
        --transition-duration 3
}

# Main loop
while true; do
    change_wallpaper
    sleep 600  # Wait for 10 minutes
done
