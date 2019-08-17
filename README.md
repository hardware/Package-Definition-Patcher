# HITMAN 2 - PACKAGE DEFINITION PATCHER

This tool allows to use extra mods patches in HITMAN 2 by raising the patchlevel value of chunk0.

The packagedefinition.txt's patchlevel directive tells the game how many chunk0 patches should be recognised when playing. This is usually set to 3 by default, but in order to play with mods, this number must be higher to allow the game to recognise extra mod patches provided by the community.

This tool makes a copy of the original packagedefinition.txt file and sets a patchlevel value of 10000.

Package Definition Patcher was intended to work through the game updates without having to re-download it each time, unless if a future game update introduces a breaking change.

## REQUIREMENTS 

- HITMAN 2

## INSTALLATION

1. Run `PATCH.cmd`
2. Mod your game \o/

IMPORTANT : Note that the first step has to be done after every game update, as they replace the packagedefinition.txt with a new one.

## UNINSTALL

1. Run `UNINSTALL.cmd` to restore the packagedefinition.txt file to its original state

## CREDITS

- h6xtea : [A.W. Stanley](https://github.com/awstanley/hitman.rs)
    