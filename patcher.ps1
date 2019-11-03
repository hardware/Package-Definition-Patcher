<#

.SYNOPSIS
    This tool automatically updates the packagedefinition.txt encrypted file to use extra mods patches in HITMAN 2.

.DESCRIPTION
    The packagedefinition.txt encrypted file tells how many patches the base game and DLCs should be recognised 
    when playing. Patchlevel settings are usually set to a low value, but in order to play with mods, these 
    settings must be higher to allow the game to recognise extra mods patches provided by the community.

    This tool makes a copy of the original packagedefinition.txt file and sets all patchlevel values to 10000.

    Package Definition Patcher is intended to work through the game updates without having to re-download 
    it each time, unless if a future game update introduces a breaking change.

.NOTES
    Author  : https://www.hitmanforum.com/u/Hardware
    Date    : 2019/11/03
    Version : 1.4.0

.OUTPUTS
    0 if successful, 1 otherwise

.PARAMETER Restore
    If set, restore the packagedefinition.txt file to its original state

.LINK
    https://www.nexusmods.com/hitman2/mods/17

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

Set-Variable STEAM_APP_ID -option Constant -value 863550
Set-Variable STEAM_KEY_PATH -option Constant -value "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
Set-Variable PACKAGEDEFINITION_NAME -option Constant -value "packagedefinition.txt"
Set-Variable HITMAN2_NAME -option Constant -value "HITMAN2.exe"
Set-Variable PATCHLEVEL_SETTING -option Constant -value "patchlevel"
Set-Variable PATCHLEVEL_NUMBER -option Constant -value 10000

#endregion

#region begin functions

function Get-ScriptDirectory
{
    [OutputType([string])]
    param ()

    if ($null -ne $hostinvocation)
    {
        Split-Path $hostinvocation.MyCommand.path
    }
    else
    {
        Split-Path $script:MyInvocation.MyCommand.Path
    }

} # end function Get-ScriptDirectory

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

    $currentDir = Get-ScriptDirectory

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.Filename = "$currentDir\bin\h6xtea\h6xtea.exe"
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

Function ConvertFrom-VDF 
{
    <# 
    .Synopsis 
        Reads a Valve Data File (VDF) formatted string into a custom object.

    .Description 
        The ConvertFrom-VDF cmdlet converts a VDF-formatted string to a custom object 
        (PSCustomObject) that has a property for each field in the VDF string. 
        VDF is used as a textual data format for Valve software applications, 
        such as Steam.

    .Parameter InputObject
        Specifies the VDF strings to convert to PSObjects. Enter a variable that contains 
        the string, or type a command or expression that gets the string. 

    .Example 
        $vdf = ConvertFrom-VDF -InputObject (Get-Content ".\SharedConfig.vdf")

        Description 
        ----------- 
        Gets the content of a VDF file named "SharedConfig.vdf" in the current location 
        and converts it to a PSObject named $vdf

    .Inputs 
        System.String

    .Outputs 
        PSCustomObject
    #>

    param
    (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String[]]$InputObject
    )
    
    process
    {
        $root = New-Object -TypeName PSObject
        $chain = [ordered]@{}
        $depth = 0
        $parent = $root
        $element = $null
		
        ForEach ($line in $InputObject)
        {
            $quotedElements = (Select-String -Pattern '(?<=")([^\"\t\s]+\s?)+(?=")' -InputObject $line -AllMatches).Matches
    
            if ($quotedElements.Count -eq 1) # Create a new (sub) object
            {
                $element = New-Object -TypeName PSObject
                Add-Member -InputObject $parent -MemberType NoteProperty -Name $quotedElements[0].Value -Value $element
            }
            elseif ($quotedElements.Count -eq 2) # Create a new String hash
            {
                Add-Member -InputObject $element -MemberType NoteProperty -Name $quotedElements[0].Value -Value $quotedElements[1].Value
            }
            elseif ($line -match "{")
            {
                $chain.Add($depth, $element)
                $depth++
                $parent = $chain.($depth - 1) # AKA $element
            }
            elseif ($line -match "}")
            {
                $depth--
                $parent = $chain.($depth - 1)
				$element = $parent
                $chain.Remove($depth)
            }
            else # Comments etc
            {
            }
        }

        return $root
    }
    
} # end function ConvertFrom-VDF

#endregion

#region begin body

Show-Message -Type BANNER -NoPrefix -Message "`n-------------------------------------------------------`n"
Show-Message -Type BANNER -NoPrefix -Message "        HITMAN 2 - PACKAGE DEFINITION PATCHER              "
Show-Message -Type BANNER -NoPrefix -Message "                                                           "
Show-Message -Type BANNER -NoPrefix -Message "                 v1.4.0 (2019/11/03)                       "
Show-Message -Type BANNER -NoPrefix -Message "`n-------------------------------------------------------`n"

