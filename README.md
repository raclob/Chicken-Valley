# Chicken Valley

A 3D real-time farm economy game: grow your flock, build coops, defend your farm, and steal chickens from your rival. The first prototype is offline 1v1 against an AI farmer.

## Play

Open `project.godot` in **Godot 4.6.3** and press **F6** or **F5**. Tap **Start match vs AI**. The game uses a landscape view and large touch buttons; desktop mouse controls work too.

Both farms start with 8 chickens and 70 coins. Each chicken earns 0.65 coins per second. Buy chickens, build coops for more capacity, upgrade fences to stop theft, and buy raider boots to improve raid strength and speed. Raiders cross the field, steal chickens, and bring them home. The farm with the most chickens after four minutes wins. Pause and restart are available.

| Purchase | Effect | Initial cost |
| --- | --- | --- |
| Chicken | One more chicken, if a coop has space | 20 |
| Coop | Space for 12 more chickens, maximum 4 coops | 65 |
| Fence | Blocks 2 chickens per incoming raid, maximum level 3 | 45 |
| Raider boots | +1 theft strength and shorter travel, maximum level 3 | 55 |
| Steal chickens | Launch a raider; 14-second launch cooldown | 30 |

Upgrade prices increase with each level. A basic raider takes 9 seconds each way and steals up to 4 chickens before fence reductions. Chickens in transit earn no income. Excess loot returns to the original farm if your coops are full. Undelivered chickens return to their original farm before final scoring.

## Android APK

The **Android prototype** workflow in [Actions](../../actions) tests the game and exports an APK on pushes to `main`, or when run manually. Once a run succeeds, open it and download the **chicken-valley-android** artifact. Unzip it, transfer `chicken-valley.apk` to your Android device, and install it. Android may ask you to allow installation from that download source.

The export targets ARM64 phones and x86_64 emulators using Godot's compatibility renderer. It is a debug-signed prototype. Builds within this repository use a persisted CI debug key, so later APKs can update the earlier installation. Online multiplayer is not included.

To export locally, install the Godot 4.6.3 export templates, Android SDK (platform-tools, Android platform 35, and build-tools 35.0.1), and JDK 17. Configure Java and Android SDK paths in Godot's editor settings, then use **Project → Export → Android → Export Project** with **Export With Debug** enabled.

## Verification

Run `godot --headless --path . --script tests.gd` to check income, purchases, capacity, raid cooldown, theft timing, defenses, delivery, final scoring, and a full AI match. Run `godot --headless --path . --quit-after 120` for a scene startup smoke check.

The gameplay tests and headless scene startup passed in the development workspace. Real-device rendering, touch input, and APK installation still need testing. Graphics are procedural placeholders. Buildings occupy fixed plots; custom placement, direct farmer movement, sound, and online matchmaking are future work.
