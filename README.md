# Medieval World Conqueror

Playable Godot 4 prototype for a 3D medieval RTS and kingdom simulation game.

## Overview

This repository contains a project foundation for a mobile-friendly medieval strategy game featuring:

- 3D overhead RTS camera with touch-friendly controls
- 30 kingdom world simulation
- player-start economy with 1,000,000 gold, food, wood, stone, and iron
- AI kingdom logic and diplomacy shell
- city and army management structures
- fog-of-war and exploration scaffolding
- save/load support
- data-driven architecture for expansion

## Development requirements

- Godot 4.x
- Android SDK and Android export templates for deployment to phones
- A desktop or laptop capable of editing Godot scenes and scripts

## How to open the project

1. Download and install Godot 4.x.
2. Open Godot.
3. Click Project > Import...
4. Select the `Medieval-World-Conqueror` folder.
5. Open the project.

## How to run the game

- Press F5 in the Godot editor to run the project.
- The default scene is `scenes/Game.tscn`.

## How to export for Android

1. In Godot, open Project > Export.
2. Install the Android build templates if prompted.
3. Configure the Android SDK path in Editor > Settings > Android.
4. Set up the Java SDK, Android SDK, and NDK if needed.
5. Select the Android preset and export the APK/AAB.
6. Install the APK on a test Android device.

Important:

- Do not claim the APK is complete or fully functional until it is built and tested on a device.
- Export settings, API level, and signatures must be checked before shipping.

## Folder structure

- `scenes/` — game scenes
- `scripts/` — core gameplay logic
- `data/` — data-driven game configuration
- `ui/` — interface assets and scripts
- `android/` — Android export notes and packaging guidance
- `tests/` — validation scripts and future test cases

## Features implemented

- 3D terrain and world generation foundation
- overhead camera rig with pan/zoom controls
- kingdom economy data model
- city generation and kingdom ownership
- AI kingdom shell with diplomatic and expansion hooks
- 30-kingdom world setup structure
- save/load to JSON
- UI labels for key resources and simulation state
- modular script design for future upgrades

## Planned features

- advanced city management screens
- building construction and upgrades
- recruitment, army commands, and combat
- siege systems and fortification logic
- diplomacy actions and alliance simulation
- fog-of-war, scouting, and visibility rules
- optimized performance pathing for mobile devices
- long-form world simulation with deeper AI decisioning
- polished 3D medieval assets and audio

## Contributing

Contributions are welcome. Please keep changes modular and data-driven, and prefer clear, testable scripts over large monolithic systems.

## License

This project is released under the MIT License.
