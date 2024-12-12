#!/bin/bash

# Function to get a random wallpaper
get_random_wallpaper() {
    find "$HOME/Pictures/wallpapers" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1
}

# Initialize swww if not running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init
fi

# Change wallpaper with transition
wallpaper=$(get_random_wallpaper)
swww img "$wallpaper" \
    --transition-fps 60 \
    --transition-type random \
    --transition-duration 3
