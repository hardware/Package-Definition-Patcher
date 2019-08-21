@echo off

IF EXIST "%~dp0patcher.ps1" (
    Powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0patcher.ps1" "-Restore"
) ELSE (
    Powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%CD%\patcher.ps1" "-Restore"
)

pause