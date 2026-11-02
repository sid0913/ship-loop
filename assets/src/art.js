// Ink-style caricatures. Everything draws in currentColor (ink) and var(--paper) (fill).
const P = 'var(--paper)';
const INK_FILTER = `
<filter id="ink" x="-5%" y="-5%" width="110%" height="110%">
  <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="7" result="n"/>
  <feDisplacementMap in="SourceGraphic" in2="n" scale="7" xChannelSelector="R" yChannelSelector="G"/>
</filter>`;

function rng(seed) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function splatter(n, x0, y0, w, h, seed = 3, rmax = 7) {
  const r = rng(seed); let s = '';
  for (let i = 0; i < n; i++) {
    const x = x0 + r() * w, y = y0 + r() * h, rx = 1.5 + r() * rmax, ry = rx * (0.5 + r() * 0.7);
    s += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${rx.toFixed(1)}" ry="${ry.toFixed(1)}" transform="rotate(${(r()*180).toFixed(0)} ${x.toFixed(1)} ${y.toFixed(1)})"/>`;
  }
  return `<g fill="currentColor">${s}</g>`;
}

// The founder. viewBox 0 0 600 720. o: {mouth: grin|oh|sleep|smirk, eyes: wide|closed|side, sweat, mug, hoodie}
function founder(o = {}) {
  const { mouth = 'grin', eyes = 'wide', sweat = false, mug = true, hoodie = true } = o;
  const st = 'stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" fill="none"';
  const stP = `stroke="${P}" stroke-linecap="round" stroke-linejoin="round" fill="none"`;
  let s = '';
  if (hoodie) {
    // hood behind the head, then the body
    s += `<path d="M150 470 C120 540 110 600 105 720 L495 720 C490 600 480 540 450 470 C420 520 370 540 300 540 C230 540 180 520 150 470 Z" fill="currentColor"/>`;
    s += `<path d="M222 520 C240 560 360 560 380 520" ${stP} stroke-width="7"/>`;
    s += `<path d="M262 548 C258 590 262 620 256 652" ${stP} stroke-width="7"/><rect x="249" y="650" width="14" height="24" rx="4" fill="${P}"/>`;
    s += `<path d="M342 548 C348 590 344 620 350 652" ${stP} stroke-width="7"/><rect x="343" y="650" width="14" height="24" rx="4" fill="${P}"/>`;
  }
  // ears
  s += `<path d="M178 282 C140 276 138 348 182 350" ${st} stroke-width="12" fill="${P}"/>`;
  s += `<path d="M448 282 C486 276 488 348 444 350" ${st} stroke-width="12" fill="${P}"/>`;
  // head
  s += `<path d="M172 250 C160 150 250 92 318 95 C408 100 462 168 456 262 C452 342 440 420 392 470 C350 508 262 512 216 472 C176 436 178 330 172 250 Z" fill="${P}" ${st.replace('fill="none"', '')} stroke-width="14"/>`;
  // earbud in the right ear
  s += `<circle cx="466" cy="310" r="10" fill="${P}" stroke="currentColor" stroke-width="6"/><path d="M468 320 L472 352" ${st} stroke-width="11"/><path d="M468 320 L472 352" ${stP} stroke-width="3"/>`;
  // hair: just-woke-up spikes
  s += `<path d="M162 262 L146 206 L112 196 L156 168 L132 118 L192 134 L196 72 L244 110 L268 46 L302 100 L344 42 L360 104 L414 64 L404 126 L468 112 L444 166 L490 182 L460 220 L470 262 C444 206 404 176 332 178 C266 180 216 204 162 262 Z" fill="currentColor"/>`;
  s += `<path d="M300 178 C296 208 286 226 270 238" ${st} stroke-width="10"/>`;
  // brows
  s += `<path d="M226 246 Q262 226 298 244" ${st} stroke-width="12"/><path d="M346 242 Q384 224 414 244" ${st} stroke-width="12"/>`;
  // eyes
  if (eyes === 'closed') {
    s += `<path d="M234 304 Q264 326 296 304" ${st} stroke-width="10"/><path d="M350 304 Q380 326 410 304" ${st} stroke-width="10"/>`;
  } else {
    const dx = eyes === 'side' ? 14 : 2;
    s += `<circle cx="265" cy="300" r="34" fill="${P}" stroke="currentColor" stroke-width="9"/><circle cx="380" cy="300" r="34" fill="${P}" stroke="currentColor" stroke-width="9"/>`;
    s += `<circle cx="${265 + dx}" cy="303" r="7" fill="currentColor"/><circle cx="${380 + dx}" cy="303" r="7" fill="currentColor"/>`;
  }
  // eye bags: three all-nighters deep
  s += `<path d="M236 348 Q266 366 298 346" ${st} stroke-width="6"/><path d="M244 362 Q268 374 292 360" ${st} stroke-width="4"/>`;
  s += `<path d="M350 346 Q382 366 412 346" ${st} stroke-width="6"/><path d="M357 360 Q382 374 405 360" ${st} stroke-width="4"/>`;
  // nose
  s += `<path d="M326 318 Q312 364 334 370" ${st} stroke-width="9"/>`;
  // mouth
  if (mouth === 'grin') {
    s += `<path d="M266 402 Q328 458 392 398 Z" fill="${P}" stroke="currentColor" stroke-width="10" stroke-linejoin="round"/>`;
    s += `<path d="M298 405 L300 426 M328 404 L329 434 M358 403 L357 427" ${st} stroke-width="6"/>`;
  } else if (mouth === 'oh') {
    s += `<ellipse cx="330" cy="420" rx="17" ry="23" fill="currentColor"/>`;
  } else if (mouth === 'sleep') {
    s += `<path d="M296 414 Q330 440 362 410" ${st} stroke-width="10"/><path d="M352 424 C358 446 350 462 352 478" ${st} stroke-width="6"/><circle cx="352" cy="484" r="7" fill="currentColor"/>`;
  } else {
    s += `<path d="M284 418 Q336 432 382 404" ${st} stroke-width="10"/>`;
  }
  // stubble
  s += splatter(26, 236, 430, 170, 60, 11, 3.2);
  if (sweat) s += `<path d="M440 180 C424 214 426 232 442 234 C458 232 458 214 440 180 Z" fill="${P}" stroke="currentColor" stroke-width="6"/><path d="M150 200 C138 226 140 240 152 241 C164 240 164 226 150 200 Z" fill="${P}" stroke="currentColor" stroke-width="5"/>`;
  if (mug) {
    // hand + SHIP IT mug, raised
    s += `<path d="M498 640 C470 640 452 610 470 596 C452 586 460 560 482 566 L540 566 C560 566 566 640 540 640 Z" fill="${P}" stroke="currentColor" stroke-width="8"/>`;
    s += `<path d="M466 520 L470 660 C470 676 560 676 560 660 L564 520 Z" fill="${P}" stroke="currentColor" stroke-width="10" stroke-linejoin="round"/>`;
    s += `<path d="M562 548 C600 548 600 616 560 616" ${st} stroke-width="10"/>`;
    s += `<text x="515" y="586" text-anchor="middle" font-family="Bangers, Impact, sans-serif" font-size="30" fill="currentColor">SHIP</text><text x="515" y="618" text-anchor="middle" font-family="Bangers, Impact, sans-serif" font-size="30" fill="currentColor">IT</text>`;
    s += `<path d="M492 504 C480 486 504 474 492 456 M520 500 C508 478 532 466 520 444 M546 504 C536 488 556 476 546 460" ${st} stroke-width="6"/>`;
  }
  return `<g filter="url(#ink)">${s}${splatter(18, 60, 40, 500, 480, 5, 6)}</g>`;
}

