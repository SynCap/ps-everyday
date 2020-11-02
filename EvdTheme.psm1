
function Get-EvdTheme {
    $themes = @()
    Get-ChildItem -Path "$PSScriptRoot\Themes\*" -Include '*.psm1' -Exclude Tools.ps1 | Sort-Object Name | ForEach-Object -Process {
        $themes += [PSCustomObject]@{
                Name = $_.BaseName
                Location = $_.FullName
        }
    }
    $themes
}

function Set-EvdTheme {
    param (
        [Parameter(Mandatory=$true)] [string] $Name
    )
    if (Test-Path "$PSScriptRoot\Themes\${Name}.psm1") {
        Set-Theme "$PSScriptRoot\Themes\${Name}.psm1"
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