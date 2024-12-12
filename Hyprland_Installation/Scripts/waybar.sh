#!/bin/bash
if pgrep -x "waybar"
then
    killall waybar
else
    waybar
fi