// The loop: a deadpan cardboard shipping box. viewBox 0 0 300 300.
function box(o = {}) {
  const { mouth = 'flat', prop = '' } = o;
  const st = 'stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"';
  let s = '';
  s += `<path d="M50 100 L150 70 L250 100 L150 130 Z" fill="${P}" ${st} stroke-width="9"/>`;
  s += `<path d="M50 100 L150 130 L150 280 L50 248 Z" fill="${P}" ${st} stroke-width="9"/>`;
  s += `<path d="M250 100 L150 130 L150 280 L250 248 Z" fill="${P}" ${st} stroke-width="9"/>`;
  s += `<path d="M50 100 L20 128 L120 160 L150 130 M250 100 L280 128 L180 160 L150 130" fill="${P}" ${st} stroke-width="8"/>`;
  s += `<path d="M100 85 L200 115" ${st} stroke-width="16"/>`; // tape
  s += `<path d="M64 170 L66 210 M64 170 L80 176" fill="none" ${st} stroke-width="5"/>`; // this-side-up arrow
  // face on the front-right side: ponytail-grade deadpan
  s += `<path d="M172 176 L196 170 M214 165 L238 158" ${st} stroke-width="8"/>`;
  s += `<circle cx="186" cy="190" r="6" fill="currentColor"/><circle cx="226" cy="179" r="6" fill="currentColor"/>`;
  s += mouth === 'smile'
    ? `<path d="M186 222 Q208 232 230 210" fill="none" ${st} stroke-width="7"/>`
    : `<path d="M188 224 L228 213" ${st} stroke-width="7"/>`;
  if (prop === 'clipboard') {
    s += `<rect x="6" y="160" width="74" height="96" rx="6" fill="${P}" ${st} stroke-width="7" transform="rotate(-8 43 208)"/>`;
    s += `<path d="M22 186 L62 180 M24 204 L64 198 M26 222 L56 218" ${st} stroke-width="5"/>`;
  } else if (prop === 'magnifier') {
    s += `<circle cx="40" cy="190" r="34" fill="${P}" fill-opacity="0.4" ${st} stroke-width="9"/><path d="M64 214 L100 248" ${st} stroke-width="14"/>`;
  }
  return `<g filter="url(#ink)">${s}</g>`;
}

