# Pi Zero CAN Enclosure

A 3D-printable enclosure for a Raspberry Pi Zero W with a Waveshare
2-CH CAN HAT, plus a WebXR viewer for inspecting the model on a Meta Quest.

**[Open the viewer](https://jmitz.github.io/piZeroCanEnclosure/)** in the Quest
Browser, or on a desktop browser to preview it.

The outside is 70.6 × 61.8 × 35.2 mm, plus a mounting ear on each side.

The viewer has been used on a real Quest to review the model. The first print
was fragile where the walls met the floor and top, and this version with fillets
hasn't been printed yet.

## Design

- **Boards:** the Zero screws down at all four holes. The HAT screws down at
  its two far corners and sits on the GPIO header at the other end.
- **Lid:** snaps on. Nothing inside it touches the HAT.
- **Walls:** every inside corner, and every join to the floor or lid top, has a
  3 mm fillet (`fillet_r`), because the first print was fragile at those joins.
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

Hole positions and the 14 mm `stack_gap` were confirmed with a printed test
frame. The printed pins used before were too weak, so the boards now use screws.

## Assembly

The Zero needs a soldered 2×20 header.

| Hardware | Qty | Used for |
| --- | --- | --- |
| M2.5 × 5 self-tapping pan head screw | 4 | Zero to the short posts |
| M2.5 × 8 self-tapping pan head screw | 2 | HAT to the tall posts |

The screws cut their own thread in the 2.2 mm pilot holes, so go gently.

1. Screw the Zero down.
2. Plug the HAT onto the header.
3. Screw down the HAT's far corners.
4. Snap on the lid.

The pilot size is `pilot_d` in `cad/enclosure.scad`.

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
| Trigger | Next view: closed, lid off, exploded, boards only |
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
- `cad/build.sh`: exports the STL files and manifest
- `viewer/main.js`: the WebXR viewer
- `viewer/serve.mjs`: the local HTTPS server
- `viewer/build_site.sh`: assembles the static site for hosting
- `viewer/models/`: generated STL files
