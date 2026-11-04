#!/usr/bin/env bash
# Assemble the static site for hosting, keeping the paths index.html's import
# map expects. Run `npm ci` first. Usage: viewer/build_site.sh <output-dir>
set -euo pipefail
cd "$(dirname "$0")"
out=$1
three=node_modules/three

rm -rf "$out"
mkdir -p "$out/models" "$out/$three/build" "$out/$three/examples/jsm/loaders" "$out/$three/examples/jsm/controls"
cp index.html main.js "$out/"
cp models/* "$out/models/"
cp "$three/LICENSE" "$out/$three/"
cp "$three"/build/three.module.js "$three"/build/three.core.js "$out/$three/build/"
cp "$three/examples/jsm/loaders/STLLoader.js" "$out/$three/examples/jsm/loaders/"
cp "$three/examples/jsm/controls/OrbitControls.js" "$out/$three/examples/jsm/controls/"
