# Chicken Valley — Windows PC

A third-person 3D farm rivalry game. Walk your farmer around two competing farms, grow your chicken economy, build coops and defenses, and send raiders to steal chickens. This prototype is offline 1v1 against an AI opponent.

## Download and play

**[Download the Windows game ZIP](https://github.com/raclob/Chicken-Valley/releases/latest/download/Chicken-Valley-Windows.zip)**. No GitHub sign-in is required.

1. Download and extract the entire ZIP.
2. Open the extracted **Chicken-Valley** folder.
3. Double-click **ChickenValley.exe** and choose **Start match vs AI**.

Godot does not need to be installed to play. This build targets 64-bit Windows 10/11 with an OpenGL 3.3-capable GPU. Use the [release page](https://github.com/raclob/Chicken-Valley/releases/latest) if the direct download does not open.

## Controls

| Control | Action |
| --- | --- |
| WASD or arrow keys | Walk relative to the camera |
| Hold right mouse button and move mouse | Turn and tilt the third-person camera |
| Release right mouse button | Use the menus |
| Center view | Reset the camera behind the farmer |
| Farm & raids | Open or close the economy and raid controls |
| Esc or Pause | Pause or resume |
| Play again | Restart after a match |

The camera follows the farmer using perspective projection, with collision to keep it out of buildings. Barns, coops, and upgraded fences block movement. Fences have a central opening. The action panel temporarily disables movement while the match economy continues. Switching away from the game pauses it and releases the mouse.

## Farm economy

Both farms start with 8 chickens and 70 coins. Each chicken earns 0.65 coins per second. Buy chickens and coops, upgrade fences to stop theft, and buy raider boots to improve theft strength and travel speed. The farm with the most chickens after four minutes wins.

| Purchase | Effect | Initial cost |
| --- | --- | --- |
| Chicken | One more chicken, if there is space | 20 |
| Coop | Space for 12 more chickens; maximum 4 coops | 65 |
| Fence | Blocks 2 chickens per incoming raid; maximum level 3 | 45 |
| Raider boots | +1 theft strength and shorter travel; maximum level 3 | 55 |
| Launch raid | Send a raider with a 14-second launch cooldown | 30 |

Upgrade prices increase with each level. A base raider takes 9 seconds each way and steals up to 4 chickens before fence reductions. Chickens in transit earn no income. Excess loot returns to the original farm if your coops are full. Undelivered chickens return before final scoring.

The controllable farmer explores the world. Chicken theft is performed by the raiders launched from the action panel.

## Preview

![Third-person farmer view](https://github.com/raclob/Chicken-Valley/releases/latest/download/third-person-preview.png)

## Source and verification

Open `project.godot` in **Godot 4.6.3** and press F5 to run the source.

Run `godot --headless --path . --script tests.gd` for farm economy, capacity, raids, defenses, and match scoring checks. Run `godot --headless --path . --script third_person_tests.gd` for walking, camera-relative movement, collisions, pitch limits, pause, and touch-release checks.

The **Windows PC prototype** workflow runs these checks, renders a preview, exports the game, launches the packaged executable on a Windows runner, and publishes the portable ZIP only after those checks pass.

Graphics are procedural placeholders. Buildings use fixed plots. Interactive play on real Windows hardware still needs testing. Custom placement, sound, and online multiplayer are future work. Development now targets Windows; earlier Android builds remain in historical releases.
