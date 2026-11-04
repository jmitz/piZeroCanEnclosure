#!/usr/bin/env bash
# Export every part as STL, one file per colour, and a manifest for the viewer.
set -euo pipefail
cd "$(dirname "$0")"
out=../viewer/models
rm -f "$out"/*.stl

export_layer() {
    local part=$1 colour=$2
    local name="$part-${colour#\#}"
    openscad -o "$out/$name.stl" -D "part=\"$part\"" -D "layer=\"$colour\"" enclosure.scad 2>/dev/null
    echo "{\"part\":\"$part\",\"colour\":\"$colour\",\"file\":\"$name.stl\"}"
}

{
    echo '['
    {
        export_layer base "#e8e8ea" &
        export_layer lid "#e8e8ea" &
        for c in "#1f7a4d" "#222" "#c8c8c8" "#111" "#444" "#e8e0c8"; do export_layer zero "$c" & done
        for c in "#1b4fa0" "#222" "#2fa24a" "#111" "#e6c200"; do export_layer hat "$c" & done
        for c in "#999" "#1a1a1a"; do export_layer plugs "$c" & done
        export_layer zero_screws "#c8c8c8" &
        export_layer hat_screws "#c8c8c8" &
        wait
    } | sort | paste -sd, -
    echo ']'
} > "$out/manifest.json"
