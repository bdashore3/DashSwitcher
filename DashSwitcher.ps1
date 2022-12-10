<# 
    DashSwitcher

    A powershell script to switch between Oculus Dash and OculusKiller
    Renames OculusKiller with the prefix .kill when inactive and Dash to .bak when inactive
    Please follow the exact instructions for installing OculusKiller before using this script!
    https://github.com/LibreQuest/OculusKiller#installation

    Thanks ItsKaitlyn03 for OculusKiller!    

    Created by kingbri <bdashore3@proton.me>
#>

# MARK: Powershell preferences
$errorActionPreference = 'Stop'

# MARK: Global variables
$DashPath = "C:\Program Files\Oculus\Support\oculus-dash\dash\bin"
$wshell = New-Object -ComObject Wscript.Shell

# MARK: Registry Paths

# Steam Paths
$SteamPath = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" | Select-Object -ExpandProperty SteamPath
$SteamXRPath = "${SteamPath}\steamapps\common\SteamVR\steamxr_win64.json"

# Oculus Paths
$OculusPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Oculus" | Select-Object -ExpandProperty InstallLocation
$OculusXRPath = "${OculusPath}Support\oculus-runtime\oculus_openxr_64.json"

# OpenXR Config variables and paths
$OpenXRMajorVersion = 1
$OpenXRPath = "HKLM:\SOFTWARE\Khronos\OpenXR\${OpenXRMajorVersion}"

# MARK: Enums for popups
Enum AlertButton {
    Ok = 0
    OkCancel = 1
    AboutRetryIgnore = 2
    YesNoCancel = 3
    YesNo = 4
    RetryCancel = 5
    CancelAgainContinue = 6
}

Enum AlertIcon {
    Stop = 16
    Question = 32
    Exclamation = 48
    Information = 64
}

function Main {
    if (Test-Path -Path "${DashPath}\OculusDash.exe") {
        if (Test-Path -Path "${DashPath}\OculusDash.exe.bak") {
            Enable-Dash
        } elseif (Test-Path -Path "${DashPath}\OculusDash.exe.kill") {
            Enable-Killer
        } else {
            Show-Popup -Title "Error" -Message "There is no other dash exe to switch. Please download OculusKiller to use this script!" -Icon Exclamation
        }
    } else {
        Show-Popup -Title "Error" -Message "No dash found! Please reinstall Oculus." -Icon Exclamation
    }
}

# Shows a popup to the user
function Show-Popup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [AlertButton]$Buttons = [AlertButton]::Ok,
        [AlertIcon]$Icon = [AlertIcon]::Information
    )

    # Don't care about output here
    $null = $wshell.Popup($Message, $Timeout, $Title, [int]$Buttons + [int]$Icon)
}

# Activates OculusKiller and renames dash to .bak
function Enable-Killer {
    try {
        Rename-Item "${DashPath}\OculusDash.exe" "OculusDash.exe.bak"
        Rename-Item "${DashPath}\OculusDash.exe.kill" "OculusDash.exe"
        $FormattedPath = $SteamXRPath -replace '/','\'
        Set-ItemProperty -Path $OpenXRPath -Name ActiveRuntime -Value $FormattedPath
        Show-Popup -Title "Success" -Message "Switched to OculusKiller"
    } catch {
        Show-Popup -Title "Error" -Message "There was an error when switching to OculusKiller: `n`n$_" -Icon Exclamation
    }
}

# Activates Oculus Dash and renames OculusKiller to .kill
function Enable-Dash {
    try {
        Rename-Item "${DashPath}\OculusDash.exe" "OculusDash.exe.kill"
        Rename-Item "${DashPath}\OculusDash.exe.bak" "OculusDash.exe"
        $FormattedPath = $OculusXRPath -replace '/','\'
        Set-ItemProperty -Path $OpenXRPath -Name ActiveRuntime -Value $FormattedPath
        Show-Popup -Title "Success" -Message "Switched to Oculus Dash"
    } catch {
        Show-Popup -Title "Error" -Message "There was an error when switching to Oculus Dash: `n`n$_" -Icon Exclamation
    }
}

# MARK: Executable code

# Is this admin? If not, elevate.
# https://stackoverflow.com/a/17888599/17525181
if (
    -NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
) {
    try {
        $arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
        Start-Process powershell.exe -Verb runAs -ArgumentList $arguments
    } catch {
        Show-Popup -Title "Error" -Message "There was a permission error: `n`n$_" -Icon Exclamation
    }

    break
}

# Init
Main
