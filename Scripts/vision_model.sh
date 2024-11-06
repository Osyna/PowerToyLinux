#!/bin/bash

# Ensure required tools are installed
command -v ollama >/dev/null 2>&1 || { echo >&2 "Ollama is required but not installed. Aborting."; exit 1; }
command -v grim >/dev/null 2>&1 || { echo >&2 "Grim is required but not installed. Aborting."; exit 1; }
command -v slurp >/dev/null 2>&1 || { echo >&2 "Slurp is required but not installed. Aborting."; exit 1; }
command -v wl-copy >/dev/null 2>&1 || { echo >&2 "wl-clipboard is required but not installed. Aborting."; exit 1; }

# Create temporary file and ensure cleanup
TEMP_IMG=$(mktemp --suffix=.png)
trap 'rm -f $TEMP_IMG' EXIT

# Show notification that selection is starting
notify-send -t 1000 "Vision Analysis" "Select an area to analyze..."

# Capture screen selection
grim -g "$(slurp)" "$TEMP_IMG"

# Check if image was captured successfully
if [ ! -f "$TEMP_IMG" ]; then
    notify-send -t 2000 "Vision Analysis" "Selection cancelled or failed"
    exit 1
fi

# Show notification that analysis is starting
notify-send -t 1000 "Vision Analysis" "Analyzing selection..."

# Run vision analysis using minicpm-v
ANALYSIS=$(ollama run minicpm-v "Describe what you see in this image. If you see any text, include it. Be concise." "$TEMP_IMG")

# Copy result to clipboard
echo "$ANALYSIS" | wl-copy

# Show notification
notify-send -t 3000 "Vision Analysis" "Analysis copied to clipboard"

# Print result to terminal
echo -e "\nAnalysis Result:"
echo "$ANALYSIS"