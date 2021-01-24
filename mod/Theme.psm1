$Script:ThemesDir = Join-Path "$PSScriptRoot" '..' 'Themes' -Resolve

function Get-EvdTheme {
    $themes = @()
    Get-ChildItem -Path $ThemesDir -Include '*.psm1' -Exclude Tools.ps1 | Sort-Object Name | ForEach-Object -Process {
        $themes += [PSCustomObject]@{
                Name = $_.BaseName
                Location = $_.FullName
        }
    }
    $themes
}

function Set-ClxClock {
    param(
        [ValidateSet('Time','Dur')]
        [Parameter(Position=0)]
        [String[]]$Sections = ($NoClock ? @() : @('Dur')),
        [Switch] $NoClock
    )
    $Global:ThemeSettings.ClxClock = $Sections
}

function Set-EvdTheme {
    <#
        .Synopsis
            Loads and apply oh-my-posh theme which depends of EveryDay's resources.
        .Description
            Load EveryDay's themes of command prompt based on oh-my-posh but depends of
            EveryDay's resources. If you're use themes that don't need an EveryDay's functions,
            data structures, etc, it's a beeter way to place them at oh-my-posh's Theme folder
            and use with native functions.
    #>
    param (
        [Parameter(Mandatory=$true)] [string] $Name
    )
    if (Test-Path (Join-Path $ThemesDir "${Name}.psm1")) {
        Set-Theme (Join-Path $ThemesDir "${Name}.psm1")
    }
    elseif (Test-Path "$Name") {
        Set-Theme "$Name"
    }
    else {
        Write-Warning "Theme $Name not found. Available themes are:"
        Get-EvdTheme
    }
    Set-Prompt
}

Set-EvdTheme CLX