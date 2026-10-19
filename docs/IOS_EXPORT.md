# iOS export (Mac → iPhone 16)

> **⚠️ Nothing in this guide has been tested.** No iOS build has been made, signed, installed or run for this project. Every step comes from the Godot 4.7 / Xcode workflow and has not been verified on a real Mac or iPhone. Expect to adjust details (menu names, Xcode versions, signing errors) when you do it for the first time.

## What you need

- A Mac with an Xcode release that supports iOS 26.
- An Apple ID. A free account can install on your own device, but the app expires after 7 days. A paid Apple Developer Program membership is needed for TestFlight and the App Store.
- An iPhone 16 with iOS 26 and a USB-C cable.
- **Godot 4.7.2** for macOS. It must match the version this project uses exactly, because export templates only work with the same version.

## 1. Install the tools

1. Install **Xcode** from the Mac App Store and open it once. Accept the license and let it install components.
2. In Terminal, run `xcode-select --install` (command-line tools), then `sudo xcode-select -s /Applications/Xcode.app`.
3. In Xcode → **Settings → Accounts**, add your Apple ID. Note your **Team ID**, a 10-character code. Paid accounts can also find it at developer.apple.com → Membership.
4. Download **Godot 4.7.2 (macOS, universal)** from godotengine.org and move it to Applications.
5. Open Godot → **Editor → Manage Export Templates → Download and Install**. Make sure it installs the **4.7.2** templates.

## 2. Get the project

1. Clone or copy the repository to the Mac. Line endings are LF (`.gitattributes`), so no conversion is needed.
2. In Godot, choose **Import**, select `project.godot` and open it. The first open imports every resource, which takes a minute.
3. Optional check: in Terminal, `godot --headless --path . -s res://tests/run_tests.gd` should report 0 failures. Use the `godot` binary inside `Godot.app/Contents/MacOS/`.

## 3. Create the iOS export preset

**Project → Export… → Add… → iOS**, then set:

| Setting | Value |
|---|---|
| Application → App Store Team ID | your 10-character Team ID |
| Application → Bundle Identifier | a reverse-DNS id you own, e.g. `com.yourname.shogunslaststand` (letters, digits, dots, hyphens only) |
| Application → Short Version / Version | `0.6.0` / `1` |
| Application → Export Method (Debug) | Development |
| Application → Export Method (Release) | App Store (or Ad Hoc) |
| Application → Targeted Device Family | iPhone (and iPad if wanted) |
| Icons | Set at least the 1024×1024 App Store icon (a PNG with no transparency). The project has **no icon yet**, so make a placeholder. If Godot reports missing required icons, set them here. |

Already set in the project, nothing to do:
- **Landscape orientation** (Project Settings → Display → Window → Handheld → Orientation = Landscape, the default).
- **Compatibility renderer** (OpenGL ES 3 / ANGLE-Metal), and the 1920×1080 canvas with `expand` aspect.

## 4. Export to Xcode

1. In the Export dialog, select the iOS preset and choose **Export Project…**. Pick an empty folder such as `builds/ios/` (it's ignored by git). Use **Export With Debug** for the first device test.
2. Godot writes an Xcode project (`Shogun's Last Stand.xcodeproj`) plus the game data (`.pck`).

> One-click deploy also exists (the iOS icon at the top right of the editor while a device is connected), but the Xcode route makes signing errors visible, so use it first.

## 5. Sign in Xcode

1. Open the `.xcodeproj` in Xcode.
2. Select the project → target → **Signing & Capabilities**:
   - Tick **Automatically manage signing**.
   - **Team**: choose your team.
   - **Bundle Identifier**: must match the export preset.
   - If Xcode says the identifier is unavailable, change it, both here and in the preset, to something unique.
3. Fix any red signing errors before continuing. They're almost always a team, bundle ID or device registration issue.

## 6. Install on the iPhone 16

1. Connect the phone with USB and unlock it. Tap **Trust This Computer**.
2. On the phone, go to **Settings → Privacy & Security → Developer Mode → On** and restart when asked. The option appears only after Xcode has seen the device once.
3. In Xcode, choose the iPhone as the run destination (top bar) and press **Run** (⌘R).
4. On the first launch with a free account, go to **Settings → General → VPN & Device Management**, tap your Apple ID and choose **Trust**. Then run again.

## 7. What to test on the device

Use [SMOKE_TEST.md](SMOKE_TEST.md) as the base (touch controls appear automatically on iOS: Settings → Touch controls → Auto), plus these device-only checks:

- [ ] **Safe area:** in both landscape directions, nothing important is under the Dynamic Island or the home indicator. That covers the HUD bars, the pause button, the joystick and the action buttons.
- [ ] **Touch targets:** every button is easy to hit with a thumb. They're designed for at least 44 pt, about 121 canvas units.
- [ ] **Multitouch:** hold the joystick and tap Attack with your other thumb. You move and attack at the same time, and lifting one finger doesn't cancel the other.
- [ ] **Left-handed layout** and **UI scale** (90–140%) work and stay inside the safe area.
- [ ] **Vibration** when the samurai is hit, and none after turning Vibration off.
- [ ] **Frame rate:** steady 60 FPS in wave 3 with several allies. Check the FPS gauge in Xcode's Debug Navigator. A headless desktop stress test (30 enemies + 12 allies) used about 2.5 ms of CPU per frame without rendering; the phone hasn't been measured.
- [ ] **Heat and battery:** after 10–15 minutes of play, the phone isn't uncomfortably hot and the frame rate hasn't dropped.
- [ ] **Backgrounding:** swipe home mid-battle and come back. The battle should be paused with the pause menu open.
- [ ] **Saves:** buy an upgrade, force-quit the app from the app switcher and reopen it. Gold and upgrades persist. Settings persist too.
- [ ] **Audio:** the game has no sound assets yet, so the volume sliders have nothing audible to control. This is expected.

## Troubleshooting

- **"No matching provisioning profiles found"**: set the Team in Signing & Capabilities and keep automatic signing on.
- **Black screen or crash at launch**: run from Xcode and read the console. The usual cause is mismatched export templates, so reinstall the exact 4.7.2 templates.
- **Wrong orientation**: check Project Settings → Display → Window → Handheld → Orientation is Landscape, then export again.
