@echo off
Powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\patcher.ps1 -Restore
pause