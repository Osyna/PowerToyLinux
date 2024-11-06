#!/bin/bash

# Ensure required tools are installed
command -v tesseract >/dev/null 2>&1 || { echo >&2 "Tesseract is required but not installed. Aborting."; exit 1; }
command -v grim >/dev/null 2>&1 || { echo >&2 "Grim is required but not installed. Aborting."; exit 1; }
command -v slurp >/dev/null 2>&1 || { echo >&2 "Slurp is required but not installed. Aborting."; exit 1; }
command -v wl-copy >/dev/null 2>&1 || { echo >&2 "wl-clipboard is required but not installed. Aborting."; exit 1; }

# Capture a selection of the screen
grim -g "$(slurp)" ocr_temp.png

# Perform OCR on the captured image
tesseract ocr_temp.png ocr_output

# Copy the OCR result to clipboard
wl-copy < ocr_output.txt

# Clean up temporary files
rm ocr_temp.png ocr_output.txt

echo "OCR completed and text copied to clipboard."
notify-send -t 2000 "OCR Tool" "text copied to clipboard."
