<#

.SYNOPSIS
    This tool automatically updates the packagedefinition.txt encrypted file to use extra mods patches in HITMAN 3.

.DESCRIPTION
    The packagedefinition.txt encrypted file tells how many patches the base game and DLCs should be recognised 
    when playing. Patchlevel settings are usually set to a low value, but in order to play with mods, these 
    settings must be higher to allow the game to recognise extra mods patches provided by the community.

    This tool makes a copy of the original packagedefinition.txt file and sets all patchlevel values to 10000.

    Package Definition Patcher is intended to work through the game updates without having to re-download 
    it each time, unless if a future game update introduces a breaking change.

.NOTES
    Author  : https://www.hitmanforum.com/u/Hardware
    Date    : 2021/05/20
    Version : 1.5.0

.OUTPUTS
    0 if successful, 1 otherwise

.PARAMETER Restore
    If set, restore the packagedefinition.txt file to its original state

.EXAMPLE
    .\patcher.ps1
    Patch the packagedefinition.txt file

.EXAMPLE
    .\patcher.ps1 -Restore
    Restore the packagedefinition.txt file to its original state

#>

Param
(
    [Parameter(Mandatory=$false)]
    [Switch]$Restore
)

#region begin constants

Set-Variable EGS_APP_NAME -option Constant -value "Eider"
Set-Variable EGS_FILE_MANIFEST -option Constant -value "C:\ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat"
Set-Variable PACKAGEDEFINITION_NAME -option Constant -value "packagedefinition.txt"
Set-Variable HITMAN3_NAME -option Constant -value "HITMAN3.exe"
Set-Variable PATCHLEVEL_SETTING -option Constant -value "patchlevel"
Set-Variable PATCHLEVEL_NUMBER -option Constant -value 10000

#endregion

#region begin functions

function Show-Message
{
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Message,
        [Parameter(Mandatory = $true)]
        [ValidateSet('BANNER', 'INFO', 'WARNING', 'DEBUG', 'ERROR', 'SUCCESS')]
        [String]$Type,
        [Parameter(Mandatory = $false)]
        [Switch]$NoPrefix
    )

    switch ($Type) {
        BANNER  { $color = [ConsoleColor]::Gray }
        INFO    { $color = [ConsoleColor]::Cyan }
        WARNING { $color = [ConsoleColor]::DarkYellow }
        DEBUG   { $color = [ConsoleColor]::Yellow }
        ERROR   { $color = [ConsoleColor]::Red }
        SUCCESS { $color = [ConsoleColor]::Green }
    }

    if($NoPrefix -eq $true)
    {
        Write-Host -ForegroundColor $color $message
    }
    else 
    {
        Write-Host -ForegroundColor $color "[$Type] $message"
    }

} # end function Show-Message

function Invoke-H6xtea
{
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Args
    )

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.Filename = "$PSScriptRoot\bin\h6xtea\h6xtea.exe"
    $process.StartInfo.Arguments = $Args
    $process.StartInfo.RedirectStandardOutput = $True
    $process.StartInfo.RedirectStandardError = $True
    $process.StartInfo.UseShellExecute = $false
    $process.start() | Out-Null
    $process.WaitForExit()

    [PsCustomObject]@{
        StdOut = $process.StandardOutput.ReadToEnd();
        StdErr = $process.StandardError.ReadToEnd();
        ExitCode = $process.ExitCode;
    }
    
} # end function Invoke-H6xtea

#endregion

#region begin body

Show-Message -Type BANNER -NoPrefix -Message "`n-------------------------------------------------------`n"
Show-Message -Type BANNER -NoPrefix -Message "        HITMAN 3 - PACKAGE DEFINITION PATCHER              "
Show-Message -Type BANNER -NoPrefix -Message "                                                           "
Show-Message -Type BANNER -NoPrefix -Message "                 v1.5.0 (2021/05/20)                       "
Show-Message -Type BANNER -NoPrefix -Message "`n-------------------------------------------------------`n"

if($Restore)
{
    Show-Message -Type WARNING -NoPrefix -Message "STARTING PACKAGE DEFINITION RESTORATION PROCEDURE`n"
}

