# Import-Module ./

function Import-EvdModulesAll {
    ls (Join-Path $PSScriptRoot 'Evd*.psm1') | %{Import-Module $_ -Force}
}

function Import-EvdModule {
    <#
        .Synopsys

            Reload EveryDay PSM pack's submodule or all submodules.

        .Description

            Reloads all or cpecific submodle(s) of EveryDay PSM family. To
            import or reload exact module use Import-EvdModule
            `<SubModule_Name>` where `<SubModule_Name>` is part of modules'
            filename after `Evd` and just till extension. Module with name
            `Theme` lives in `EvdTheme.psm1` file so to reload that module use
            `Import-EvdModule Theme`.

            To reload all Evd modules use `Import-EvdModule -f` or better
            `Import-EvdModulesAll`.

            To reload several modules use `Import-EvdModule Mod1,Mod2,Mod3` or
            `(Mod1,Mod2,Mod3) | Import-EvdModule`

    #>
    param(
        [Parameter(ValueFromPipeline)] [String[]] $Name,
        [Alias('f')] [Switch] $Force
    )
    if (!$Name -and $Force) {
        Import-EvdModulesAll
    }
    if (Test-Path ($mp=(Join-Path $PSScriptRoot "Evd${Name}.psm1"))) {
        Import-Module $mp -Force
    }
}

$LogDir = Join-Path $PSScriptRoot 'Logs'
$LogFilesMask = '*.log'
$DaysToKeepLogs = 10

$TimeStampFormat ='yyyy MM-MMM dd-ddd HH:mm:ss.fffffff'
$LogFileNameFormat = 'yyyy-MM-dd'
# https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings
# https://docs.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings?view=netframework-4.8
# https://docs.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings?view=netframework-4.8

function Write-EvdLog ( $Message ) {
    Get-ChildItem $LogFilesMask -Filter $LogFilesMask |
        where {$_.LastWriteTime -lt (Get-Date).AddDays(-$DaysToKeepLogs)} |
            Remove-Item
    "$(Get-Date -Format $TimeStampFormat)`t$Message" >> $(Join-Path $LogDir "$(Get-Date -Format $LogFileNameFormat).log")
}

Register-EngineEvent PowerShell.Exiting -Action {
    Write-EvdLog "Close PowerShell Console;`t${PWD}"
}

Set-Alias -Name reevd  -Value Import-EvdModule
Set-Alias -Name evdlog -Value Write-EvdLog

Import-EvdModulesAll
Import-Module Jumper
