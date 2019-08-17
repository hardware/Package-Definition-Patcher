# HITMAN 2 - PACKAGE DEFINITION PATCHER

v1.0 (2019/08/17)

This script allows to use extra mods patches in HITMAN 2 by raising the patchlevel value of chunk0.

The packagedefinition.txt's patchlevel directive tells the game how many chunk0 patches should be recognised 
when playing. This is usually set to 3 by default, but in order to play with mods, this number must be higher 
to allow the game to recognise extra mod patches provided by the community.

This script backup the original packagedefinition.txt file and sets a patchlevel value of 10000.

IMPORTANT : Note that this has to be done after every game update, as updates replace the packagedefinition.txt with a new one.

## REQUIREMENTS 

- HITMAN 2

## INSTALLATION

1. Run PATCH.cmd
2. Mod your game \o/

## UNINSTALL

1. Run UNINSTALL.cmd to restore the packagedefinition.txt file to its original state

## CREDITS

- h6xxtea tool made by HHCHunter (https://github.com/HHCHunter/HITMAN)