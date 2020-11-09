[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='Script')]

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Bars')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'PowerLineSymbols')]

# ❯ echo "Line feed$lf here"
# Line feed
#  here
$lf = [System.Environment]::NewLine

# ❯ echo "line feed$(lf)here"
# line feed
# here
function lf {[System.Environment]::NewLine}

function .c {
    param (
        [Alias('f')][Parameter(position=0)] [int] $FgColor,
        [Alias('b')][Parameter(position=1)] [int] $BgColor
    )
    if($FgColor && $BgColor) {
        "`e[${FgColor};${BgColor}m"
    } else {
        if ($FgColor) { "`e[${FgColor}m"}
        if ($BgColor) { "`e[${BgColor}m"}
    }
}

function .cls {[Console]::Write("`ec")}

function hr{
    param(
        [Alias('c')][Parameter(position=0)][String] $Char =
            [Char]::ConvertFromUtf32(0x2013), # En dash

        [Alias('q')][Parameter(position=1)][Single] $Count = .4 # ≈40% of window width
    )
    switch ($Count) {
        0 {$Count = $Host.UI.RawUI.WindowSize.Width;Break}
        {$_ -lt 1} {$Count = $Host.UI.RawUI.WindowSize.Width * $Count -bor 0;Break}
    }
    $Char * $Count
}

# цветной вывод c поддержкой встроенных цветов PowerShell'a
function draw {
    param (
        [Parameter(Mandatory, Position=0)]
        [string[]]$Text,
        [Alias('Foreground', 'ForegroundColor')] [Parameter(Position=1)]
        $FG = $Host.UI.RawUI.ForegroundColor,
        [Alias('Background', 'BackgroundColor')] [Parameter(Position=2)]
        $BG = $Host.UI.RawUI.BackgroundColor
    )
    Write-Host $Text -ForegroundColor $FG -BackgroundColor $BG -NoNewline
}

function print([Parameter(ValueFromPipeline)][String[]]$Params){[System.Console]::Write($Params -join '')}
function println([Parameter(ValueFromPipeline)][String[]]$Params){[System.Console]::WriteLine($Params -join '')}

# ANSI colors table
function Show-AnsiColorSample {
    param (
        [Alias('l')] $Lines = ( 40..47 + 100..107 )
    )
    print "`e[0m",(hr _ 80)
    foreach ($j in $Lines) {
        '';foreach ($i in 30..37){print ' ',"`e[$i;$j","`me[$i;$j`m",(($j -gt 47) ? '' : ' '),"`e[0m"};
        '';foreach ($i in 90..97){print ' ',"`e[$i;$j","`me[$i;$j`m",(($j -gt 47) ? '' : ' '),"`e[0m"};
    }
}
Set-Alias -Name shansi -Value Show-AnsiColorSample

<#
.Synopsys
Quick info about current screen settings
#>
function .scr([switch]$c) {cls;$host.ui.RawUI;if($c){Show-AnsiColors}}

$Global:PowerLineSymbols = @(
    "`t       ",
    "`ta0 a1 a2 a3 ",
    "`t                               ",
    "`tb0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf ",
    "`t                               ",
    "`tc0 c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf ",
    "`t         ",
    "`td0 d1 d2 d3 d4 -E6- "
)

$Global:Bars = [char[]]'│┆┊┃┇┋≈‒–—―─━═╌╍▀▁▂▃▄▅▆▇█▉▊▋▌▍▎▏▐░▒▓▔'

# [Char]::ConvertFromUtf32(0x2248), # ≈ - Almost equal to
# [Char]::ConvertFromUtf32(0x2012), # Figure dash
# [Char]::ConvertFromUtf32(0x2013), # En dash
# [Char]::ConvertFromUtf32(0x2014), # 0151 — Em dash
# [Char]::ConvertFromUtf32(0x2015), # Horizontal bar
# [Char]::ConvertFromUtf32(0x2500), # Box drawing light horizontal
# [Char]::ConvertFromUtf32(0x2501), # Box drawing heavy horizontal
# [Char]::ConvertFromUtf32(0x2550), # Box drawing double horizontal
# [Char]::ConvertFromUtf32(0x254c), # Box drawing light double dash horizontal
# [Char]::ConvertFromUtf32(0x254d)  # Box drawing light heavy double dash horizontal


set-alias grep -Value Select-String -Force
filter mgrep {
    param {
        [Alias('patt','p')]
        $Pattern,
        [Alias('c')]
        $Color = "`e[97m"
    }
    $_ | Select-String $patt | ForEach-Object {$_ -replace "($patt)", "$Color`$1`e[0m"}
}

function EasyView($Seconds=.5) { process { $_; Start-Sleep -Seconds $Seconds}}
