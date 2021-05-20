@echo off
Powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0patcher.ps1" "-Restore"
pause