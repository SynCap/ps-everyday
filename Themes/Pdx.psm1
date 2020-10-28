#requires -Version 2 -Modules posh-git

function Write-Theme {
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )

    $lastColor = $sl.Colors.PromptBackgroundColor
    $prompt = Write-Prompt -Object ($sl.PromptSymbols.StartSymbol) -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor

    #check the last command state and indicate if failed
    If ($lastCommandFailed) {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.FailedCommandSymbol)" -ForegroundColor $sl.Colors.CommandFailedIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    #check for elevated prompt
    If (Test-Administrator) {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.ElevatedSymbol) " -ForegroundColor $sl.Colors.AdminIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    if (Test-VirtualEnv) {
        $prompt += Write-Prompt $sl.PromptSymbols.SegmentStartSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor
        # $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.VirtualEnvSymbol) $(Get-VirtualEnvName)" -ForegroundColor $sl.Colors.VirtualEnvForegroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol)" -ForegroundColor $sl.Colors.VirtualEnvBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }
    else {
        $prompt += Write-Prompt $sl.PromptSymbols.SegmentStartSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor
        # $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }

    # Writes the drive portion
    $path = ' '
    $path += (Get-FullPath -dir $pwd).Replace('\', $sl.PromptSymbols.PathSeparator) + ' '
    $prompt += Write-Prompt -Object $path.PadLeft(13,' ') -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor

    $status = Get-VCSStatus
    if ($status) {
        $themeInfo = Get-VcsInfo -status ($status)
        $lastColor = $themeInfo.BackgroundColor
        $prompt += Write-Prompt -Object $($sl.PromptSymbols.SegmentForwardSymbol) -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $lastColor
        $prompt += Write-Prompt -Object " $($themeInfo.VcInfo) " -BackgroundColor $lastColor -ForegroundColor $sl.Colors.GitForegroundColor
    }

    # Writes the postfix to the prompt
    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor

    $timeStamp = Get-Date -Format "HH:mm:ss"
    $timestamp = " $timeStamp "

    $prompt += Set-CursorForRightBlockWrite -textLength ($timestamp.Length+1)
    $prompt += Write-Prompt $sl.PromptSymbols.SegmentBackwardSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor
    $prompt += Write-Prompt $timeStamp -BackgroundColor $sl.Colors.PromptBackgroundColor -ForegroundColor $sl.Colors.PromptSymbolColor
    $prompt += Write-Prompt $sl.PromptSymbols.SegmentFinishSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor

    $prompt += Set-Newline

    if ($with) {
        $prompt += Write-Prompt -Object "$($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
    }
    $prompt += Write-Prompt -Object ($sl.PromptSymbols.PromptIndicator) -ForegroundColor $sl.Colors.PromptSymbolColor
    $prompt += ' '
    $prompt
}

$sl = $global:ThemeSettings #local settings
$sl.PromptSymbols.StartSymbol = '' # [char]::ConvertFromUtf32(0x9889)
$sl.PromptSymbols.PromptIndicator = [char]::ConvertFromUtf32(0xE0B1) #(0x276F) - ❯
$sl.PromptSymbols.PathSeparator = ' {0} ' -f [char]::ConvertFromUtf32(0xe0bb)
$sl.PromptSymbols.SegmentStartSymbol = [char]::ConvertFromUtf32(0xE0b2)
$sl.PromptSymbols.SegmentForwardSymbol = [char]::ConvertFromUtf32(0xE0bc)
$sl.PromptSymbols.SegmentBackwardSymbol = [char]::ConvertFromUtf32(0xE0be)
$sl.PromptSymbols.SegmentFinishSymbol = [char]::ConvertFromUtf32(0xE0b8)
# $sl.PromptSymbols.Chevron = [char]::ConvertFromUtf32(0xE0b1)

#       
# a0 a1 a2 a3
#                               
# b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf
#                               
# c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf
#         
# d0 d1 d2 d3 d4 -E6-

$sl.Colors.PromptForegroundColor = [ConsoleColor]::White
$sl.Colors.PromptSymbolColor = [ConsoleColor]::Cyan
$sl.Colors.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.Colors.GitForegroundColor = [ConsoleColor]::Black
$sl.Colors.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.Colors.WithBackgroundColor = [ConsoleColor]::Magenta
$sl.Colors.VirtualEnvBackgroundColor = [System.ConsoleColor]::Red
$sl.Colors.VirtualEnvForegroundColor = [System.ConsoleColor]::White
