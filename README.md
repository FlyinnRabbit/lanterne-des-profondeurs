# Lanterne des Profondeurs (Lantern of the Depths)

<p align="center"><img src="docs/banner.jpg" width="900" alt="The hero beneath the Lantern, surrounded by the guardians of the depths"></p>

**English** · [Français](README.fr.md) · [Español](README.es.md) · [Deutsch](README.de.md)

A 2D roguelite metroidvania for **Godot 4.3+**, inspired by Hollow Knight: dark caves, needle
combat, pogo jumps on enemies, healing with soul, resting benches and ten bosses.
Everything is drawn in code — there is not a single image asset in the game.

**Play in your browser: https://flyinnrabbit.github.io/lanterne-des-profondeurs/**

## Trailer

<p align="center"><a href="docs/video/trailer_en.mp4"><img src="docs/video/preview.gif" width="820" alt="Trailer preview: click to watch"></a></p>

<p align="center"><b><a href="docs/video/trailer_en.mp4">▶ Watch the trailer (80 s)</a></b> · <a href="docs/booklet/booklet_en.pdf">Booklet (PDF, 10 pages)</a></p>

## The goal

The Lantern of the Depths once lit every tier down to the bottom of the world. Its flame has gone out.
From the **Sanctuary**, take the lift down tier after tier, defeat the guardian of each tier, and
**rekindle the Lantern**, then climb back alive. Every fall sends you back to the Sanctuary: your shade
keeps the shards you dropped where you fell, and the lift remembers how deep you went.

<p align="center"><img src="docs/screenshots/surface.jpg" width="820" alt="The light finally reaches the surface"></p>

## At a glance

- **9 biomes**; levels are generated anew on every descent, with grottos, three-storey strata and winches
- **10 bosses**: 6 tier guardians and 4 final bosses, each with a phase 2 and its own music
- **Combat**: 3-hit combos, charged whirl, air combo, pogo, plunge attack, dash thrust, parry (a perfect parry makes your next hit critical), soul blade, ultimate
- **5 weapons** upgraded by the smith (the Twin Claws are worn on both hands), **21 charms**
- **The Sanctuary**: merchant, arsenal, smith, cartographer, seamstress (53 cosmetics), elder and four yearly festivals
- **4 difficulties** plus a one-life mode, curses, a **Daily Descent** with an online leaderboard, and a **Boss Rush**
- English, French, Spanish and German; keyboard and Xbox controller; browser, Windows, macOS, Linux and Steam Deck; automatic updates
- The **Scriptorium** records everything: statistics, records, bestiary, guardians and charms
- Everything drawn in code; original music and sounds

## Screenshots

| | |
|---|---|
| ![The Sanctuary and its inhabitants](docs/screenshots/sanctuary.jpg) | ![The lift going down to the next tier](docs/screenshots/lift_descent.jpg) |
| ![A perfect parry in the Ossuary, on Nightmare](docs/screenshots/nightmare_parry.jpg) | ![The Lantern rekindled](docs/screenshots/lantern_rekindled.jpg) |
| ![The Fungal Gardens](docs/screenshots/fungal_gardens.jpg) | ![The Blazing Forge](docs/screenshots/blazing_forge.jpg) |
| ![The Crystal Mines](docs/screenshots/crystal_mines.jpg) | ![The Frozen Abyss](docs/screenshots/frozen_abyss.jpg) |
| ![The Silent Library](docs/screenshots/silent_library.jpg) | ![The Humming Hive](docs/screenshots/humming_hive.jpg) |
| ![The Cerberus of the Depths](docs/screenshots/boss_cerberus.jpg) | ![The Bone Colossus](docs/screenshots/boss_bone_colossus.jpg) |
| ![The Swarm Queen](docs/screenshots/boss_swarm_queen.jpg) | ![Combat effects and projectiles](docs/screenshots/combat_effects.jpg) |
| ![The map, a lost parchment with a legend](docs/screenshots/map.jpg) | ![The arsenal in the Sanctuary](docs/screenshots/arsenal.jpg) |
| ![The seamstress in the Sanctuary](docs/screenshots/seamstress.jpg) | ![The wardrobe](docs/screenshots/wardrobe.jpg) |
| ![A few outfits](docs/screenshots/outfits.jpg) | ![Ultimate styles](docs/screenshots/ultimates.jpg) |

