#!/bin/bash

# Obtenir le layout actuel
current=$(hyprctl getoption input:kb_layout -j | jq '.str' -r)

# Switcher entre les layouts
if [ "$current" = "fr" ]; then
    hyprctl keyword input:kb_variant ""
    sleep 0.1
    hyprctl keyword input:kb_layout "us"
    sleep 0.1
    hyprctl keyword input:kb_variant "colemak"
    notify-send "Keyboard" "Switched to Colemak"
else
    hyprctl keyword input:kb_variant ""
    sleep 0.1
    hyprctl keyword input:kb_layout "fr"
    notify-send "Keyboard" "Switched to AZERTY"
fi
