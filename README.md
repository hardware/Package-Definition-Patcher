# HITMAN 3 - PACKAGE DEFINITION PATCHER

This tool automatically updates the packagedefinition.txt encrypted file to use extra mods patches in HITMAN 3.

The packagedefinition.txt encrypted file tells how many patches the base game and DLCs should be recognised 
when playing. Patchlevel settings are usually set to a low value, but in order to play with mods, these 
settings must be higher to allow the game to recognise extra mods patches provided by the community.

This tool makes a copy of the original packagedefinition.txt file and sets all patchlevel values to 10000.

Package Definition Patcher is intended to work through the game updates without having to re-download 
it each time, unless if a future game update introduces a breaking change.

The game location is automatically detected if you use Epic Games Launcher or Legendary.

## REQUIREMENTS 

- HITMAN 3
- Microsoft Windows 10 (64 bits)

## INSTALLATION

1. Run `PATCH.cmd`
2. [Mod your game](https://www.nexusmods.com/hitman3) \o/

#### IMPORTANT : 

- Note that the first step (Run PATCH.cmd) has to be done after every game update, as they replace the packagedefinition.txt with a new one.
- During the first execution, a smartscreen window might appear. In this case, click on "More info > Run Anyway", if you trust this mod of course :D

## UNINSTALL

1. Run `UNINSTALL.cmd` to restore the packagedefinition.txt file to its original state

## CREDITS

* h6xtea : [A.W. Stanley](https://github.com/awstanley)
    - h6xtea is released under the Zlib licence

## OTHER TOOLS

Package Definition Patcher was designed to patch/unpatch the game easily and quickly, if you are looking for a more complete mod management solution, check this out :

- [QuickMod by Atampy26](https://www.hitmanforum.com/t/quickmod-a-mod-manager-for-hitman-2-and-3/140)
- [A modding SDK and mod loader for HITMAN 3 by OrfeasZ](https://github.com/OrfeasZ/ZHMModSDK)