**Festivals in the Sanctuary** (Valentine's Day, Easter, Vigil of Shadows, Christmas)

![The four festivals](docs/screenshots/festivals.jpg)

**Loading screens** (launch, entering a shop, the elevator)

| | | |
|---|---|---|
| ![Launch](docs/screenshots/loading_launch.jpg) | ![Entering a shop](docs/screenshots/loading_shop.jpg) | ![The elevator](docs/screenshots/loading_lift.jpg) |

## Download and play

The game is available in French, English, Spanish and German.

### Browser (PC, Xbox, tablet)
**https://flyinnrabbit.github.io/lanterne-des-profondeurs/** — updated automatically on every push.
Keyboard, mouse and gamepad all work; saves are kept in the browser.
- **Xbox Series**: open **Microsoft Edge**, go to the address above, then switch to full screen.
- The first load downloads about 55 MB.
- In the browser, key names follow the QWERTY layout by default: pick AZERTY in
  **Controls → Keyboard** if needed.

### Windows
Latest version: **Releases** tab → `LanterneDesProfondeurs_Windows.zip`, unzip it, run
`LanterneDesProfondeurs.exe`. The exe is not signed, so Windows SmartScreen may show
"Windows protected your PC" → *More info* → *Run anyway*.

### macOS (Intel and Apple Silicon)
1. Download `LanterneDesProfondeurs_macOS.zip` from the Release, unzip it and drag
   **Lanterne des Profondeurs** into the Applications folder.
2. The app is not notarised by Apple (that needs a paid developer account), so macOS blocks it on
   first launch:
   - **right-click (or Ctrl + click) the app → Open**, then **Open** in the dialog;
   - on **macOS 15 (Sequoia)** and later: launch the app once, then **System Settings →
     Privacy & Security** → at the bottom, **"Open Anyway"**;
   - if macOS says "the app is damaged", open **Terminal** and type:
     `xattr -cr "/Applications/Lanterne des Profondeurs.app"`, then launch it again.
3. After that the game starts normally. Xbox and PlayStation controllers work.
   Saves: `~/Library/Application Support/Godot/app_userdata/Lanterne des Profondeurs/`.

### Linux and Steam Deck
In the Releases: `LanterneDesProfondeurs_Linux_SteamDeck.tar.gz` (Linux x86_64).

**Linux**: extract the archive, then run `./LanterneDesProfondeurs.x86_64`
(if needed: right-click → Properties → "Allow executing", or `chmod +x`).

**Steam Deck**:
1. Switch to **Desktop Mode** (Steam button → Power → Switch to Desktop).
2. Download the archive from the Releases page with the browser and extract it
   (right-click → *Extract archive here*), for example into `~/Games/Lanterne`.
3. Open Steam in Desktop Mode → *Games* → **Add a Non-Steam Game to My Library**
   → *Browse* → pick `LanterneDesProfondeurs.x86_64` → *Add Selected Programs*.
4. Go back to **Gaming Mode**: the game is in the library (*Non-Steam* tab).
   It starts in full screen, the Deck controls work straight away
   (A jump, X attack, RT dash, LB parry, Y ultimate, B heal) and the 16:10 screen is filled.
   The supplied `LanterneDesProfondeurs.png` icon can be chosen in the shortcut's properties.

### Portable version
`LanterneDesProfondeurs_Windows_Portable.zip` / `LanterneDesProfondeurs_Linux_Portable.tar.gz`:
the game with a `portable.txt` file. As long as that file sits next to the executable,
progress, settings and key bindings are saved in the game's own `sauvegardes` folder
(nothing is written anywhere else): copy the folder to a USB stick to take the game and your
save with you. Delete `portable.txt` to go back to the usual save location.

### Run the project in Godot
1. Install Godot 4 (standard version, not .NET): https://godotengine.org/download
2. In the project manager: **Import** → choose the project folder (the `project.godot` file).
3. Press **F5**.

To build it yourself: *Editor → Manage Export Templates → Download and Install*, then
*Project → Export* and pick one of the presets already in the repo (Windows Desktop, Linux, macOS, Web).

## Controls (keyboard and Xbox / XInput gamepad)

Keys are stored **by position** on the keyboard: you move with **W A S D** on QWERTY and QWERTZ,
and with **Z Q S D** on AZERTY, with nothing to configure. The names shown on screen follow the
system layout; if it is detected wrongly (virtual machine, Steam Deck…), choose
**Controls → Keyboard: AZERTY / QWERTY / QWERTZ**. The table uses QWERTY names.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A / D or arrow keys | Left stick / D-pad |
| Jump (hold = higher) | Space | A |
| Attack | J or **left click** | X |
| Attack upwards / downwards | W or S + J | up/down + X |
| Crouch (dodges high attacks) | S or down arrow (hold, on the ground) | down |
| Dive attack (in the air) | S + K | down + RT |
| Dash / dodge | K or Shift | RT |
| Parry | I or **right click** | LB |
| Soul spell (33 soul) | O or middle click | RB |
| Ultimate (full gauge) | U or R | Y |
| Heal (hold, costs 33 soul) | L or F | B |
| Rest on a bench | W / up arrow | up |
| Map | M | R3 |
| **Pause and menu** | **Esc or P** | **Menu (Start)** |
| **Inventory / equipment** | **Tab or B** | **View (Back)** |

### "Controls" menu
Esc → **Controls**: click (or confirm with the gamepad) a slot, then press the new key.
Each action has 2 keyboard keys and 1 gamepad button; if the input is already used, the two
actions are swapped. Delete clears a keyboard key, Esc cancels. Key slots also accept mouse
buttons (left, right, middle, side buttons). Menus and the inventory can be driven with the
mouse; in game, the cursor hides after 2 seconds without moving.
Settings are saved automatically (`user://controls.cfg`). The left stick always moves the hero.

### Control icons
On-screen hints, signs, messages and the Controls menu show **icons**: drawn keys and mouse
buttons for the keyboard, coloured A/B/X/Y, LB/RT… for an Xbox controller, and cross / circle /
square / triangle, L1/R2… for a PlayStation controller (generic symbols).

### Gamepad (XInput)
On Windows, Godot reads Xbox controllers through XInput: just plug one in. The game shows the
detected controller, uses Xbox button names, accepts triggers in the menu and rumbles on hits,
damage and bosses. Rumble can be turned off in the Controls menu. On-screen hints follow the
last device used (keyboard or gamepad).

## Saves and difficulty

**3 save slots**: title screen → "Saves". Each slot has its own game and its own difficulty
(for example a Normal game and a Nightmare game side by side). "Continue" resumes the last slot
played. Achievements and options are shared by all slots. Saving is automatic.

On launch: **Play** → choose the difficulty (and the "Skip the tutorial" option).
Also available during a game: Pause → "New game…".

**One life** (box to tick when creating a game, at every difficulty): your first death erases the save
slot (outside the tutorial). A small skull next to your shards reminds you. Achievements and cosmetics are
kept, since they are shared by all slots.

| Difficulty | Soul / ultimate | Enemies | Damage taken |
|---|---|---|---|
| Easy | +35% / +30% | slower, -25% health, fewer, no elites | 1 |
| Normal | normal | normal; elites: 8% at first, up to 35% deep down | 1 |
| Hard | -25% / -20% | +25% speed, more aggressive, +35% health, +35% enemies; elites: 25% up to 65% | 1 |
| Nightmare | -40% / -35% | +40% speed, very aggressive, +60% health, +60% enemies; elites: 42% up to 85% | **2** |

Bosses are also faster and tougher depending on the difficulty, but their wind-ups never drop below
0.25 s: even on Nightmare, every attack can be read and dodged. A boss never has more than 3 summoned
minions alive at once, and does not try to summon while its swarm is full.

**Shards**: each enemy gives 10% more per tier (tier 6: +50%), elites give double, and the boss pays
60 + 20 × tier. On Easy, where enemies are fewer and there are no elites, enemies give 40% more and the
boss 10% more, so you progress about as fast as on Normal. Hard and Nightmare give more, through their
extra enemies and elites.

## The Sanctuary and the endless tiers

After the tutorial you arrive at **The Lantern Sanctuary**, the hub of the game:
- **Bench**: rest, restore health, change charms. In the depths, each bench heals only once per level
  (you can sit again to set your respawn point and change charms), and not right after a fight (1.5 s).
- **Merchant**: trades shards for **health masks** (+1 max health, up to 4), charm **notches**
  and the **charms** you have not found yet. His old cart and its pack woodlouse wait beside him.
- **Scriptorium** (up on its platform, above the merchant): **Master Quill**, the archivist owl, keeps
  the records of your game in a big book: game statistics, records, a **bestiary** and the **guardians**
  defeated (with descriptions and tips), and your **charm collection** (where you found each one and
  how long you have worn it).
- **Arsenal**: buy and equip your base weapon. **Try** lends a weapon while you stay in the Sanctuary.
- **Training dummy** (right of the arsenal): shows your damage per second.
- **Seamstress** (between the merchant and the bench): the wardrobe and cosmetics.
- **Elevator**: choose the **tier** to descend to.
- **Residents** arrive as you clear tiers: the **smith** (tier 1, forges your weapons to level 2), the
  **cartographer** (tier 2, sells a quill that reveals the whole map) and the **elder**
  (tier 3, the story of the Lantern).

Your health carries over through the portal between the two levels of a tier (Easy and Normal give
back 1 mask, Hard and Nightmare nothing).

A **tier = 2 generated levels** (biomes drawn at random from 9) **then a boss**. Clearing it
brings you back to the Sanctuary and **unlocks the next tier** — endlessly. The deeper you go,
the more health, speed, aggression and elites the enemies have (about ×1.9 health at tier 6,
×2.6 at tier 10).

**Dying** during a descent: back to the Sanctuary, and the loot picked up since you left
(shards, charms, notches) is lost, but unlocked tiers and purchases remain. Your **shade** keeps
the lost shards where you fell: return to the same tier and defeat it to get them back
(a new death replaces it).

From the elevator you can also:
- play any tier with a **curse** (Haste, Darkness, Frailty) for +50 to 60% shards;
- play the **Daily descent** (same level for everyone, best time), with an **online leaderboard** per
  difficulty: your time is sent at the end with the name you pick (Elevator → "Daily leaderboard"), and
  you see the top 10 and your rank. Sending can be switched off on the same screen;
- take on the **Boss rush** (bosses in a row, timed) once tier 6 is cleared: +600 shards each time, +200 more when you beat your best time, and a charm notch on your first win.

There are 29 **achievements**, viewable from the title screen or the pause menu.

### The 9 biomes

| Biome | Features |
|---|---|
| The Depths | bluish caves, hills and shafts, crawlers and flyers |
| The Fungal Gardens | walls to climb, shafts, lots of spitters |
| The Sunken Citadel | pillars above spikes, arenas, bridges |
| The Crystal Mines | wide chasms (Dash), low corridors, flyers |
| The Blazing Forge | spikes everywhere, embers, crawlers in numbers |
| The Silent Library | climbing and platforms, swarms of flyers |
| The Frozen Abyss | snow, fragile bridges and chasms, spitters |
| The Humming Hive | narrow corridors overrun with flyers |
| The Ossuary | hills and arenas, crawlers and spitters |

### Depths: grottos and strata

| | | |
|---|---|---|
| ![Grotto in the Fungal Gardens](docs/screenshots/grotto_gardens.jpg) | ![Grotto in the Silent Library](docs/screenshots/grotto_library.jpg) | ![Winch at the foot of a shaft (Crystal Mines)](docs/screenshots/strata_winch.jpg) |

Levels are no longer flat strips:
- **Grottos** (every biome): holes in the path lead to a cave dug under the level, laid out
  for its biome (giant mushrooms, library shelves, honeycomb cells, a flooded hall, a bone crypt,
  crystal stalagmites, a fragile ice bridge, ember pits…). Each one hides a **chest**, enemies, and
  sometimes a **merchant** or a charm.
- **Strata** (the Depths, Crystal Mines, Frozen Abyss, Blazing Forge): the level sinks in three
  layers. The first runs to the right, the second back to the left, the third to the right again
  down to the exit. A wide shaft drops from one layer to the next.
- **Winch**: at the bottom of every grotto and every shaft a rope hangs from a winch. **Up** next to
  it hoists you back up in about 1.5 s, so no climbing back through a pit.

### Special rooms
- **Treasure**: a cracked floor hides a chest; break it (downward strikes or a dive).
- **Timed challenge**: touch the hourglass stele, then reach the flag within 13 seconds.
- **Elite arena**: wake the altar, beat three elites, win shards and a charm.
- **Travelling merchant**: sometimes near the mid-level bench (purchases count as loot).

### Traps and platforms
Levels have relief (the ground rises and falls from room to room) and varied rooms: floating
islands, zigzag shafts, double paths, low caves, fragile bridges, chasms with a moving
platform, blade corridors.
- **Dart totem**: shoots at head height — crouch, jump or parry.
- **Pendulum blade**: its lowest point passes just above a crouching hero.
- **Stalactite**: drops when you walk under it.
- **Fragile blocks**: collapse shortly after you land on them, then re-form.
- **Moving platform**: goes back and forth above a chasm.
- Traps appear in at most 50% of rooms, and trapped rooms hold fewer enemies.

## Combat

- **Ground combo**: three strikes, the 3rd is a wider, stronger **finisher**.
- **Charged strike**: hold Attack for about 0.7 s (the needle sparkles) then release = a
  **whirlwind** that hits all around.
- **Thrust**: attack **during (or just after) a dash** = a piercing thrust in a straight line. It **sends
  enemies flying** (not bosses, and not with the shurikens), and can push again 2 s later.
- **Air combo** (different from the ground combo): slash, **rising slash** that lifts you
  again, then a **spin** that hits all around.
- **Dive attack**: in the air, down + Dash. Dive to the ground, bounce off the enemy you hit,
  or cause a **shockwave** on landing. One per jump. After a dive you stand on landing: you only
  crouch again once you have released down.
- **Crouch**: hold down on the ground. Slower, but high attacks pass over you (the lancer's
  thrust, the Colossus's sweep, darts, pendulum blades). Attacking while crouched = low strike.
- **Soul spell**: a soul blade thrown ahead that **passes through** enemies (costs 33 soul,
  the same as a heal — your choice).
- **Parry**: a short window (0.2 s). A parried contact stuns the enemy; a parried boss is
  stunned for a second. A parried spore flies back at the enemies. It grants soul and a lot of
  ultimate charge.
- **Perfect parry**: parrying at the very last moment shows "PERFECT!"; a **golden light**
  glows at the tip of the weapon and the next hit is **critical: ×1.5 damage** (rounded up,
  always at least +1).
- **Dodge**: while dashing you pass through enemies and projectiles (not spikes).
- **Ultimate**: the golden gauge fills when you hit (+6) and parry (+25). When full, the hero
  freezes, charges for half a second (invulnerable), then releases a shockwave: 8 damage to
  everything nearby, and spores are destroyed.
- A needle strike also destroys enemy spores.
- **Recoil**: each strike pushes the hero back a little (about 9 px on the first two hits of the
  combo, 24 px on the finisher, none when crouching), so the whole combo reaches a target that
  does not move.
- **Attack warnings**: a yellow "!" above an enemy preparing a strike; orange with an arrow
  when it is a high attack (crouch).

### The arsenal

| Weapon | Price | Style | Level 2 (smith) |
|---|---|---|---|
| Watcher's Needle | — | balanced | the finisher throws a short air blade |
| Twin Claws | 180 | one claw on each hand: every attack strikes twice (0.5 damage per claw, 0.875 per claw on a power hit), very fast, short reach, half the soul per claw | bleeding: each claw strike has a 20% chance (50% with the Blood Fang) to make the enemy lose 1 more health a second later |
| Bramble Whip | 150 | very long reach ahead and upwards, a little slower | pulls small enemies towards you |
| Anvil Hammer | 220 | slow, +1 damage, big knockback, stuns | the finisher sends a shockwave both ways |
| Moon Stars (shurikens) | 260 | ranged; finisher = 3 stars, whirlwind = 8 in a circle, thrust = a large piercing star | they return like a boomerang and hit again |

Moon Stars: at most 3 plain stars on screen, less soul per hit, and bosses take 75% of
ranged damage.

### Charms
Tab opens the inventory (the game pauses): items, shards, statistics and the grid of **charms**
to find in the levels. Each charm costs notches; you start with 3, and more can be found
(golden rings) or bought. You can only change equipment **while sitting on a bench**.

| Charm | Cost | Effect |
|---|---|---|
| Long Needle | 2 | strike reach +40% |
| Glass Heart | 2 | +2 health masks |
| Swift Cloak | 1 | run +12%, Dash recharges twice as fast |
| Thorned Shell | 2 | thorns hurt nearby enemies when you are hit |
| Perfect Mirror | 1 | parry window 0.35 s |
| Hungry Soul | 2 | more soul and ultimate on every hit |
| Quick Focus | 1 | healing almost twice as fast |
| Brute Strength | 3 | +1 damage, but strikes are 20% slower |
| Blazing Meteor | 2 | a dive that hits primes a critical strike |
| Shadow's Rest | 2 | crouching out of combat slowly refills soul up to 33; crouched healing is 1.5× faster |
| Perfect Echo | 2 | a perfect parry throws a free soul blade |
| Light Step | 1 | crossing a trap without being hit earns 5 shards |
| Rebound Blade | 1 | bouncing off an enemy sends you 25% higher and restores 6 soul |
| Falling Anvil | 2 | the dive deals +1 damage and its shockwave is 50% wider |
| Cutting Parry | 2 | a successful parry deals 2 damage to the attacker |
| Phantom Dash | 2 | the dash hurts the enemies it passes through (1 damage) |
| Soul Harvest | 1 | each enemy defeated restores 8 soul |
| Plunderer's Nose | 1 | grotto chests and hidden caches give 60% more shards |
| Climber's Knot | 1 | winches hoist twice as fast; the first ride up each winch restores 33 soul |
| Last Breath | 3 | a fatal blow leaves you at 1 mask instead, once per level |
| Blood Fang | 2 | +30% chance to cause bleeding with every hit, with any weapon (1 damage a second later); 50% with Twin Claws lv. 2 |

Effects are defined in `scripts/charms.gd` and applied in `scripts/player.gd`.

## Enemies
- **Crawler**, **Flyer**, **Spitter**: the basics — walks, dives, shoots spores.
- **Hopper**: a grasshopper that leaps at you.
- **Shield guard**: blocks hits from the front. Strike from above, from behind, or with the ultimate.
- **Exploding bulb**: rolls towards you, lights up and explodes (hurting nearby enemies too).
- **Weaver**: a spider hanging from the ceiling that drops when you pass underneath.
- **Lancer**: takes a stance then delivers a long thrust; a parry stuns it.
- **Wraith**: fades out (untouchable), reappears near you and throws a slow orb.
- **Elites** (red glow): more health, faster, double loot, and an extra attack — the crawler
  charges, the flyer dive-bombs, the spitter fires 3 spores, the hopper chains two leaps,
  the guard charges with its shield.

The tougher enemies and the elites become more frequent the deeper you go.

## Bosses

The Warden always comes first; the other five arrive in an **order specific to each game**,
then the cycle starts again, tougher. Each has its own shape, attacks, a **phase 2** at half
health and its own musical theme. Parrying a contact stuns the boss for a second.

| Boss | Style | Attacks |
|---|---|---|
| Warden of the Well | armoured beetle | telegraphed charge, crushing leap; phase 2: ground shockwaves |
| The Drowned Abbess | spore queen | charge, leap, fan volley, ring of spores (denser in phase 2) |
| The Swarm Queen | giant **flying** wasp | dives (chained in phase 2), aimed sting volley, spiral rings, summons flyers |
| The Bone Colossus | giant of bones | ground punch (waves + falling rocks), arm sweep; phase 2: leap + row of bone pillars |
| The Deep Worm | **burrowing** worm | digs in, a dust trail gives it away, bursts out under you spitting acid; charge; phase 2: three bursts + waves |
| The Spectral Knight | ghost duellist | lightning thrusts (×3 combos in phase 2), **teleports behind you**, spectral pillars in a line, ember volley |

### Final bosses
At tier 7 (then every 7 tiers), a final boss **drawn at random for each game**, each with its
own theme:
- **The Shadow of the Lantern**: ember crowns, head-height sweep, ash rain, columns of light,
  wraiths in phase 2.
- **The Cerberus of the Depths**: ember breath from three heads, pounce with a shockwave,
  triple bite at head height (crouch), a howl that makes flames erupt.
- **The Centaur Archer**: gallops across the arena, arrow volleys, arrow rain marked on the
  ground, head-height lance strike (crouch), leaps over the player.
- **The Eye from Below**: tentacles bursting from the ground, a beam sweeping the arena at head
  height (crouch) or ground level (jump), spore spirals, flying eyes.

Defeating it plays **the ending**: the Lantern is relit, light climbs tier by tier up to the
Sanctuary and then the surface, and the credits roll. After that, the tiers continue.
Achievement "The Four Guardians": defeat all four.

## Graphics

Everything is drawn in code, in a detailed, painted style:

- **Rock** textured by a shader per biome (strata, cut stone, crystal, lava veins, ice,
  honeycomb, bones), darker with depth, with lit edges;
- **decorated ground** per biome (grass, glowing mushrooms, crystals, skulls, books, candles,
  snow, honey) and **parallax backgrounds** on three planes with mist and light rays;
- **hero, enemies, 10 bosses and Sanctuary residents** with shading, highlights and detail;
- **traps, gates, attack pillars, the exit portal** (one design per biome) and the **ending**;
- **charms** each have an engraved medallion and icon; **weapon swings** leave painted trails;
- **HUD**: a brass-ringed glass soul vessel, painted masks, a brass ultimate gauge, a faceted
  shard crystal, and a parchment minimap;
- **menus and title screen**: painted backdrop (well, lantern, embers), dark wood and brass panels;
- **combat effects**: impact star, death ring with smoke and debris, shards that fly to the
  hero, landing dust, dash afterimage, projectiles with trails;
- **ambience per biome**: spores and fireflies, snow, flying pages, embers, will-o'-the-wisps,
  ceiling drips, bubbling lava, glowing crystal clusters;
- **map** drawn as a lost map: torn, folded, stained and burnt parchment.

## Map, options and accessibility
- **Map** (M / R3): everything you have discovered in the level, with an icon and a legend for
  each point of interest found (bench, exit, merchant, residents, chests, charms, altar, challenge, shade…). **Minimap** in the top-right corner (Options).
- **Language**: Automatic (system language), Français, English, Español, Deutsch.
  Translations live in `tools/translations.py`; running `python3 tools/translations.py`
  regenerates `scripts/translations.gd`.
- **HUD size** (60–160%) and **menu size** (60–130%), **camera zoom**, **full screen**
  (also F11), **vertical sync**.
- **Graphics quality**: High, Balanced (no background light shafts or fog banks, half the particles) or
  Low (far background only, no 2D lights except the hero's, no particles or vignette). Balanced is the
  default on Mac and in the browser. Changes apply instantly.
- **Enemy health bars** and **damage dealt** shown briefly in the top-right corner.
- **On-screen hints**, **screen shake** (0–150%), **hit stop**, gamepad **rumble**.
- **Accessibility**: high-contrast hazards (colour blindness), crouch as a toggle,
  game speed 100 / 90 / 80 / 70%.
- **Descent statistics** (enemies, damage, criticals, perfect parries, hits taken, time) shown
  when you return to the Sanctuary.

Everything is saved in `user://settings.cfg`.

## Cosmetics and wardrobe
The **seamstress** in the Sanctuary (left of the bench) opens the wardrobe, where you change the hero's
look with an animated preview: **53 cosmetics** in 6 categories, 21 of them seasonal. Everything is
purely visual and shared by all save slots. Bright cloaks are toned down so they do not glare on the
dark backgrounds.

| Category | Examples |
|---|---|
| Cloak | shadow, ember, moss, frost, amethyst, ivory, Golden Watcher, starry night |
| Scarf | teal, scarlet, golden, white, violet, living ember |
| Headwear | raven feather, candle, flower crown, golden crown, halo, bone horns |
| Trail and glow | colour of the dash, the eye and the strikes: ember, frost, wraith, pure gold… |
| Companion | firefly, moth, will-o'-the-wisp, little lantern, Queen's wasp (follows the hero, purely decorative) |
| Ultimate | look of the shockwave: golden wave, frost nova, blaze, eclipse, spectral swarm |

Three ways to get them:
- **buy** the common ones from the seamstress with shards;
- **earn an achievement**: the reward is shown in the achievements list;
- **beat a boss**: the Colossus, the Queen, the Knight, the Cerberus and the Eye each have a rare
  cosmetic (25% chance per victory).

There are **29 achievements**, several of which unlock a cosmetic (shown in the achievements list),
including "Watcher's calendar": open the gift of all four festivals.

### Festivals
Four festivals come back every year, automatically, based on the date. During each one the Sanctuary is
decorated, a **gift** can be opened once a year (the festival's headwear and 50 shards), and the
seamstress sells the festival's collection. Whatever you earn or buy stays all year.

| Festival | Dates | Gift | On sale |
|---|---|---|---|
| Valentine's Day | February 8 – 16 | heart headband | rose cloak, beating heart trail, little heart, Love at first sight ultimate |
| Easter | the week before → the week after | bunny ears | spring cloak, chick, Hatching ultimate |
| Vigil of Shadows | October 20 – November 2 | carved pumpkin | vigil cloak, pumpkin fire trail, bat, Swarm of bats ultimate |
| Christmas | December 1 – January 6 | Santa hat | Christmas cloak, string of lights, reindeer antlers, snowflakes, living snowflake, Christmas star ultimate |

Each festival has its own **music** in the Sanctuary and on the title screen, composed for the game
by `tools/synth_fetes.py` (same instruments as the rest of the soundtrack, no existing melody).

To try a festival out of season, start the game with the environment variable
`LANTERNE_EVENT=noel` (or `halloween`, `valentin`, `paques`).

## Loading screens
All drawn in code, in the game's style; any key speeds them up.
- **Launch**: in the dark, a lantern catches fire, embers rise, then the title and a tip appear,
  with a row of embers lighting up as the progress bar, to the sound of crackling embers (synthesized by the game).
- **Entering a shop**: two wooden doors studded with brass close on the resident's sign (purse,
  anvil, map and quill, scroll, spool, crossed blades), then swing open on the counter.
- **The elevator**: the cage, with the hero in their outfit, goes down a stone shaft while the
  chains rattle; the tier number is engraved on a brass plate under the cage. The level is built
  during the ride and the cage stops with a thud. It rides back up to the Sanctuary after a cleared
  tier. The chains are a royalty-free recording (`sfx/lift_chains.ogg`).

## Automatic updates
On launch, the game (Windows, macOS, Linux, Steam Deck) asks GitHub for the latest Release.
If it is newer:
- a small **patch** (scripts and shaders, a few hundred KB) is downloaded and applied on the next
  launch — the title screen offers **"Update ready — restart"**;
- if a patch is not enough (new music, a new Godot version), the title screen shows
  **"Version available — download"** and opens the Release page.

The version number is shown at the bottom of the title screen. **Options → Automatic updates**
turns the download off (the notice still shows). With no network, nothing happens. If the game
fails to start with a patch, the patch is removed on the next launch. The browser version is always
up to date. Details: `scripts/updater.gd`; the patch is built by the release workflow (the "Patch"
export preset). Bump `config/data_gen` in `project.godot` when adding music, sounds or images:
older installs will then see the download notice instead.

## Music and sounds
An **original** soundtrack generated for the game (free of any rights): 29 looping tracks in
`music/` — one or two per biome that crossfade, a theme per boss, one for the tutorial, one for the
Sanctuary and one per festival.
Sound effects are in `sfx/`, with distinct sounds per weapon, for critical hits and for the
perfect parry. **Master / music / effects** volumes are in Options; the music lowers a little
when the game is paused.

## Modding
- Hand-made maps are in `scripts/levels.gd`: add an entry to `LEVELS` to create a level
  (`#` rock, `^` spikes, `c`/`f`/`s` enemies, `B` bench, `D` orb, `K` boss…).
- The hero's settings (speed, jump, dash, damage) are the constants at the top of
  `scripts/player.gd`.

## Tests
`tests/test_run.gd` plays through the levels automatically (simulated inputs, bosses, menus):
`godot --headless --fixed-fps 120 -s res://tests/test_run.gd`.
`tests/dump_maps.gd` generates hundreds of levels to check that they can be completed.

**Leaderboard server**: `server/` (Cloudflare Worker + D1), deployed by the "Classement (Cloudflare)"
workflow with the `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets. `node server/test_worker.mjs`
tests it; `node server/dev_server.mjs` runs it locally (start the game with
`LANTERNE_LEADERBOARD_URL=http://127.0.0.1:8787`).

## License
Code, music (generated for the game) and sound effects: **MIT** license — see `LICENSE`.
Exception: `sfx/lift_chains.ogg` comes from the recording *Chains Chiming* by freesound_community on Pixabay (Pixabay Content License, free to use, no attribution required).
The game is inspired by Hollow Knight (Team Cherry) but reuses none of its characters or assets.
