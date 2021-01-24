#requires -Version 2 -Modules posh-git

function Write-Theme {
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )

    $lastColor = $sl.Colors.SessionInfoBackgroundColor
    $prompt = Write-Prompt -Object $sl.PromptSymbols.StartSymbol -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $lastColor

    #check the last command state and indicate if failed
    If ($lastCommandFailed) {
        $prompt += Write-Prompt -Object $sl.PromptSymbols.FailedCommandSymbol -ForegroundColor $sl.Colors.CommandFailedIconForegroundColor -BackgroundColor $lastColor
    }

    #check for elevated prompt
    If (Test-Administrator) {
        $prompt += Write-Prompt -Object $sl.PromptSymbols.ElevatedSymbol -ForegroundColor $sl.Colors.AdminIconForegroundColor -BackgroundColor $lastColor
    }

    if (Test-VirtualEnv) {
        $prompt += Write-Prompt $sl.PromptSymbols.SegmentStartSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
        # $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.VirtualEnvSymbol) $(Get-VirtualEnvName)" -ForegroundColor $sl.Colors.VirtualEnvForegroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol)" -ForegroundColor $sl.Colors.VirtualEnvBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }
    else {
        $prompt += Write-Prompt $sl.PromptSymbols.SegmentStartSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
        # $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }

    $lastColor = $sl.Colors.PromptBackgroundColor

    # Clock section
    # possible to display time of finish previous command and/or it's duration

    if ($sl.ClxClock -contains 'Time') {
        $timestamp = "⌚{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)
    }

    $history = Get-History
    if (0 -lt $history.Count -and $sl.ClxClock -contains 'Dur') {
        $dur = '⌛' + ( ($history | Select-Object -Last 1).Duration.ToString() -Replace '^[0:]*','' -Replace '\d{4}$','' )
    }

    $clock = (@($timestamp,$dur) -Join ''),( [boolean]$timestamp -or [boolean]$dur ? '┋' : $null ) -join ''

    $prompt += Write-Prompt $clock -BackgroundColor $sl.Colors.PromptBackgroundColor -ForegroundColor $sl.Colors.ClockForeground

    # Writes the Path portion
    $pathSeparator = $sl.promptSymbols.PathSeparatorSymbol
    $path = Get-FullPath -dir $pwd

    if ($path -eq '~') {
        $path = '   {0}   ' -f $sl.promptSymbols.homeChars[2]
    } else {
        foreach ($subst in $sl.PathSubstitutions) {
            if ($path -match ($subst.Pattern+'\\?')){
                # println 'Found: ', $subst.Label
                $path = ($path -replace $subst.Pattern, $subst.Label)
                # println $path
                break
            }
        }
        if ($path.Length -lt [Console]::WindowWidth / 3) { $pathSeparator = " ${pathSeparator} " }
        if ($path.Length -gt ($pathFieldWidth = [Console]::WindowWidth / 2 - 10)) {
            $m = $path -match '^(.*)[/\\](.+)$';
            $ellipsed = $Matches[1].Substring(0, ( 3 + $Matches[2].Length -lt $pathFieldWidth ? $pathFieldWidth - 3 - $Matches[2].Length : 0 ) )
            $path = $ellipsed + '… ' + $pathSeparator + "`e[1;93m" + $Matches[2]
            # $path = $path -replace '^(~|\w+:).*[/\\](.*)[\\/]?$','$1\ .. \$2'
        }
        $path = $path.Replace('\', $PathSeparator)
    }
    $prompt += Write-Prompt -Object $path.PadLeft(7,' ') -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor

    $status = Get-VCSStatus
    if ($status) {
        $themeInfo = Get-VcsInfo -status ($status)
        $lastColor = $themeInfo.BackgroundColor
        $prompt += Write-Prompt -Object $($sl.PromptSymbols.SegmentForwardSymbol) -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $lastColor
        $prompt += Write-Prompt -Object $themeInfo.VcInfo -BackgroundColor $lastColor -ForegroundColor $sl.Colors.GitForegroundColor
    }

    $prompt += Write-Prompt $sl.PromptSymbols.SegmentFinishSymbol -ForegroundColor $lastColor

    $prompt += Set-Newline
    # $prompt += Write-Prompt $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor

    if ($with) {
        $prompt += Write-Prompt -Object "$($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
    }
    $prompt += Write-Prompt -Object ($sl.PromptSymbols.PromptIndicator) -ForegroundColor $sl.Colors.PromptSymbolColor
    $prompt += "`e[0m "
    $prompt
}

$sl = $Global:ThemeSettings #local settings

# show timestamp and/or duration of previously executed command (taken from history)
# Array of 'Time', 'Dur' (duration). Show respective value when aray contains one or both
if ($null -eq $sl.ClxClock) {
    Add-Member -InputObject $sl -MemberType NoteProperty -Name 'ClxClock' -Value @()
}

if ($null -eq $sl.PathSubstitutions) {
    Add-Member -InputObject $sl -MemberType NoteProperty -Name 'PathSubstitutions' -Value @()
}

$sl.PathSubstitutions = @(
    <# 0 #> @{ Label=" Alpine `u{e0b1} ";   Pattern='~\\AppData\\Local\\Packages\\36828agowa338.AlpineWSL_my43bytk1c4nr\\LocalState\\rootfs'},
    <# 1 #> @{ Label=" Debian `u{e0b1} ";   Pattern='~\\AppData\\Local\\Packages\\TheDebianProject.DebianGNULinux_76v4gfsz19hv4\\LocalState\\rootfs'},
    <# 2 #> @{ Label=" KALI `u{e0b1} ";     Pattern='~\\AppData\\Local\\Packages\\KaliLinux.54290C8133FEE_ey8k8hqnwqnmg\\LocalState\\rootfs'},
    <# 3 #> @{ Label=" Ubuntu `u{e0b1} ";   Pattern='~\\AppData\\Local\\Packages\\CanonicalGroupLimited.Ubuntu20.04onWindows_79rhkp1fndgsc\\LocalState\\rootfs'},
    <# 4 #> @{ Label={"`e[36m WSL`$ `e[33m{0}`e[97m `u{e0b1} " -f ($_.Groups[1].Value.Substring(0,1).ToUpper() + $_.Groups[1].Value.Substring(1).ToLower())}; Pattern='^Microsoft\.PowerShell\.Core\\FileSystem::\\\\wsl\$\\(\w+).*\\?'}
)

$sl.PromptSymbols.StartSymbol                    = '' # [char]::ConvertFromUtf32(0x9889)
$sl.PromptSymbols.ElevatedSymbol                 = [char]::ConvertFromUtf32(0x26A1)
$sl.PromptSymbols.PromptIndicator                = [char]::ConvertFromUtf32(0xE0B1) #(0x276F) - ❯
$sl.PromptSymbols.PathSeparatorSymbol            = "`e[96m{0}`e[97m" -f [char]::ConvertFromUtf32(0xe0bb) # 0x2573
$sl.PromptSymbols.SegmentStartSymbol             = [char]::ConvertFromUtf32(0xE0ba)
$sl.PromptSymbols.SegmentBackwardSymbol          = [char]::ConvertFromUtf32(0xE0be)
$sl.PromptSymbols.SegmentForwardSymbol           = [char]::ConvertFromUtf32(0xE0c6)
$sl.PromptSymbols.SegmentFinishSymbol            = [char]::ConvertFromUtf32(0xE0bc)
$sl.PromptSymbols.SegmentSeparatorForwardSymbol  = [char]::ConvertFromUtf32(0xE0B1)
$sl.PromptSymbols.SegmentSeparatorBackwardSymbol = [char]::ConvertFromUtf32(0xE0B3)
$sl.PromptSymbols.FailedCommandSymbol            = [char]::ConvertFromUtf32(0x2573)

# ﮟﳐ
$sl.PromptSymbols.homeChars = (
    [char]::ConvertFromUtf32(0x2263), <# Extremally exact equal math symbol #>
    [char]::ConvertFromUtf32(0x25b6), <# Unicode graphics righ triangles - Black #>
    [char]::ConvertFromUtf32(0x25b7), <# Unicode graphics righ triangles - Framed #>
    <# Nerd fonts home icons #>
    [char]::ConvertFromUtf32(0xfb9f),
    [char]::ConvertFromUtf32(0xf7db),
    [char]::ConvertFromUtf32(0xf46d),
    [char]::ConvertFromUtf32(0xfcd0)
)

$sl.Colors.PromptForegroundColor = [ConsoleColor]::White
$sl.Colors.PromptSymbolColor = [ConsoleColor]::Cyan
$sl.Colors.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.Colors.GitForegroundColor = [ConsoleColor]::Black
$sl.Colors.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.Colors.WithBackgroundColor = [ConsoleColor]::Magenta
$sl.Colors.VirtualEnvBackgroundColor = [System.ConsoleColor]::Red
$sl.Colors.VirtualEnvForegroundColor = [System.ConsoleColor]::White
$sl.Colors.ClockForeground = [ConsoleColor]::DarkCyan
$sl.Colors.ClockBackground = [ConsoleColor]::Gray
$sl.Colors.SessionInfoBackgroundColor = [ConsoleColor]::DarkYellow
$sl.Colors.AdminIconForegroundColor = [consoleColor]::Blue
$sl.Colors.CommandFailedIconForegroundColor = [ConsoleColor]::Red

# PSReadLine
(Get-PSReadLineOption).ContinuationPrompt = "`u{e0b1}"
