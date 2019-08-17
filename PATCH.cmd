@echo off
Powershell.exe -ExecutionPolicy RemoteSigned -File "%~dp0\bin\packagedefinition-patcher.ps1"
pause