# STEP 1 : GAME LOCATION AND PACKAGEDEFINITION SEARCHING
# ------------------------------------------------------------------------------------------------------------------

$gameLocationPath = $null

if(Get-Command legendary -ErrorAction SilentlyContinue)
{
    Show-Message -Type INFO -Message "Legendary executable found"
    Show-Message -Type INFO -Message "Seaching HITMAN 3 install location"
    $apps = legendary list-installed --json | ConvertFrom-Json

    foreach($app in $apps)
    {
        if($app.app_name -eq $EGS_APP_NAME)
        {
            $gameLocationPath = $app.install_path
        }
    }
}

if(([string]::IsNullOrEmpty($gameLocationPath)) -or (-not(Test-path($gameLocationPath)))) 
{
    if(-not(Test-path $EGS_FILE_MANIFEST))
    {
        Show-Message -Type WARNING -Message "Epic Games Store manifest not found"
    }
    else 
    {
        Show-Message -Type INFO -Message "Epic Games Store manifest found"
        Show-Message -Type INFO -Message "Seaching HITMAN 3 install location"

        $gameLocationPath = Get-Content -Raw -Path $EGS_FILE_MANIFEST | 
            ConvertFrom-Json | 
            Select-Object -ExpandProperty InstallationList | 
            Where-Object AppName -eq $EGS_APP_NAME | 
            Select-Object -ExpandProperty InstallLocation
    }
}

if(([string]::IsNullOrEmpty($gameLocationPath)) -or (-not(Test-path($gameLocationPath)))) 
{
    Show-Message -Type WARNING -Message "HITMAN 3 folder not found"
    $gameLocationPath = Read-Host "`n > Enter the full path (eg. C:\Program Files\Epic Games\HITMAN3)"
    Write-Host ""

    if([string]::IsNullOrEmpty($gameLocationPath))
    {
        Show-Message -Type ERROR -Message "No path entered`n"
        Exit 1
    }

    if(-not(Test-path($gameLocationPath))) 
    {
        Show-Message -Type ERROR -Message "Unable to determine a path to HITMAN 3's folder`n"
        Exit 1
    }
}
else
{
    Show-Message -Type INFO -Message "HITMAN 3 folder found"
}

$packageDefinitionBasePath = "$gameLocationPath\Runtime"
$mainExePath = "$gameLocationPath\Retail\$HITMAN3_NAME"
$packageDefinitionFile = "$packageDefinitionBasePath\$PACKAGEDEFINITION_NAME"

if(-not(Test-path($mainExePath))) 
{
    Show-Message -Type ERROR -Message "$HITMAN3_NAME not found"
    Show-Message -Type DEBUG -Message "$HITMAN3_NAME retail file should be here :"
    Show-Message -Type DEBUG -Message "$mainExePath"
    Show-Message -Type DEBUG -Message "But the file was not found...`n"
    Exit 1
}

Show-Message -Type INFO -Message "Searching for $PACKAGEDEFINITION_NAME"

if(-not(Test-path($packageDefinitionFile))) 
{
    Show-Message -Type ERROR -Message "$PACKAGEDEFINITION_NAME not found"
    Show-Message -Type DEBUG -Message "$PACKAGEDEFINITION_NAME retail file should be here :"
    Show-Message -Type DEBUG -Message "$packageDefinitionFile"
    Show-Message -Type DEBUG -Message "But the file was not found...`n"
    Exit 1
}

$gameVersion = (Get-Item $mainExePath).VersionInfo.FileVersion

$packageDefinitioniniFile = "$packageDefinitionBasePath\packagedefinition.ini"
$packageDefinitionBackupFile = "$packageDefinitionFile-original-$gameVersion"
$packageDefinitionBackupPattern = "$packageDefinitionFile-original-*"

# STEP 2 : PACKAGE DEFINITION BACKUP 
# ------------------------------------------------------------------------------------------------------------------

