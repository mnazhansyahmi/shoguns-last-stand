# Smoke test (about 15 minutes)

A manual pass that covers every MVP acceptance criterion in [MASTER_PROMPT.md](MASTER_PROMPT.md) section 18. Each step lists the criteria it covers in brackets, for example **[#2]**.

Tick each box as you go. If a step fails, note what you saw and stop: later steps often depend on earlier ones.

**Setup (1 min).** Close the game. If you want a clean run, back up and delete `%APPDATA%\Godot\app_userdata\Shogun's Last Stand\savegame.json` (and `.bak`). Otherwise, your progress is used as is.

## 1. Automated checks — 2 min

- [ ] **[#13]** Run the tests. The last line should read `N tests, N passed, 0 failed`.

  ```bash
  godot_console --headless --path . -s res://tests/run_tests.gd
  ```

- [/ ] **[#1]** Open the project in the Godot 4.7.2 editor. The Output panel shows no red errors, and no script shows a parse error. (Headless alternative: `godot_console --headless --import` prints no errors.)

## 2. Main menu — 1 min

- [/ ] **[#11]** Press F5. The window opens and the main menu shows the title, Gold/Level, and Start, Upgrades, Settings and Quit. The red bar sits above the title, not over it.
- [/ ] Note the gold value here: _630_____

## 3. Fight, keyboard — 4 min (Start)

- [/ ] **[#2]** A/D move the samurai and the sprite turns to face the way you walk. J three times plays a 3-hit combo, K a heavy attack, L a dash (the cooldown shows in the top-left "Dash" bar), and U fires the Spirit Slash.
- [/ ] **[#3]** After "Wave 1" appears, Hollow Soldiers come out of the purple portal on the right, walk left and attack you. You flash white and get knocked back.
- [/ ] **[#6]** The "Spirit" bar fills by about 5 per second. Press **1**: an Ashigaru appears near the gate and the bar drops by 30. Press **2** right away with less than 45 energy: "Not enough Spirit Energy" appears.
- [/ ] **[#5]** With 45 or more energy, press **2**: a Yumi Archer appears and shoots arrows at enemies. Summoned allies walk to enemies and fight on their own.
- [/ ] **[#4]** Walk to the far right (or stand still) and let a soldier reach the gate. The gate shakes and flashes, and both its bar over the gate and the HUD "Gate" bar go down.
- [/ ] **[#7]** Keep fighting:
  - "Wave 1 cleared" appears, then a 5 s countdown, then "Wave 2" (6 soldiers).
  - Then "Final Wave" (6 soldiers + 1 Oni Brute, big and red, near the end).
  - "Enemies remaining" counts down in each wave.
- [/ ] **[#8 victory]** After the Oni Brute dies, the VICTORY screen appears with enemies defeated, gold and XP earned, and "Progress saved."

## 4. Progression — 2 min

- [/ ] **[#9]** Press **Upgrades**. Gold is higher than the value you noted. Buy an affordable upgrade: gold drops and the level goes up. Try one you can't afford (its cost is shown in red): you get "Not enough gold: …".
- [/ ] **[#9]** Buy **Samurai Max HP** if you can afford it, then press **Battle**. The HUD shows "Samurai 220 / 220", or higher if you bought more levels.
- [/ ] **[#8 defeat]** In this battle, stand far right and let enemies destroy the gate (it takes a while; F1 spawns extra soldiers in editor/debug builds). DEFEAT appears with partial rewards (50% of enemy rewards). Press **Main Menu**.

## 5. Persistence — 1 min

- [/11:21 AM 10/19/2026 ] **[#10]** Note the gold on the main menu, then **Quit**. Press F5 again. Gold, level and upgrade levels are the same as before you quit.

## 6. Simulated mobile controls — 3 min

- [/ ] **[#12]** Main menu → **Settings** → Touch controls → **Always** → **Back** → **Start**:
  - A joystick appears bottom-left, Attack/Heavy/Dash/Spirit bottom-right, the summons bottom-center and the pause button top-right.
  - They're semi-transparent.
  - The gate, units and portal are drawn above them, not under them.
- [/ ] **[#12]** Using the mouse:
  - **Joystick:** drag it left or right and the samurai moves.
  - **Attack:** click it and the samurai attacks; the button turns fully opaque while held.
  - **Dash:** click it and a shrinking pie with seconds left appears on the button.
  - **Ashigaru:** with enough energy, an Ashigaru is summoned. Without enough, the button is crossed out with "need 30".
- [/ ] Click **II**: the game pauses and the pause menu appears. Choose **Settings** → **Left-handed: On**: the joystick and buttons swap sides immediately. Press **Back**, then **Resume**.
- [ ] (Touchscreen only) Hold the joystick and tap Attack with a second finger: you move and attack at the same time.
- [/ ] Afterwards, set Touch controls back to **Auto** if you don't want them on Windows.

## Phase 9: art (code-drawn ink style)

- [ ] **Title screen:** a bamboo and misty-mountain backdrop at dusk, and the samurai on a rock with their head against the moon, scarf streaming. Bamboo leaves drift across. The title is gold serif text with a crimson brush stroke under it.
- [ ] **Menus** (stage select, upgrades, pause, settings, results) use charcoal panels, parchment text and gold borders. Hovered and focused buttons get a bright gold border. Settings toggles light up gold when on.
- [ ] **Battle backdrop:** sky, moon, mountains, a pagoda on the hills, bamboo groves at both sides and drifting fog. Fighters are dark against pale mist and easy to see.
- [ ] **Characters:** each one is recognisable at a glance:
  - The samurai has a red scarf and a red ring at their feet.
  - Ashigaru have gold hats and spears.
  - Archers have teal headbands and tall bows.
  - Hollow Soldiers are hunched, with glowing violet eyes.
  - The Oni Brute is huge, with horns, a club and an ember glow.
- [ ] **Animation:** units breathe when idle and stride when running. Combo hits go downward cut, rising cut, then thrust. A hit lightens the unit briefly (about 0.08 s) but it stays a dark silhouette, and hurt units recoil. Dead units fall backward and dissolve into ink. Summoned allies rise out of an ink splash; enemies step out of violet smoke.
- [ ] **Effects:** attacks leave crimson-edged slash arcs, and hits throw sparks (gold on enemies, red on defenders). The Spirit Slash is a glowing blue crescent. The Oni's slam sends a ground ring, and a dash leaves pale afterimages.
- [ ] **Gate:** lanterns flicker. Cracks appear at about 2/3 and 1/3 health, and the lanterns go out when it falls.
- [ ] **Zoomed view:** units are about 1.5x bigger than before. The camera follows the samurai, with far layers moving slower than near ones. Walk right: a "Gate NN%" tab appears at the left edge and pulses when enemies reach the gate. Walk left: an "N incoming" tab appears at the right edge ("Oni Brute!" when one is coming).
- [ ] **Health bars:** enemies at full health show no bar, and the first hit makes a short red bar appear. When several hurt enemies stand together, their bars stack instead of overlapping. Damage numbers are large, with a dark outline.
- [ ] **Atmosphere:** each stage has its own sunset (gold and crimson, rose, olive-gold, blood red, an eclipse). Tall pampas sways in waves, and the wind visibly strengthens and eases over about half a minute. Red leaves and petals drift past behind and in front of the fighters. Faint light rays cross the fog and slowly breathe. Every fighter has a thin warm rim on the upper-right edge. Fighters stay easy to see against the bright sky; the main menu and stage select show the sunset without leaves or grass in front of the buttons.
- [ ] **Characters alive:** every character has torn cloth that flutters (samurai's trailing strip, ashigaru tabard, archer cloak, healer and onmyoji hems, guardian tabard, hatamoto's flag, Oni's hide strips) and one glowing detail that flickers. The samurai stands calm, the Oni heaves and stomps, the healer sways gently. A crowd of Hollow Soldiers is not a row of clones: heads, sizes, heights, walking speeds and spacing differ, and now and then one glances aside or stumbles. Allies are a lighter blue-slate than the enemies and are drawn side by side in their own lanes, so a group does not pile into one dark blob. An enemy's health bar disappears 2 s after it was last hit. Leaves never cross the HUD or the touch buttons.
- [ ] **Summon bar (phone):** with touch controls on at a phone-shaped window (e.g. 2340x1080 or 1278x590) and every ally unlocked, six round summon buttons sit in one row between the joystick and the buttons on the right, each in its ally's colour with the name, cost and a cooldown pie; the Ultimate button is beside the skill buttons. With fewer allies unlocked, only those buttons show. With UI scale at maximum on a narrow window they wrap to two rows and still do not touch the other controls. Keys 1-6 summon in the same order.
- [ ] **Allies:** in a fresh save only the Ashigaru and Archer can be summoned. After clearing Stage 1 the Shrine Healer joins (key 3): she walks to a hurt ally, waves her wand and a green "+28" rises. After Stage 2 the Spear Guardian (a big shield and long spear; enemies near her turn on her), after Stage 3 the Onmyoji (a talisman burst that hits a group), after Stage 4 the Hatamoto (a banner on his back, a wide naginata sweep). The result screen says "New ally: ..." the first time. In the upgrade menu the new allies' upgrades say "Unlocks after ..." until then.
- [ ] **Ultimate:** the Ultimate ring round the samurai's portrait (HUD) fills as you hit enemies, as allies hit them (slower) and as you take damage. When full it glows gold, pulses and says READY, and the touch button (Spirit slash column, left of it) pulses. Press I (or the button): the samurai raises his glowing blade and cannot be hurt, then a big ink brush stroke crosses the screen, the game freezes briefly, and every enemy in view is hit (soldiers die, an Oni survives hurt). The meter is empty afterwards. In a debug build F3 fills the meter.
- [ ] **Phone:** with touch controls on (Settings → Always) at a phone-shaped window (e.g. 1278×590), the fight sits above the controls and the samurai is easy to find.

## Result

| # | Criterion | Pass / Fail | Notes |
|---|---|---|---|
| 1 | Opens without parsing errors | | |
| 2 | Player can move and attack | | |
| 3 | Enemies spawn, move and attack | | |
| 4 | Gate takes damage | | |
| 5 | Allies can be summoned | | |
| 6 | Spirit Energy regenerates and is consumed | | |
| 7 | All three waves function | | |
| 8 | Victory and defeat conditions work | | |
| 9 | Upgrades can be purchased | | |
| 10 | Save data persists between sessions | | |
| 11 | The game can be played on Windows | | |
| 12 | HUD supports simulated mobile controls | | |
| 13 | Automated tests pass | | |
- [ ] **Stage 5 boss:** the final wave brings The Fallen Daimyo (a tall, torn lord with a glowing green-yellow blade) and a few Hollow Soldiers. A bar with his name sits at the top of the screen, with ticks at one third and two thirds. Every attack warns first: the sweep (blade coiled high, an oval on the ground), the slam (blade overhead, a ring around him), and in phase 2 the leap (a ring where you stand) and the cursed wave (a strip along the ground). At about 66% and 33% he roars, untouchable, with a shockwave and a banner, and gets faster and brighter; in phase 3 he calls three Hollow Soldiers, each marked by a ring. He ignores hits (no stagger). The stage ends only when he dies, and his soldiers fall with him.
- [ ] **Main menu and stage select:** the main menu has six buttons of the same shape, a dark panel with a thin gold border and gold serif text (Continue, Stages, Upgrades, Settings, Credits, Quit), that slide in one after another. Hovering or focusing one brightens its border, fades in a soft gold glow around it and plays a soft katana slash. Continue says "Start" on a new save and otherwise names the stage it will play under it, inside the panel and clear of the label ("Stage 3 - Misty Grove"); with every stage cleared it replays the last stage you played. Stages opens cards for the five stages: each has a picture of its own sky, its number, name and a short line; a cleared stage has a gold check; a locked one a padlock and "Clear <previous stage>"; stage 5 a small boss crest. Focusing or tapping a card shows its waves, enemies and first-clear and replay gold in the side panel; Enter, the Play button or a double click starts it. It looks right on a desktop window and a phone-shaped one.
- [ ] **Keyboard HUD:** top left is two blocks only: the vitals (a round portrait medallion of the samurai with the Ultimate ring round it; his health as a katana blade coming out of it, which leaves a pale ghost of lost health that drains away after a hit and glows red at 30% or less; a flowing blue Spirit bar with an orb and its number; a small gate icon with a short Gate bar) and one row of six round icons (Dash, Heavy, Slash, Bow, War Cry, Allies stance), each with its key letter. A ready skill glows softly and has no text; using it darkens the icon with a shrinking sweep and the seconds left. A locked Bow or War Cry is dimmed with a small padlock only; hovering it shows "Clear stage N" as a tooltip and clicking it shows that line as a message. The gate tab at the left edge appears only while the gate is under attack or was damaged in the last 3 seconds. On a phone the icon row is hidden (the touch buttons show cooldowns and the stance).
- [ ] **Army and stance:** the HUD shows "Allies 0/6" at the start of a new game and the cap grows by one for each stage cleared (up to 11); the Command upgrade in the shop adds up to 3 more. The stance is an icon in the HUD's skill row (a sword for CHARGE, a shield for HOLD, key F); pressing F (or tapping the Allies button above the summon bar) switches to HOLD and back. Charging allies run out to meet the enemies and stop at the middle of the field; holding allies stay by the gate.
- [ ] **Bow and War Cry:** after clearing stage 1, E (or the Bow button, bottom row of the top skill pair) shoots an arrow that flies across the field; after stage 2, Q (or the War Cry button) makes nearby allies glow gold and hit harder and faster for 8 s (25 s cooldown). Before the unlock the key shows "unlocks when you clear Stage N" and the buttons are not shown. On a phone all the buttons stay on screen, none overlaps another, and the summon bar is still centred.
- [ ] **Music and credits:** the main menu plays a calm track; the stage select another; a battle its own track, and when the Fallen Daimyo arrives the music crossfades to the intense one. The Music volume slider (Settings) changes it live. Swings, hits, enemies falling (zombie groans, an Oni's lower), the gate being hit, button clicks and the summon bell sound recorded, not synthetic. An Oni and the boss roar when they arrive and slam the ground; the fireball explodes; the boss fight has a quiet eerie drone under its music. Main menu, Credits shows only the creator line and the music credit (Free Music : MOMIZizm MUSiC); Back (or Escape) returns.
