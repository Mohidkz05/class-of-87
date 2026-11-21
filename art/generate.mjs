// Generates the game icon and thumbnail with Satori. Run: npm install && npm run build
// Art rule: no people, animals, faces or figures. See ../docs/REQUIREMENTS.md, R4.
import satori from 'satori'
import { Resvg } from '@resvg/resvg-js'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'

const font = (pkg, file) => readFileSync(new URL(`node_modules/@fontsource/${pkg}/files/${file}`, import.meta.url))
const fonts = [
  { name: 'Marker', data: font('permanent-marker', 'permanent-marker-latin-400-normal.woff'), weight: 400, style: 'normal' },
  { name: 'Elite', data: font('special-elite', 'special-elite-latin-400-normal.woff'), weight: 400, style: 'normal' },
]
const CHALK = '#ece6d4'
const h = (type, style, children, extra = {}) => ({ type, props: { style: { display: 'flex', ...style }, children, ...extra } })

// A one-point perspective school corridor, drawn as SVG.
function corridor(W, H) {
  const vx = W * 0.5, vy = H * 0.44
  const nearX = W * 0.62, nearTop = H * 0.62, nearBottom = H * 0.82
  const P = (side, up, t) => [vx + side * nearX * t, vy + (up ? -nearTop : nearBottom) * t] // t: 1 near, 0 far
  const pts = (...a) => a.map((p) => p.map((n) => n.toFixed(1)).join(',')).join(' ')
  const depth = (i, n) => 1 / (1 + i * n) // even spacing along the hall in perspective
  const far = depth(12, 0.75)
  let s = `<defs>
    <radialGradient id="pool" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#fff0d0" stop-opacity=".30"/><stop offset="1" stop-color="#fff0d0" stop-opacity="0"/></radialGradient>
    <radialGradient id="exit" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#ff3a22" stop-opacity=".85"/><stop offset="1" stop-color="#ff3a22" stop-opacity="0"/></radialGradient>
    <radialGradient id="vig" cx="50%" cy="46%" r="70%"><stop offset=".35" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".94"/></radialGradient>
    <linearGradient id="dark" x1="0" y1="0" x2="0" y2="1"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".82"/></linearGradient>
  </defs><rect width="${W}" height="${H}" fill="#07090c"/>`
  // Ceiling, then upper walls
  s += `<polygon points="${pts(P(-1, 1, 1.4), P(1, 1, 1.4), P(1, 1, far), P(-1, 1, far))}" fill="#15171a"/>`
  for (const side of [-1, 1]) s += `<polygon points="${pts(P(side, 1, 1.4), P(side, 1, far), P(side, 0, far), P(side, 0, 1.4))}" fill="#3a463e"/>`
  // Checker floor
  for (let i = 0; i < 12; i++) {
    const a = depth(i, 0.75), b = depth(i + 1, 0.75)
    for (let c = -3; c < 3; c++) {
      const col = (i + c + 6) % 2 === 0 ? '#6d6a5a' : '#1c1e1d'
      const X = (t, u) => vx + ((u / 3) * nearX * t)
      const Y = (t) => vy + nearBottom * t
      s += `<polygon points="${pts([X(a, c), Y(a)], [X(a, c + 1), Y(a)], [X(b, c + 1), Y(b)], [X(b, c), Y(b)])}" fill="${col}"/>`
    }
  }
  // Plaster fallen away to bare brick, and water stains
  for (const [side, t0, t1, u0, u1, col] of [
    [-1, 0.72, 0.5, 0.52, 0.3, '#5e362a'], [-1, 0.42, 0.33, 0.62, 0.38, '#5e362a'], [1, 0.62, 0.42, 0.6, 0.36, '#5e362a'],
    [1, 0.95, 0.74, 0.38, 0.2, '#242a24'], [-1, 1.05, 0.82, 0.72, 0.5, '#242a24'], [1, 0.34, 0.27, 0.5, 0.3, '#242a24'],
  ]) {
    const W_ = (t, u) => [vx + side * nearX * t, vy - nearTop * t * u]
    s += `<polygon points="${pts(W_(t0, u0), W_((t0 + t1) / 2, u0 * 1.1), W_(t1, u0 * 0.92), W_(t1, u1), W_((t0 + t1) / 2, u1 * 0.8), W_(t0, u1))}" fill="${col}"/>`
  }
  // Lockers along both walls: they stop at 70% of the wall height
  for (const side of [-1, 1]) {
    for (let i = 0; i < 12; i++) {
      const a = depth(i, 0.75), b = depth(i + 1, 0.75)
      const top = (t) => [vx + side * nearX * t, vy + (nearBottom - (nearBottom + nearTop) * 0.62) * t]
      const col = side < 0 ? (i % 2 ? '#7a2e24' : '#6b2820') : (i % 2 ? '#2c5054' : '#264649')
      s += `<polygon points="${pts(top(a), top(b), P(side, 0, b), P(side, 0, a))}" fill="${col}" stroke="#090b0c" stroke-width="${(6 * a).toFixed(1)}"/>`
      const vent = (y) => [vx + side * nearX * (a * 0.72 + b * 0.28), vy + y * (a * 0.72 + b * 0.28)]
      s += `<line x1="${vent(-0.02 * H)[0]}" y1="${vent(-0.02 * H)[1]}" x2="${vent(0.12 * H)[0]}" y2="${vent(0.12 * H)[1]}" stroke="#0a0c0d" stroke-width="${(5 * a).toFixed(1)}"/>`
      if (side > 0 && i === 3) { // one door hanging open
        s += `<polygon points="${pts(top(a), [top(a)[0] - 70 * a, top(a)[1] + 26 * a], [P(side, 0, a)[0] - 70 * a, P(side, 0, a)[1] - 14 * a], P(side, 0, a))}" fill="#3a666b" stroke="#090b0c" stroke-width="4"/>`
      }
    }
  }
  // Fluorescent fittings, the far ones lit and the nearest dead
  for (let i = 1; i < 10; i++) {
    const t = depth(i, 0.75), u = depth(i + 0.35, 0.75)
    const lit = i >= 3 && i !== 5
    const y = (v) => vy - nearTop * v * 0.985
    s += `<polygon points="${pts([vx - 90 * t, y(t)], [vx + 90 * t, y(t)], [vx + 90 * u, y(u)], [vx - 90 * u, y(u)])}" fill="${lit ? '#d6e8be' : '#26282a'}"/>`
  }
  // Far doorway with the red exit glow
  const fx = P(1, 1, far)[0] - vx, ft = P(1, 1, far)[1], fb = P(1, 0, far)[1]
  s += `<rect x="${vx - fx}" y="${ft}" width="${fx * 2}" height="${fb - ft}" fill="#020203"/>`
  s += `<circle cx="${vx}" cy="${vy - (fb - ft) * 0.1}" r="${W * 0.12}" fill="url(#exit)"/>`
  // Footprints coming down the hall toward the viewer, alternating sides
  for (let i = 1; i < 11; i++) {
    const t = depth(i * 0.62, 0.75)
    const x = vx + (i % 2 ? -1 : 1) * 62 * t, y = vy + nearBottom * t * 0.9
    const rx = Math.max(5, 34 * t), ry = Math.max(3, 21 * t)
    s += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${rx.toFixed(1)}" ry="${ry.toFixed(1)}" fill="#060302" stroke="#a89668" stroke-opacity=".55" stroke-width="${Math.max(1, 3 * t).toFixed(1)}"/>`
    s += `<ellipse cx="${x.toFixed(1)}" cy="${(y - ry * 1.7).toFixed(1)}" rx="${(rx * 0.7).toFixed(1)}" ry="${(ry * 0.5).toFixed(1)}" fill="#060302" stroke="#a89668" stroke-opacity=".55" stroke-width="${Math.max(1, 2 * t).toFixed(1)}"/>`
  }
  // Flashlight pool, then darkness closing in
  s += `<ellipse cx="${vx}" cy="${H * 0.8}" rx="${W * 0.3}" ry="${H * 0.2}" fill="url(#pool)"/>`
  s += `<rect width="${W}" height="${H}" fill="url(#vig)"/><rect width="${W}" height="${H}" fill="url(#dark)"/>`
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${s}</svg>`
}
const dataUri = (svg) => `data:image/svg+xml;base64,${Buffer.from(svg).toString('base64')}`

async function render(tree, W, H, path) {
  const svg = await satori(tree, { width: W, height: H, fonts })
  const png = new Resvg(svg, { fitTo: { mode: 'width', value: W } }).render().asPng()
  writeFileSync(new URL(path, import.meta.url), png)
  console.log(`${path}: ${W}x${H}, ${Math.round(png.length / 1024)} KB`)
}

mkdirSync(new URL('output/', import.meta.url), { recursive: true })

// Thumbnail: corridor plus a chalk title
const TW = 1920, TH = 1080
await render(
  h('div', { width: TW, height: TH, position: 'relative', backgroundColor: '#07090c', alignItems: 'flex-end', justifyContent: 'center' }, [
    { type: 'img', props: { src: dataUri(corridor(TW, TH)), width: TW, height: TH, style: { position: 'absolute', left: 0, top: 0 } } },
    h('div', { position: 'absolute', left: 0, bottom: 56, width: TW, flexDirection: 'column', alignItems: 'center' }, [
      h('div', { fontFamily: 'Marker', fontSize: 210, color: CHALK, lineHeight: 1 }, "CLASS OF '87"),
      h('div', { fontFamily: 'Elite', fontSize: 50, color: CHALK, marginTop: 14, letterSpacing: 2 }, 'DON\'T RUN.'),
    ]),
  ]),
  TW, TH, 'output/thumbnail.png',
)

// Icon: must read at about 150x150, so one bold idea only. A chalkboard "87" with a chalk ledge.
await render(
  h('div', { width: 512, height: 512, backgroundColor: '#2a1a10', padding: 26, position: 'relative' }, [
    h('div', { width: 460, height: 460, flexDirection: 'column', alignItems: 'center', justifyContent: 'center', position: 'relative', backgroundImage: 'radial-gradient(circle at 50% 42%, #2a5a46 0%, #143026 60%, #07140f 100%)' }, [
      h('div', { fontFamily: 'Marker', fontSize: 270, color: CHALK, lineHeight: 1 }, '87'),
      h('div', { fontFamily: 'Elite', fontSize: 44, color: '#ff5a44', marginTop: 8, letterSpacing: 4 }, 'ABSENT'),
    ]),
  ]),
  512, 512, 'output/icon.png',
)
