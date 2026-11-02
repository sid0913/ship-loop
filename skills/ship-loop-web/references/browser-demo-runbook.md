# Browser demo runbook

How to run, capture and record a web app during `/ship-loop-web`. Values in
`<angle brackets>` come from `.claude/ship-loop.json` (`web.dev_command`, `web.port`).

## Dev server

Start it with its output going to a file, never through `head`:

```bash
PORT=<PORT> <web.dev_command> > /tmp/dev-<PORT>.log 2>&1 &
until curl -sf localhost:<PORT> >/dev/null; do sleep 1; done
```

Piping a long-running server through `head` kills it with SIGPIPE when the pipe closes,
and that looks like the server crashing on startup.

Before you wait on a slow process, check whether it is stuck: `ps -o etime=,%cpu= -p <pid>`.
At 0.0% CPU with no new output for minutes, it is dead. Kill it.

## Real recording (preferred)

If Playwright is available in the project (`npx playwright --version`), record a real
video:

```js
// demo.mjs (scratch file; do not commit)
import { chromium } from "playwright";
const browser = await chromium.launch();
for (const [name, viewport] of Object.entries({
  mobile: { width: 375, height: 812 },
  tablet: { width: 768, height: 1024 },
  desktop: { width: 1280, height: 720 },
})) {
  for (const colorScheme of ["light", "dark"]) {
    const ctx = await browser.newContext({ viewport, colorScheme,
      recordVideo: { dir: `/tmp/demo/${name}-${colorScheme}`, size: viewport } });
    const page = await ctx.newPage();
    await page.goto("http://localhost:<PORT>/<route>");
    // ...drive each state the change touches...
    await ctx.close();                     // writes the .webm
  }
}
await browser.close();
```

`colorScheme` only works if the app follows `prefers-color-scheme`. If dark mode is a
class toggle, add the class with `page.evaluate` (for example
`document.documentElement.classList.add("dark")`).

Join the clips and convert to MP4:

```bash
ls /tmp/demo/*/*.webm | sed "s/^/file '/; s/$/'/" > /tmp/demo/list.txt
ffmpeg -y -f concat -safe 0 -i /tmp/demo/list.txt \
  -vf "scale=900:-2:flags=lanczos,format=yuv420p" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart /tmp/demo.mp4
```

## Screenshot slideshow (fallback)

gstack's `browse` skill takes screenshots but cannot record video. Drive every state with
`browse`, take one PNG per state (`$B screenshot`; `$B responsive` captures mobile, tablet
and desktop in one call; `$B viewport` sets one size), name them `g1.png`, `g2.png`, ...
in play order, then:

```bash
ffmpeg -y -framerate 1/2.2 -i /tmp/g%d.png \
  -vf "scale=900:-2:flags=lanczos,format=yuv420p" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart /tmp/demo.mp4
```

Each frame shows for about 2.2 seconds.

## Look at what you captured

Open each capture with the Read tool and check it. A capture you did not look at is not
QA. Also read the browser console for errors in every state.

Font and Dynamic Type sizes measured in a browser have been wrong before, always too
optimistic. If the ticket depends on exact text size on phones, check on a real device or
a simulator and say so in **Not checked** if you could not.

## Repo hygiene in a worktree

- `.env*` files are gitignored and missing from fresh worktrees. Copy them in.
- Never symlink `node_modules` into a worktree. `git worktree remove --force` follows the
  link and deletes the real folder. Install dependencies in the worktree instead.
- Never `git add -A`; add files by name, so scratch files like `demo.mjs` stay out.
- Demo skills that record from a fixed branch (for example an old `develop`) film stale
  product. Record from the worktree's branch.
