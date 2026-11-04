import * as THREE from 'three';
import { STLLoader } from 'three/addons/loaders/STLLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const MM = 0.001;
const START_SCALE = 4;
const START_POSITION = new THREE.Vector3(0, 1.1, -0.6);
const MIN_SCALE = 1;
const MAX_SCALE = 15;

// Part lift along the model's z axis, in mm
const VIEWS = [
  { name: 'Closed', lift: { base: 0, zero: 0, plugs: 0, hat: 0, lid: 0 } },
  { name: 'Lid off', lift: { base: 0, zero: 0, plugs: 0, hat: 0, lid: 50 } },
  { name: 'Exploded', lift: { base: 0, zero: 22, plugs: 22, hat: 55, lid: 95 } },
  { name: 'Boards only', lift: { base: 0, zero: 0, plugs: 0, hat: 0, lid: 0 }, hide: ['base', 'lid'] },
];

const statusEl = document.getElementById('status');
const vrButton = document.getElementById('vr');
const arButton = document.getElementById('ar');

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.xr.enabled = true;
renderer.xr.setReferenceSpaceType('local-floor');
renderer.xr.setFoveation(1);
document.body.append(renderer.domElement);

const background = new THREE.Color('#14171c');
const scene = new THREE.Scene();
scene.background = background;
const camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.01, 50);
camera.position.set(0.45, 1.5, 0.35);

scene.add(new THREE.HemisphereLight('#ffffff', '#3b4250', 1.6));
const sun = new THREE.DirectionalLight('#ffffff', 2);
sun.position.set(1, 3, 2);
scene.add(sun);

const room = new THREE.GridHelper(10, 20, '#46505e', '#2b313b');
scene.add(room);

// Model: CAD z-up, in mm, mapped to three's y-up, in metres
const model = new THREE.Group();
const cad = new THREE.Group();
cad.rotation.x = -Math.PI / 2;
cad.scale.setScalar(MM);
model.add(cad);
scene.add(model);

const parts = { base: new THREE.Group(), lid: new THREE.Group(), zero: new THREE.Group(), hat: new THREE.Group(), plugs: new THREE.Group() };
for (const p of Object.values(parts)) cad.add(p);

function resetModel() {
  model.position.copy(START_POSITION);
  model.quaternion.identity();
  model.rotateY(-0.5);
  model.scale.setScalar(START_SCALE);
}
resetModel();

let view = 0;
let showCables = true;

// Floating instructions
const label = (() => {
  const canvas = document.createElement('canvas');
  canvas.width = 1024;
  canvas.height = 420;
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(1.1, 0.45),
    new THREE.MeshBasicMaterial({ map: texture, transparent: true }),
  );
  mesh.position.set(0, 1.85, -1.3);
  scene.add(mesh);
  return { canvas, texture, mesh };
})();

function drawLabel() {
  const c = label.canvas.getContext('2d');
  c.clearRect(0, 0, label.canvas.width, label.canvas.height);
  c.fillStyle = 'rgba(24, 28, 35, 0.9)';
  c.beginPath();
  c.roundRect(0, 0, label.canvas.width, label.canvas.height, 28);
  c.fill();
  c.fillStyle = '#ffffff';
  c.font = '600 54px system-ui, sans-serif';
  c.fillText(`${VIEWS[view].name}  ·  ${model.scale.x.toFixed(1)}× actual size`, 44, 84);
  c.fillStyle = '#c3cad5';
  c.font = '40px system-ui, sans-serif';
  [
    'Trigger: next view',
    'Grip: hold to move and turn',
    'Thumbstick: up/down resize, left/right spin',
    `A or X: cables ${showCables ? 'on' : 'off'}     B or Y: reset`,
  ].forEach((line, i) => c.fillText(line, 44, 170 + i * 62));
  label.texture.needsUpdate = true;
}

function applyVisibility() {
  const hidden = VIEWS[view].hide ?? [];
  for (const [name, group] of Object.entries(parts)) group.visible = !hidden.includes(name);
  parts.plugs.visible = showCables;
  drawLabel();
}

function nextView() {
  view = (view + 1) % VIEWS.length;
  applyVisibility();
}

function toggleCables() {
  showCables = !showCables;
  applyVisibility();
}

// Controllers: a grip moves the whole model from any distance
const holders = new Set();

function releaseModel() {
  scene.attach(model);
  holders.clear();
}

