# HITMAN 2 - PACKAGE DEFINITION PATCHER

This tool automatically updates the packagedefinition.txt encrypted file to use extra mods patches in HITMAN 2.

The packagedefinition.txt encrypted file tells how many patches the base game and DLCs should be recognised 
when playing. Patchlevel settings are usually set to a low value, but in order to play with mods, these 
settings must be higher to allow the game to recognise extra mods patches provided by the community.

This tool makes a copy of the original packagedefinition.txt file and sets all patchlevel values to 10000.

Package Definition Patcher is intended to work through the game updates without having to re-download 
it each time, unless if a future game update introduces a breaking change.

## REQUIREMENTS 

- HITMAN 2
- Microsoft Windows 7 or above (64 bits)

If you're running this game on Linux, you can use this [online editor](https://g2-mods.com/tools/online/xtea/index.html), drag or drop your packagedefinition.txt file and click on "Set Patch Levels", then save this file into Hitman 2's Runtime folder.

## INSTALLATION

1. Run `PATCH.cmd`
2. [Mod your game](https://www.nexusmods.com/hitman2) \o/

#### IMPORTANT : 

- Note that the first step (Run PATCH.cmd) has to be done after every game update, as they replace the packagedefinition.txt with a new one.
- During the first execution, a smartscreen window might appear. In this case, click on "More info > Run Anyway", if you trust this mod of course :D

## UNINSTALL

1. Run `UNINSTALL.cmd` to restore the packagedefinition.txt file to its original state

## NEXUS PAGE

https://www.nexusmods.com/hitman2/mods/17

## CREDITS

* h6xtea : [A.W. Stanley](https://github.com/awstanley/hitman.rs)
    - h6xtea is released under the Zlib licence and is modern variant of the old `h6xxtea` made in 2016.