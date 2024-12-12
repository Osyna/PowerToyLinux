#!/bin/bash

case "$1" in
    "area")
        grimblast --notify copy area
        ;;
    "screen")
        grimblast --notify copy active
        ;;
    "all")
        grimblast --notify copy output
        ;;
    *)
        echo "Usage: screenshot [area|screen|all]"
        echo "  area   - Select an area to screenshot"
        echo "  screen - Screenshot current active window"
        echo "  all    - Screenshot all displays"
        exit 1
        ;;
esac
