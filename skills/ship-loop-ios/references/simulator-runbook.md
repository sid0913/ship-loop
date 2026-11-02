# Simulator runbook

A working setup for building, driving and recording an iOS app in the Simulator during
`/ship-loop-ios`. Every item here was learned the hard way. Do not work it out again.
Items marked **(RN/Expo)** apply only to React Native or Expo apps.

Values in `<angle brackets>` come from `.claude/ship-loop.json`
(`ios.workspace`, `ios.scheme`, `ios.bundle_id`).

## Build once, not per worktree

Most ticket changes are pure JS, so one Debug build serves every branch. Only the Metro
bundle differs.

```bash
xcodebuild -workspace <ios.workspace> -scheme <ios.scheme> -configuration Debug \
  -sdk iphonesimulator -destination "id=<UDID>" -derivedDataPath <path> build
```

- Two `xcodebuild` runs at once in different worktrees corrupt each other through Xcode's
  shared build cache and produce empty `.app` bundles. Build one at a time.
- Rebuild when native code changes: a native dependency, config plugin, entitlement, or
  `app.json` `ios`/`plugins` (`npx expo prebuild` first). A green Metro bundle proves
  nothing about native config.
- **(RN/Expo)** Do not use `npx expo run:ios --device <UDID>` with a simulator UDID. It
  treats it as a physical device and fails on code signing.

## Point the app at your Metro port (RN/Expo)

A plain RN Debug build without `expo-dev-client` has port 8081 baked in, so a
`<scheme>://expo-development-client/?url=...` link does nothing. Set the port per device:

```bash
xcrun simctl spawn <UDID> defaults write <ios.bundle_id> RCT_jsLocation "localhost:<PORT>"
xcrun simctl launch <UDID> <ios.bundle_id>
```

`RCT_jsLocation` is stored per device. Every run must overwrite what the last run left.

Start Metro with its output going to a file, never through `head`:
`npx expo start --port <PORT> > /tmp/metro-<PORT>.log 2>&1 &`, then poll
`curl -s localhost:<PORT>/status`. Piping through `head` kills Metro with SIGPIPE, and that
looks like a Metro crash.

## Record

```bash
xcrun simctl io <UDID> recordVideo --codec h264 -f /tmp/demo.mov &   # note the PID
# ...drive the app...
kill -INT <PID>
ffmpeg -y -i /tmp/demo.mov -vf "scale=760:-2:flags=lanczos,format=yuv420p" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart /tmp/demo.mp4
```

Always pass `<UDID>` rather than `booted` when more than one device may be running.

Dark mode: `xcrun simctl ui <UDID> appearance dark` (or `light`).
Dynamic Type: `xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large`.
Measure text size on the simulator or a device. Sizes measured in a browser have been
wrong 3 out of 3 times, always too optimistic.

## Drive the app with Maestro

AppleScript/System Events returns `-1743`, and posted `CGEvent`s are silently dropped.
Both are dead ends, and no privacy setting fixes them. Maestro drives the simulator
directly.

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk          # Homebrew openjdk is keg-only
export PATH="$JAVA_HOME/bin:$HOME/.maestro/bin:$PATH"
maestro --device <UDID> test flow.yaml
```

- **Read the screen with `accessibilityText`, not `text`.** React Native puts content in
  accessibility labels. Searching the hierarchy for `text` returns only status-bar items,
  which looks exactly like a blank app. For a quick "is it blank" check, a screenshot is
  more honest.
- There is no `wait` command; a flow with `wait` fails to parse. Use
  `waitForAnimationToEnd: {timeout: N}` to let the screen settle and
  `extendedWaitUntil: {visible: {text: "..."}, timeout: N}` to wait for an element.
- System dialogs need `optional: true`, or the flow fails when the dialog does not appear:
  ```yaml
  - tapOn: {text: "Not Now", optional: true}   # Save Password
  - tapOn: {text: "Close",   optional: true}   # stray Apple Account sheet
  ```
- `hideKeyboard` can fail on secure inputs. Tap the submit button directly instead.
- Sign-in survives app restarts through the Keychain.

## Wedged or just slow?

`ps -o etime=,%cpu= -p <pid>`. A Maestro or `xcodebuild` process at 0.0% CPU that has
written no new files in 20 minutes is dead, not working. Kill it. One once stayed stuck
for 8 hours and blocked the queue.

Shut down simulators you booted: `xcrun simctl shutdown <UDID>`.

## Repo hygiene in a worktree

- `.env` is gitignored and missing from fresh worktrees. Copy it in, or the app fails
  with a config error.
- Never symlink `node_modules` into a worktree. `git worktree remove --force` follows the
  link and deletes the real folder. Run `npm ci` instead. Recovery:
  `rm -f node_modules && npm ci`.
- **(Expo)** If the project has no lint config, `npx expo lint` creates one and rewrites
  `package.json` and the lockfile. Do not run it. Never `git add -A`; add files by name.
- A test that imports a module which pulls in `react-native` or `expo-*` will not parse
  under vitest. Mock those modules the way the existing tests do.
- **(RN)** If `maxFontSizeMultiplier` does not stop a label from clipping, clamp the font
  size explicitly. Do not "simplify" an explicit clamp back to the prop.
