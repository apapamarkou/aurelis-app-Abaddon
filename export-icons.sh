#!/bin/sh

set -eu

APPDIR="./AppDir"
OUTDIR="./dist"
ICONDIR="$APPDIR/usr/share/icons"

# For every .desktop file in outdir, read the icon and find in AppDir icons
find "$OUTDIR" -name "*.desktop" -type f 2>/dev/null | while read -r desktop_file; do
    # Extract Icon name from .desktop file
    icon_name=$(grep -E '^Icon=' "$desktop_file" | head -1 | cut -d'=' -f2)

    if [ -n "$icon_name" ]; then
        icon_path=""

        # Check AppDir root first
        svg_path=$(find "$APPDIR" -maxdepth 1 -name "${icon_name}.svg" -type f 2>/dev/null | head -1)
        if [ -n "$svg_path" ]; then
            icon_path="$svg_path"
        else
            png_path=$(find "$APPDIR" -maxdepth 1 -name "${icon_name}.png" -type f 2>/dev/null | head -1)
            [ -n "$png_path" ] && icon_path="$png_path"
        fi

        # Fallback: check usr/share/icons
        if [ -z "$icon_path" ] && [ -d "$ICONDIR" ]; then
            svg_path=$(find "$ICONDIR" -name "${icon_name}.svg" -type f 2>/dev/null | head -1)
            if [ -n "$svg_path" ]; then
                icon_path="$svg_path"
            else
                png_path=$(find "$ICONDIR" -name "${icon_name}.png" -type f -printf "%s %p\n" 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
                [ -n "$png_path" ] && icon_path="$png_path"
            fi
        fi

        # Last resort: any SVG/PNG at AppDir root
        if [ -z "$icon_path" ]; then
            icon_path=$(find "$APPDIR" -maxdepth 1 \( -name "*.svg" -o -name "*.png" \) -type f 2>/dev/null | head -1)
        fi

        if [ -n "$icon_path" ]; then
            cp "$icon_path" "$OUTDIR/"
            echo "Copied icon: $(basename "$icon_path")"
        fi
    fi
done