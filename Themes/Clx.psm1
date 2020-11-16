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

    $timestamp = "{0:HH}:{0:mm}:{0:ss}┋" -f (Get-Date)

    $prompt += Write-Prompt $timeStamp -BackgroundColor $sl.Colors.PromptBackgroundColor -ForegroundColor $sl.Colors.ClockForeground

    # Writes the Path portion
    $pathSeparator = $sl.promptSymbols.PathSeparatorSymbol
    $path = Get-FullPath -dir $pwd

    if ($path -eq '~') {
        $path = '   {0}   ' -f $sl.promptSymbols.homeChars[2]
    } else {
        if ($path.Length -lt [Console]::WindowWidth / 3) { $pathSeparator = " ${pathSeparator} " }
        if ($path.Length -gt [Console]::WindowWidth / 2) { $path = $path -replace '^(~|\w+:).*[/\\](.*)[\\/]?$','$1\ .. \$2' }
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

$sl = $global:ThemeSettings #local settings

$sl.PromptSymbols.StartSymbol                    = '' # [char]::ConvertFromUtf32(0x9889)
$sl.PromptSymbols.ElevatedSymbol                 = [char]::ConvertFromUtf32(0x26A1) # Hummer & Sickle
$sl.PromptSymbols.PromptIndicator                = [char]::ConvertFromUtf32(0xE0B1) #(0x276F) - ❯
$sl.PromptSymbols.PathSeparatorSymbol            = "`e[96m{0}`e[97m" -f [char]::ConvertFromUtf32(0xe0bb) # 0x2573
$sl.PromptSymbols.SegmentStartSymbol             = [char]::ConvertFromUtf32(0xE0ba)
$sl.PromptSymbols.SegmentBackwardSymbol          = [char]::ConvertFromUtf32(0xE0be)
$sl.PromptSymbols.SegmentForwardSymbol           = [char]::ConvertFromUtf32(0xE0c6)
$sl.PromptSymbols.SegmentFinishSymbol            = [char]::ConvertFromUtf32(0xE0bc)
$sl.PromptSymbols.SegmentSeparatorForwardSymbol  = [char]::ConvertFromUtf32(0xE0B1)
$sl.PromptSymbols.SegmentSeparatorBackwardSymbol = [char]::ConvertFromUtf32(0xE0B3)
$sl.PromptSymbols.FailedCommandSymbol            = [char]::ConvertFromUtf32(0x274C)

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
$sl.Colors.AdminIconForegroundColor = [consoleColor]::Black
$sl.Colors.CommandFailedIconForegroundColor = [ConsoleColor]::DarkRed