for (const i of [0, 1]) {
  const controller = renderer.xr.getController(i);
  scene.add(controller);

  const pointer = new THREE.Mesh(
    new THREE.CylinderGeometry(0.002, 0.002, 0.25, 8).rotateX(Math.PI / 2).translate(0, 0, -0.125),
    new THREE.MeshBasicMaterial({ color: '#7fb2ff' }),
  );
  controller.add(pointer);

  controller.addEventListener('selectstart', nextView);
  controller.addEventListener('squeezestart', () => {
    holders.add(controller);
    controller.attach(model);
  });
  controller.addEventListener('squeezeend', () => {
    holders.delete(controller);
    const other = [...holders][0];
    if (other) other.attach(model);
    else scene.attach(model);
  });
}

const pressed = new Map();

function justPressed(source, index) {
  const key = `${source.handedness}:${index}`;
  const down = Boolean(source.gamepad.buttons[index]?.pressed);
  const was = pressed.get(key);
  pressed.set(key, down);
  return down && !was;
}

function pollGamepads(dt) {
  const session = renderer.xr.getSession();
  if (!session) return;
  for (const source of session.inputSources) {
    if (!source.gamepad) continue;
    if (justPressed(source, 4)) toggleCables();
    if (justPressed(source, 5)) {
      releaseModel();
      resetModel();
      drawLabel();
    }
    const [, , x = 0, y = 0] = source.gamepad.axes;
    if (Math.abs(y) > 0.2) {
      const scale = THREE.MathUtils.clamp(model.scale.x * (1 - y * dt * 1.2), MIN_SCALE, MAX_SCALE);
      model.scale.setScalar(scale);
      drawLabel();
    }
    if (Math.abs(x) > 0.2) model.rotateY(x * dt * 1.8);
  }
}

function animateParts(dt) {
  const { lift } = VIEWS[view];
  const k = 1 - Math.exp(-dt * 8);
  for (const [name, group] of Object.entries(parts))
    group.position.z += (lift[name] - group.position.z) * k;
}

// Desktop preview
const orbit = new OrbitControls(camera, renderer.domElement);
orbit.target.copy(START_POSITION);
orbit.update();

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
addEventListener('keydown', (e) => {
  if (e.code === 'Space') nextView();
});

const clock = new THREE.Clock();
renderer.setAnimationLoop(() => {
  const dt = Math.min(clock.getDelta(), 0.1);
  pollGamepads(dt);
  animateParts(dt);
  renderer.render(scene, camera);
});

async function startSession(mode) {
  const session = await navigator.xr.requestSession(mode, { optionalFeatures: ['local-floor', 'bounded-floor'] });
  const passthrough = mode === 'immersive-ar';
  scene.background = passthrough ? null : background;
  room.visible = !passthrough;
  await renderer.xr.setSession(session);
  session.addEventListener('end', () => {
    scene.background = background;
    room.visible = true;
    releaseModel();
    pressed.clear();
  });
}

function offer(button, mode) {
  button.disabled = false;
  button.addEventListener('click', () => {
    startSession(mode).catch((err) => {
      statusEl.textContent = `Could not start: ${err.message}`;
    });
  });
}

async function setupXR() {
  if (!navigator.xr) {
    statusEl.textContent = window.isSecureContext
      ? 'This browser has no WebXR. Preview only.'
      : 'WebXR needs HTTPS. Open the https:// address.';
    return;
  }
  const [vr, ar] = await Promise.all(['immersive-vr', 'immersive-ar'].map((m) => navigator.xr.isSessionSupported(m).catch(() => false)));
  if (vr) offer(vrButton, 'immersive-vr');
  if (ar) offer(arButton, 'immersive-ar');
  statusEl.textContent = vr || ar ? 'Ready.' : 'No headset found. Preview only: drag to orbit, Space for next view.';
}

async function loadModel() {
  const manifest = await (await fetch('./models/manifest.json')).json();
  const loader = new STLLoader();
  await Promise.all(manifest.map(async ({ part, colour, file }) => {
    const geometry = await loader.loadAsync(`./models/${file}`);
    const metal = colour === '#c8c8c8' || colour === '#999';
    const material = new THREE.MeshStandardMaterial({ color: colour, roughness: metal ? 0.35 : 0.65, metalness: metal ? 0.7 : 0 });
    parts[part].add(new THREE.Mesh(geometry, material));
  }));
  applyVisibility();
}

loadModel()
  .then(setupXR)
  .catch((err) => {
    statusEl.textContent = `Failed to load: ${err.message}`;
  });

// Read by the emulated-headset test
export const inspect = () => ({
  view: VIEWS[view].name,
  cables: showCables,
  scale: model.scale.x,
  position: model.position.toArray(),
  parent: model.parent === scene ? 'scene' : 'controller',
  lid: parts.lid.position.z,
  presenting: renderer.xr.isPresenting,
});
