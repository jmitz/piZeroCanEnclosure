#!/usr/bin/env bash
# Export every part as STL, one file per colour, the test prints, and a
# manifest for the viewer.
set -euo pipefail
cd "$(dirname "$0")"
out=../viewer/models
prints=../test-prints
rm -f "$out"/*.stl
mkdir -p "$prints"

manifest_entry() {
    echo "{\"part\":\"$1\",\"colour\":\"$2\",\"file\":\"$3\"}"
}

export_layer() {
    local part=$1 colour=$2
    local name="$part-${colour#\#}"
    openscad -o "$out/$name.stl" -D "part=\"$part\"" -D "layer=\"$colour\"" enclosure.scad 2>/dev/null
    manifest_entry "$part" "$colour" "$name.stl"
}

export_test_print() {
    local test=$1
    openscad -o "$prints/$test.stl" -D "test=\"$test\"" test_prints.scad 2>/dev/null
    cp "$prints/$test.stl" "$out/$test.stl"
    manifest_entry "$test" "#f28c28" "$test.stl"
}

{
    echo '['
    {
        export_layer base "#e8e8ea" &
        export_layer lid "#e8e8ea" &
        for c in "#1f7a4d" "#222" "#c8c8c8" "#111" "#444" "#e8e0c8"; do export_layer zero "$c" & done
        for c in "#1b4fa0" "#222" "#2fa24a" "#111" "#e6c200"; do export_layer hat "$c" & done
        for c in "#999" "#1a1a1a"; do export_layer plugs "$c" & done
        for t in pin_fit pin_layout; do export_test_print "$t" & done
        wait
    } | sort | paste -sd, -
    echo ']'
} > "$out/manifest.json"