if($Restore)
{
    Show-Message -Type WARNING -NoPrefix -Message "STARTING PACKAGE DEFINITION RESTORATION PROCEDURE`n"
}

# STEP 1 : PACKAGEDEFINITION SEARCHING
# ------------------------------------------------------------------------------------------------------------------

# Search steam installation folder
$steamPath = (Get-ItemProperty -Path $STEAM_KEY_PATH -Name InstallPath -ErrorAction SilentlyContinue).InstallPath

if(([string]::IsNullOrEmpty($steamPath)) -or (-not(Test-path $steamPath))) 
{
    Show-Message -Type ERROR -Message "Steam folder not found"
    Show-Message -Type DEBUG -Message "Invalid installation path found in the registry"
    Show-Message -Type DEBUG -Message "Key : $STEAM_KEY_PATH"
    Show-Message -Type DEBUG -Message "InstallPath value : $steamPath`n"
}
# If steam folder exists, search for Hitman 2 app manifest in all possible locations
else 
{
    Show-Message -Type INFO -Message "Steam folder found"
    Show-Message -Type INFO -Message "Seaching appmanifest in $steamPath\steamapps"

    $acfFile = "$steamPath\steamapps\appmanifest_$STEAM_APP_ID.acf"
    $gameLocationPath = $null

    # Search for Hitman 2's app manifest in the default steam folder
    if(Test-Path $acfFile)
    {
        $acf = ConvertFrom-VDF (Get-Content $acfFile -Encoding UTF8)
        $installDir = $acf.AppState.installdir
        $gameLocationPath = "$steamPath\steamapps\common\$installDir"
    }
    # Search for Hitman 2's app manifest in each steam library folders
    else
    {
        # libraryfolders.vdf contains all steam library folders
        $vdfFile = "$steamPath\steamapps\libraryfolders.vdf"
        $vdf = $null

        if(-not(Test-path $vdfFile))
        {
            Show-Message -Type ERROR -Message "Steam's libraryfolders.vdf not found"
            Show-Message -Type DEBUG -Message "libraryfolders.vdf file should be here :"
            Show-Message -Type DEBUG -Message "$vdfFile"
            Show-Message -Type DEBUG -Message "But the file was not found"
            Show-Message -Type DEBUG -Message "Unable to find the game location automatically...`n"
        }
        else
        {
            $vdf = ConvertFrom-VDF (Get-Content $vdfFile -Encoding UTF8)
        }

        if(-not([string]::IsNullOrEmpty($vdf)))
        {
            # Search up to 20 library folders
            for($i = 1; $i -le 20; $i++)
            {
                if(-not([string]::IsNullOrEmpty($vdf.LibraryFolders.$i)))
                {
                    $gamesDir = $($vdf.LibraryFolders.$i).Replace('\\','\')
                    $acfFile = "$gamesDir\steamapps\appmanifest_$STEAM_APP_ID.acf"

                    Show-Message -Type INFO -Message "Seaching appmanifest in $gamesDir\steamapps"

                    if(Test-Path $acfFile)
                    {
                        $acf = ConvertFrom-VDF (Get-Content $acfFile -Encoding UTF8)
                        $installDir = $acf.AppState.installdir
                        $gameLocationPath = "$gamesDir\steamapps\common\$installDir"
                        Break
                    }
                }
            }
        }
    }
}

if(([string]::IsNullOrEmpty($gameLocationPath)) -or (-not(Test-path($gameLocationPath)))) 
{
    Write-Host ""
    Show-Message -Type WARNING -Message "Hitman 2 folder not found"
    $gameLocationPath = Read-Host "`n > Enter the full path (eg. C:\Program Files (x86)\Steam\steamapps\common\HITMAN2)"
    Write-Host ""

    if([string]::IsNullOrEmpty($gameLocationPath))
    {
        Show-Message -Type ERROR -Message "No path entered`n"
        Exit 1
    }

    if(-not(Test-path($gameLocationPath))) 
    {
        Show-Message -Type ERROR -Message "Unable to determine a path to Hitman 2's folder`n"
        Exit 1
    }
}
else
{
    Show-Message -Type INFO -Message "Hitman 2 folder found"
}

$packageDefinitionBasePath = "$gameLocationPath\Runtime"
$mainExePath = "$gameLocationPath\Retail\$HITMAN2_NAME"
$packageDefinitionFile = "$packageDefinitionBasePath\$PACKAGEDEFINITION_NAME"

if(-not(Test-path($mainExePath))) 
{
    Show-Message -Type ERROR -Message "$HITMAN2_NAME not found"
    Show-Message -Type DEBUG -Message "$HITMAN2_NAME retail file should be here :"
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

# We replace both the base game and DLCs patchlevels
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