# Pi Zero CAN Enclosure

A 3D-printable, screwless enclosure for a Raspberry Pi Zero W with a Waveshare
2-CH CAN HAT, plus a WebXR viewer for inspecting the model on a Meta Quest.

**[Open the viewer](https://jmitz.github.io/piZeroCanEnclosure/)** in the Quest
Browser, or on a desktop browser to preview it.

The outside is 70.6 × 61.8 × 35.2 mm, plus a mounting ear on each side.

The viewer has been used on a real Quest to review the model. The enclosure
hasn't been printed or test-fitted yet.

## Design

- **Boards:** the Zero sits on four pins moulded into the base. The HAT sits on
  two pins at its far corners and on the GPIO header at the other end.
- **Lid:** snaps on, and its four hold-down tubes clamp the stack. The boards
  can lift off their pins while the lid is off.
- **Cables:** the HAT overhangs the Zero's ports, so the mini-HDMI and micro-USB
  cables run under the HAT and out through two openings in the base wall below
  the CAN terminals. Right-angle plugs won't fit.
- **Other openings:** CAN wiring and terminal screws, SD card, camera ribbon,
  lid vents and a power LED window.

Dimensions come from the official Raspberry Pi Zero W mechanical drawing and
Waveshare's `j25-2_asm.stp`. The LED window position is estimated from a photo.

## Printing

Print these two files:

- `viewer/models/base-e8e8ea.stl`
- `viewer/models/lid-e8e8ea.stl`

The Zero needs a soldered 2×20 header. No screws or metal standoffs are used.

Before printing, measure the gap from the Zero's top surface to the HAT's
underside. It's set by `stack_gap` in `cad/enclosure.scad`, currently 14 mm.
The 2.4 mm pins are moulded in and can't be replaced, so print a small test of
the fit first.

## Test prints

Print these before the base, in `test-prints/`. `cad/build.sh` regenerates them
from `cad/test_prints.scad`.

- **`pin_fit.stl`:** eight labelled pin diameters from 2.2 to 2.9 mm, with a bar
  beside the current size. Try each one in the corner holes of the real boards,
  letting the rest of the board overhang the strip. Sizes 2.8 and 2.9 are for
  the HAT only, as the Zero's holes are 2.75 mm.
- **`pin_layout.stl`:** all six pins at their true positions and heights, with
  the walls removed. Seat the Zero on it alone, then the assembled stack. The
  GPIO label marks the header end. The HAT should rest on the two tall posts at
  the same time as the Zero rests on the four short ones.

If a pin size needs changing, set `pin_d` in `cad/enclosure.scad`. If the HAT
sits high or low on the tall posts, adjust `stack_gap`.

## Changing the model

Edit `cad/enclosure.scad`, then regenerate the STL files and viewer manifest:

```sh
cad/build.sh
```

This needs OpenSCAD. STL can't carry colour, so each colour of each part is
exported as its own file, named `<part>-<colour>.stl`.

## Using the viewer

No Meta developer account or sideloading is needed. The viewer is a web page
that opens in the Quest Browser. Choose **Enter VR** or **Enter passthrough**.

| Control | Action |
| --- | --- |
| Trigger | Next view: closed, lid off, exploded, boards only, then the test prints |
| Grip | Hold to move and turn the model |
| Thumbstick | Up/down resizes, left/right spins |
| A or X | Cables on or off |
| B or Y | Reset the model's size and position |

In a desktop browser, drag to orbit and press Space for the next view.

The site is published to GitHub Pages by `.github/workflows/pages.yml` on every
push to `main`. It serves the committed files in `viewer/models/`, so run
`cad/build.sh` and commit the result after changing the model.

## Running the viewer locally

Use this to try changes before pushing. WebXR needs HTTPS, so the local server
uses a self-signed certificate.

Install the dependencies, and create a certificate for this machine's LAN IP
address. Repeat the certificate step if the address changes.

```sh
cd viewer
npm install
mkdir -p .cert
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout .cert/key.pem -out .cert/cert.pem -subj "/CN=enclosure-viewer" \
  -addext "subjectAltName=IP:<your-lan-ip>,IP:127.0.0.1,DNS:localhost"
```

Start the server. It prints the address to open, and listens on port 8443
unless `PORT` is set.

```sh
node serve.mjs
```

If `ufw` is active, allow the headset through, adjusting the subnet to match
your network:

```sh
sudo ufw allow from 192.168.0.0/24 to any port 8443 proto tcp
```

On the Quest, join the same Wi-Fi network, open the printed address in the
Quest Browser and accept the certificate warning.

## Layout

- `cad/enclosure.scad`: the model
- `cad/test_prints.scad`: the pin test prints
- `cad/build.sh`: exports the STL files and manifest
- `viewer/main.js`: the WebXR viewer
- `viewer/serve.mjs`: the local HTTPS server
- `viewer/build_site.sh`: assembles the static site for hosting
- `test-prints/`: generated test print STL files
- `viewer/models/`: generated STL files
