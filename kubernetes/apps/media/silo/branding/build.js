// Builds the Mikeflix brand assets for Silo.
// Usage: node build.js <outDir> [font]   font = anton | bebas
const fs = require('fs');
const path = require('path');
const opentype = require('opentype.js');
const { Resvg } = require('@resvg/resvg-js');

const out = process.argv[2];
const fontChoice = process.argv[3] || 'anton';
const fontsDir = path.join(__dirname, '..', 'fonts');
const fontFile = fontChoice === 'bebas' ? 'BebasNeue-Regular.ttf' : 'Anton-Regular.ttf';
const font = opentype.loadSync(path.join(fontsDir, fontFile));

// Palette
const RED = '#E4202B';        // Mikeflix red (accent color for Silo)
const RED_LIGHT = '#FF4D56';
const RED_DARK = '#9A0F18';
const RED_DEEP = '#6E0A11';
const INK = '#0B0B0F';        // Cinema Dark background
const TILE_TOP = '#1B1B21';
const TILE_BOTTOM = '#0D0D11';
const WHITE = '#F7F7FA';

const dirs = ['logo', 'icon', 'favicon', 'background'];
for (const d of dirs) fs.mkdirSync(path.join(out, d), { recursive: true });

function write(rel, data) {
  fs.writeFileSync(path.join(out, rel), data);
  console.log('wrote', rel);
}

function renderPng(svg, width, rel) {
  const r = new Resvg(svg, { fitTo: { mode: 'width', value: width }, background: 'rgba(0,0,0,0)' });
  write(rel, r.render().asPng());
}

// ---------- The ribbon M mark ----------
// Drawn in a 1000 x 1000 box. Four strokes of one folded ribbon:
// left stem, right stem, left diagonal (folded back, darker), right diagonal (front, lit).
function markDefs(id) {
  return `
  <linearGradient id="${id}-stem" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${RED_LIGHT}"/>
    <stop offset="0.55" stop-color="${RED}"/>
    <stop offset="1" stop-color="${RED_DARK}"/>
  </linearGradient>
  <linearGradient id="${id}-back" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="${RED_DARK}"/>
    <stop offset="1" stop-color="${RED_DEEP}"/>
  </linearGradient>
  <linearGradient id="${id}-front" x1="1" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${RED_LIGHT}"/>
    <stop offset="0.6" stop-color="${RED}"/>
    <stop offset="1" stop-color="${RED_DARK}"/>
  </linearGradient>
  <filter id="${id}-shadow" x="-20%" y="-20%" width="140%" height="140%">
    <feGaussianBlur in="SourceAlpha" stdDeviation="18"/>
    <feOffset dx="-14" dy="10" result="o"/>
    <feComponentTransfer><feFuncA type="linear" slope="0.55"/></feComponentTransfer>
    <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>`;
}

// Geometry: box x 170..830, y 200..800. Stem width 160.
const M = {
  top: 200, bottom: 800,
  lx1: 170, lx2: 330, rx1: 670, rx2: 830,
  cx1: 420, cx2: 580, // where the diagonals meet the baseline
};
function markBody(id) {
  const m = M;
  return `
  <g id="${id}">
    <rect x="${m.lx1}" y="${m.top}" width="${m.lx2 - m.lx1}" height="${m.bottom - m.top}" fill="url(#${id}-stem)"/>
    <rect x="${m.rx1}" y="${m.top}" width="${m.rx2 - m.rx1}" height="${m.bottom - m.top}" fill="url(#${id}-stem)"/>
    <polygon points="${m.lx1},${m.top} ${m.lx2},${m.top} ${m.cx2},${m.bottom} ${m.cx1},${m.bottom}" fill="url(#${id}-back)"/>
    <polygon points="${m.rx1},${m.top} ${m.rx2},${m.top} ${m.cx2},${m.bottom} ${m.cx1},${m.bottom}" fill="url(#${id}-front)" filter="url(#${id}-shadow)"/>
  </g>`;
}

// Flat single-colour version (for tiny sizes and one-colour uses)
function markFlat(color) {
  const m = M;
  return `<path fill="${color}" fill-rule="nonzero" d="
    M${m.lx1},${m.top} H${m.lx2} L${m.cx2},${m.bottom} H${m.cx1} Z
    M${m.rx1},${m.top} H${m.rx2} L${m.cx2},${m.bottom} H${m.cx1} Z
    M${m.lx1},${m.top} H${m.lx2} V${m.bottom} H${m.lx1} Z
    M${m.rx1},${m.top} H${m.rx2} V${m.bottom} H${m.rx1} Z"/>`;
}