function laptop(lines, x, y, w = 190) {
  const h = w * 0.62, st = 'stroke="currentColor" stroke-linejoin="round"';
  const t = lines.map((l, i) => `<text x="${x + 14}" y="${y + 30 + i * 22}" font-family="'JetBrains Mono', monospace" font-size="15" font-weight="700" fill="currentColor">${l}</text>`).join('');
  return `<g filter="url(#ink)"><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="8" fill="${P}" ${st} stroke-width="8"/>
    <path d="M${x - 22} ${y + h + 26} L${x + w + 22} ${y + h + 26} L${x + w} ${y + h} L${x} ${y + h} Z" fill="currentColor" ${st} stroke-width="8"/></g>${t}`;
}

function bubble(x, y, w, h, tx, ty, lines, size = 25) {
  const t = lines.map((l, i) => `<text x="${x + w / 2}" y="${y + h / 2 + (i - (lines.length - 1) / 2) * size * 1.15 + size * 0.35}" text-anchor="middle" font-family="'Patrick Hand', 'Comic Sans MS', cursive" font-size="${size}" fill="currentColor">${l}</text>`).join('');
  const cx = x + w / 2;
  return `<g filter="url(#ink)"><path d="M${cx - 18} ${y + h - 6} L${tx} ${ty} L${cx + 14} ${y + h - 6}" fill="${P}" stroke="currentColor" stroke-width="6" stroke-linejoin="round"/>
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${h / 2.4}" fill="${P}" stroke="currentColor" stroke-width="6"/>
    <path d="M${cx - 16} ${y + h - 3} L${cx + 12} ${y + h - 3}" stroke="${P}" stroke-width="9"/></g>${t}`;
}

function caption(x, y, text, w) {
  return `<rect x="${x}" y="${y}" width="${w}" height="38" fill="#f2c94c" stroke="currentColor" stroke-width="5"/>
    <text x="${x + 12}" y="${y + 28}" font-family="Bangers, Impact, sans-serif" font-size="25" letter-spacing="1" fill="#111">${text}</text>`;
}
