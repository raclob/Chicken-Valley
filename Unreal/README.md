# Chicken Valley — Unreal migration source

An Unreal Engine **5.8 C++ project** for Windows, porting the farm rivalry prototype. Source is implemented; **it has not been compiled or played in Unreal yet** because the development workspace has no Unreal installation. There is no new Unreal executable in the releases. The existing Windows executable uses Godot.

The source includes a third-person farmer, a collision-aware follow camera, movement and jump, runtime-generated farms, coops, fences, chickens, income, upgrades, an AI rival, visible enemy raids, a HUD, pause/restart, and direct chicken theft. Walk into the rival chicken field, press E, then return to your farm to bank the carried birds. Art and walking animation use simple engine primitives as placeholders.

## Install the tools on Windows

1. Install the **Epic Games Launcher**, then install **Unreal Engine 5.8** from its Unreal Engine Library. Keep the Win64 platform tools enabled.
2. Install the **Visual Studio version and MSVC toolchain supported by Unreal 5.8**, with **Game development with C++**, a Windows SDK, and Visual Studio Tools for Unreal Engine. Use Unreal 5.8's installer/documentation to select the required versions.
3. Download this repository using **Code → Download ZIP**, extract it, and open the **Unreal** folder.

Unreal is a large installation. The Epic launcher will show the space required for your selected engine components. An engine license/account is needed to install Unreal; no credentials belong in this repository.

## Build and open the editor

Right-click **ChickenValley.uproject**, choose **Generate Visual Studio project files**, open the generated solution, and build **ChickenValleyEditor / Development Editor / Win64**. Then open the `.uproject`.

Alternatively, in PowerShell from the Unreal folder:

```powershell
& .\Tools\Build-Windows.ps1 -EngineRoot 'C:\Program Files\Epic Games\UE_5.8'
```

The editor may initially report that `/Game/Maps/FarmValley` is missing. That map and the prototype material are generated in the next step; no binary `.uasset` or `.umap` files have been fabricated or included.

## Create the level and material

In the editor, open **Tools → Execute Python Script** and select **Tools/Bootstrap.py**. If that menu is unavailable, enable the **Python Editor Script Plugin** and **Editor Scripting Utilities** plugins and restart the editor.

The script creates and saves `/Game/Maps/FarmValley` and `/Game/Art/M_Prototype`. It then opens the level. Press **Play**. The C++ game mode builds the world at runtime, so the empty level is expected before Play. Save the generated assets; they must be present before packaging.

## Controls and rules

| Control | Action |
| --- | --- |
| WASD or arrows | Move relative to camera |
| Hold right mouse | Rotate and tilt camera |
| Space | Jump |
| 1 / 2 / 3 / 4, at your farm | Buy chicken / coop / fence / boots |
| E, at rival chicken field | Grab chickens for 30 coins |
| Return to your own chicken field | Automatically deliver carried chickens |
| Esc | Pause/resume |
| R | Restart match |

Chickens earn 0.65 coins per second. Coops provide 12 spaces each. Fences block 2 chickens per raid level; boots increase theft strength. Most chickens after four minutes wins. Chickens being carried earn no income and return to their original farm if the timer expires before delivery. The AI farmer buys upgrades and launches autonomous raids. This is offline solo practice, with no network multiplayer.

## Package a Windows game

After generating the assets and successfully playing in the editor, run:

```powershell
& .\Tools\Build-Windows.ps1 -EngineRoot 'C:\Program Files\Epic Games\UE_5.8' -Package
```

The packaged folder appears under **Unreal/Builds/Windows**. Distribute the entire packaged folder, not just its executable. Engine compilation, editor asset generation, camera/input/rendering, and packaging still need to be verified on a machine with Unreal installed.

## What is verified here

The portable C++ economy is compiled with warnings enabled and tested independently of Unreal for income, purchases, capacity, personal theft, defense, delivery, AI raids, timer scoring, and a full AI match. This does **not** validate Unreal APIs, Unreal Header Tool output, assets, or a packaged game.

```sh
g++ -std=c++17 -Wall -Wextra -Werror -pedantic Tests/FarmEconomyTests.cpp -o /tmp/chicken-valley-economy-tests
/tmp/chicken-valley-economy-tests
```