function tileDefs(id) {
  return `
  <linearGradient id="${id}-tile" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${TILE_TOP}"/>
    <stop offset="1" stop-color="${TILE_BOTTOM}"/>
  </linearGradient>
  <radialGradient id="${id}-glow" cx="0.5" cy="0.95" r="0.8">
    <stop offset="0" stop-color="${RED}" stop-opacity="0.28"/>
    <stop offset="1" stop-color="${RED}" stop-opacity="0"/>
  </radialGradient>`;
}

// Icon: dark rounded tile + ribbon M
function iconSvg({ radius = 220, flat = false, scale = 1 } = {}) {
  const body = flat ? markFlat(RED) : markBody('m');
  const inner = scale === 1 ? body : `<g transform="translate(500 500) scale(${scale}) translate(-500 -500)">${body}</g>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">
  <defs>${tileDefs('t')}${flat ? '' : markDefs('m')}</defs>
  <rect width="1000" height="1000" rx="${radius}" fill="url(#t-tile)"/>
  <rect width="1000" height="1000" rx="${radius}" fill="url(#t-glow)"/>
  ${inner}
</svg>`;
}

// Mark alone, transparent background
function markSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">
  <defs>${markDefs('m')}</defs>
  ${markBody('m')}
</svg>`;
}

// ---------- Wordmark ----------
function textPath(text, size, x, y, spacing) {
  // opentype.js returns a Path with absolute commands; letterSpacing is in em
  const p = font.getPath(text, x, y, size, { letterSpacing: spacing, kerning: true });
  return p.toPathData(2);
}
function textWidth(text, size, spacing) {
  return font.getAdvanceWidth(text, size, { letterSpacing: spacing, kerning: true });
}

function wordmarkSvg({ color = 'gradient', withMark = false } = {}) {
  const size = 300;
  const spacing = fontChoice === 'bebas' ? 0.01 : -0.01;
  const text = 'MIKEFLIX';
  const w = textWidth(text, size, spacing);
  const pad = 40;
  const markW = withMark ? 300 : 0;
  const gap = withMark ? 70 : 0;
  const capH = size * (font.tables.os2.sCapHeight || 700) / font.unitsPerEm;
  const totalW = pad * 2 + markW + gap + w;
  const totalH = Math.round(capH + pad * 2);
  const baseline = pad + capH;
  const d = textPath(text, size, pad + markW + gap, baseline, spacing);
  const fill = color === 'gradient' ? 'url(#w-grad)' : color;
  const markScale = capH / 600; // mark body is 600 tall
  const markTranslate = `translate(${pad - 170 * markScale}, ${pad - 200 * markScale}) scale(${markScale})`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${Math.round(totalW)} ${totalH}" width="${Math.round(totalW)}" height="${totalH}">
  <defs>
    <linearGradient id="w-grad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${RED_LIGHT}"/>
      <stop offset="0.5" stop-color="${RED}"/>
      <stop offset="1" stop-color="${RED_DARK}"/>
    </linearGradient>
    ${withMark ? markDefs('m') : ''}
  </defs>
  ${withMark ? `<g transform="${markTranslate}">${markBody('m')}</g>` : ''}
  <path d="${d}" fill="${fill}"/>
</svg>`;
}