# No backup found
# The script has never been used or the game version has changed
if(-not(Test-Path($packageDefinitionBackupFile)))
{
    # If a recovery is requested
    if($Restore)
    {
        Show-Message -Type ERROR -Message "Backup file not found`n"
        Exit 1
    }

    Show-Message -Type INFO -Message "No backup file found for game patch $gameVersion"

    # Remove old backup files if they exist
    Remove-Item $packageDefinitionBackupPattern -Force

    # Backup of the original file
    Copy-Item $packageDefinitionFile $packageDefinitionBackupFile -Force -ErrorAction Continue

    if(-not(Test-Path($packageDefinitionBackupFile)))
    {
        Show-Message -Type ERROR -Message "Unable to create the backup file`n"
        Exit 1
    }
    
    Show-Message -Type INFO -Message "Backup created"
}
else
{
    # If a recovery is requested
    if($Restore)
    {
        # Use the latest current backup for recovery
        Move-Item $packageDefinitionBackupFile $packageDefinitionFile -Force

        # Remove old backup files if they exist
        Remove-Item $packageDefinitionBackupPattern -Force

        Show-Message -Type SUCCESS -Message "$PACKAGEDEFINITION_NAME successfully restored`n"

        Exit 0
    }

    Show-Message -Type INFO -Message "A backup file already exists for game patch $gameVersion"
}

# STEP 3 : DECRYPTION 
# ------------------------------------------------------------------------------------------------------------------

$result = Invoke-H6xtea -Args " --decipher --src=`"$packageDefinitionFile`" --dst=`"$packageDefinitioniniFile`""

if($result.ExitCode -ne 0)
{
    Show-Message -Type ERROR -Message "An error occured during $PACKAGEDEFINITION_NAME decryption : exit code $($result.ExitCode)"
    Show-Message -Type ERROR -NoPrefix -Message "-------------------------------------------------------"
    Show-Message -Type ERROR -NoPrefix -Message $result.StdErr
    Show-Message -Type ERROR -NoPrefix -Message "-------------------------------------------------------`n"
    Exit 1
}

Show-Message -Type INFO -Message "Definition file decrypted"

# STEP 4 : PATCHLEVEL EDITING 
# ------------------------------------------------------------------------------------------------------------------

$iniFileContent = Get-Content $packageDefinitioniniFile

if(-not($iniFileContent | Select-string -Pattern $PATCHLEVEL_SETTING -Quiet))
{
    Show-Message -Type ERROR -Message "No $PATCHLEVEL_SETTING found in $PACKAGEDEFINITION_NAME, file format has probably changed`n"
    Exit 1
}

# Replace both the base game and DLCs patchlevels
# @chunk patchlevel=xx / @dlc patchlevel=xx
$iniFileContent -Replace "$PATCHLEVEL_SETTING\.*=.*", "$PATCHLEVEL_SETTING=$PATCHLEVEL_NUMBER" `
 | Set-Content $packageDefinitioniniFile -Force

Show-Message -Type INFO -Message "Patchlevel settings found and replaced"

# STEP 5 : ENCRYPTION 
# ------------------------------------------------------------------------------------------------------------------

$result = Invoke-H6xtea -Args " --encipher --src=`"$packageDefinitioniniFile`" --dst=`"$packageDefinitionFile`""

if($result.ExitCode -ne 0)
{
    Show-Message -Type ERROR -Message "An error occured during $PACKAGEDEFINITION_NAME encryption : exit code $($result.ExitCode)"
    Show-Message -Type ERROR -NoPrefix -Message "-------------------------------------------------------"
    Show-Message -Type ERROR -NoPrefix -Message $result.StdErr
    Show-Message -Type ERROR -NoPrefix -Message "-------------------------------------------------------`n"
    Exit 1
}

Remove-Item -Path $packageDefinitioniniFile -Force

Show-Message -Type INFO -Message "Definition file encrypted"

# EXITING 
# ------------------------------------------------------------------------------------------------------------------

Write-Host ""
Show-Message -Type SUCCESS -Message "$PACKAGEDEFINITION_NAME successfully patched"
Show-Message -Type SUCCESS -NoPrefix -Message "`n> Now you can add any rpkg patch for both the"
Show-Message -Type SUCCESS -NoPrefix -Message "> base game and DLCs in your Runtime folder :"
Show-Message -Type SUCCESS -NoPrefix -Message "> Path : $packageDefinitionBasePath`n"

Exit 0

#endregion