// ---------- Login background ----------
function backgroundSvg(w, h) {
  const markScale = h / 1000 * 1.35;
  const mx = w - 1000 * markScale * 0.70;
  const my = h / 2 - 500 * markScale;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#15151C"/>
      <stop offset="0.55" stop-color="${INK}"/>
      <stop offset="1" stop-color="#07070A"/>
    </linearGradient>
    <radialGradient id="glow1" cx="0.18" cy="0.95" r="0.7">
      <stop offset="0" stop-color="${RED}" stop-opacity="0.38"/>
      <stop offset="0.5" stop-color="${RED_DEEP}" stop-opacity="0.12"/>
      <stop offset="1" stop-color="${RED}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glow2" cx="0.85" cy="0.1" r="0.6">
      <stop offset="0" stop-color="#3A1C2A" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#3A1C2A" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="vignette" cx="0.5" cy="0.5" r="0.75">
      <stop offset="0.55" stop-color="#000" stop-opacity="0"/>
      <stop offset="1" stop-color="#000" stop-opacity="0.7"/>
    </radialGradient>
    <linearGradient id="beam" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${RED_LIGHT}" stop-opacity="0.10"/>
      <stop offset="1" stop-color="${RED_LIGHT}" stop-opacity="0"/>
    </linearGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="${Math.round(h / 90)}"/>
    </filter>
    ${markDefs('m')}
  </defs>
  <rect width="${w}" height="${h}" fill="url(#bg)"/>
  <rect width="${w}" height="${h}" fill="url(#glow2)"/>
  <rect width="${w}" height="${h}" fill="url(#glow1)"/>
  <!-- projector beams -->
  <polygon points="${w * 0.05},${h} ${w * 0.62},0 ${w * 0.78},0 ${w * 0.30},${h}" fill="url(#beam)" filter="url(#soft)"/>
  <polygon points="${w * 0.38},${h} ${w * 0.92},0 ${w * 1.0},0 ${w * 0.55},${h}" fill="url(#beam)" filter="url(#soft)" opacity="0.6"/>
  <!-- large faint ribbon M, bleeding off the right edge -->
  <g transform="translate(${mx}, ${my}) scale(${markScale})" opacity="0.14">${markBody('m')}</g>
  <rect width="${w}" height="${h}" fill="url(#vignette)"/>
</svg>`;
}

// ---------- Emit ----------
write('icon/mikeflix-icon.svg', iconSvg());
write('icon/mikeflix-mark.svg', markSvg());
write('icon/mikeflix-icon-flat.svg', iconSvg({ flat: true }));
for (const s of [1024, 512, 256, 128]) renderPng(iconSvg(), s, `icon/mikeflix-icon-${s}.png`);
renderPng(markSvg(), 1024, 'icon/mikeflix-mark-1024.png');

write('logo/mikeflix-wordmark.svg', wordmarkSvg());
write('logo/mikeflix-wordmark-white.svg', wordmarkSvg({ color: WHITE }));
write('logo/mikeflix-wordmark-black.svg', wordmarkSvg({ color: '#111114' }));
write('logo/mikeflix-lockup.svg', wordmarkSvg({ withMark: true }));
renderPng(wordmarkSvg(), 2000, 'logo/mikeflix-wordmark-2000.png');
renderPng(wordmarkSvg(), 800, 'logo/mikeflix-wordmark-800.png');
renderPng(wordmarkSvg({ color: WHITE }), 2000, 'logo/mikeflix-wordmark-white-2000.png');
renderPng(wordmarkSvg({ withMark: true }), 2000, 'logo/mikeflix-lockup-2000.png');

// Favicons. Flat mark under 64 px, so the strokes stay crisp.
write('favicon/favicon.svg', iconSvg({ radius: 200 }));
for (const s of [16, 32, 48]) renderPng(iconSvg({ radius: 200, flat: true, scale: 1.22 }), s, `favicon/favicon-${s}.png`);
renderPng(iconSvg({ radius: 200 }), 64, 'favicon/favicon-64.png');
renderPng(iconSvg({ radius: 200 }), 180, 'favicon/apple-touch-icon-180.png');
renderPng(iconSvg({ radius: 200 }), 192, 'favicon/android-chrome-192.png');
renderPng(iconSvg({ radius: 200 }), 512, 'favicon/android-chrome-512.png');
// Maskable icon: no rounding, the mark inside the safe zone
const maskable = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">
  <defs>${tileDefs('t')}${markDefs('m')}</defs>
  <rect width="1000" height="1000" fill="url(#t-tile)"/>
  <rect width="1000" height="1000" fill="url(#t-glow)"/>
  <g transform="translate(500 500) scale(0.8) translate(-500 -500)">${markBody('m')}</g>
</svg>`;
renderPng(maskable, 512, 'favicon/maskable-512.png');

for (const [w, h] of [[1920, 1080], [2560, 1440], [3840, 2160]]) {
  renderPng(backgroundSvg(w, h), w, `background/login-background-${w}x${h}.png`);
}
write('background/login-background.svg', backgroundSvg(2560, 1440));
