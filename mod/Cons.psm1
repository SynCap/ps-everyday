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

# "Clear console" ANSI command
function c {[Console]::Write("`ec")}

# Generate ANSI Esc sequence to set console text color
function p {
	# [CmdletBinding()]
	param (
		[Alias('f')][Parameter(position=0)] [int] $FgColor = -1,
		[Alias('b')][Parameter(position=1)] [int] $BgColor = -1
	)
	if(0 -le $FgColor && 0 -le $BgColor) {
		"`e[${FgColor};${BgColor}m"
	} elseif (0 -le $FgColor) {
		"`e[$( $FgColor )m"
	} elseif (0 -le $BgColor) {
		"`e[${BgColor}m"
	}
	# Write-Debug "FG: ${FgColor}, BG: ${BgColor}"
}

function hr{
	param(
		[Alias('c')][Parameter(position=0)][String] $Char = "`u{2013}", # En dash

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
		[Alias('l')] [Parameter(position=0)] $Lines = ( 40..47 + 100..107 )
	)
	print "`e[0m",(hr _ 80)
	foreach ($j in $Lines) {
		'';foreach ($i in 30..37){print ' ',"`e[$i;$j","`me[$i;$j`m",(($j -gt 47) ? '' : ' '),"`e[0m"};
		'';foreach ($i in 90..97){print ' ',"`e[$i;$j","`me[$i;$j`m",(($j -gt 47) ? '' : ' '),"`e[0m"};
	}
}
Set-Alias -Name shansi -Value Show-AnsiColorSample

function Show-Ansi256([int]$mode=3) {
	if($mode -bor 1){
		$s=''; foreach($i in 0..255){ $s += (" `e[38;5;{0}m{0:d3}`e[0m {1}" -f $i,(($i+1) % 16?'':"`n")) };
		println $s
	}
	if($mode -bor 2){
		$s='';foreach($i in 0..255){ $s += ("`e[48;5;{0}m {0:d3} `e[0;30m{1}" -f $i,(($i+1) % 16?'':"`n")) };
		print $s,"`e[0m"
	}
}
Set-Alias -Name shansi2 -Value Show-Ansi256

<#
.Synopsys
Quick info about current screen settings
#>
function scr([switch]$c) {$host.ui.RawUI;if($c){Show-AnsiColorSample}}
function scrr{c;scr;shansi 40;'';hr}

function Show-PowerLineSymbols {
	"`t       "
	"`ta0 a1 a2 a3 "
	"`t                               "
	"`tb0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf "
	"`t                               "
	"`tc0 c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf "
	"`t         "
	"`td0 d1 d2 d3 d4 -E6- "
}

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
# [Char]::ConvertFromUtf32(0x254d)  # Box drawing light heavy double dash horz

function Show-Bars {
	$i=0
	$Global:Bars |
		ForEach-Object {
			@{$("{0,5:d}. 0x{1:x} : {2}" -f $i++,[int]$_,$_) = $_}
		} |
			Format-Wide -a
}

function Get-FlatArray ($Source) {
	$Source | ForEach-Object {$_} | Where-Object {$_ -ne $null}
}

function Get-NerdSymbols {

	$charList = ''
	$Diapasons = @(
		@(0XE000..0XE00A),
		@(0XE0A0..0XE0A5),
		@(0XE0B0..0XE0D4),
		@(0XE200..0XE2A9),
		@(0XE300..0XE3E3),
		@(0XE5FA..0XE62E),
		@(0XE700..0XE7C5),
		@(0XF000..0XF0B2),
		@(0XF0C0..0XF2E0),
		@(0XF300..0XF31C),
		@(0XF400..0XF4A9),
		@(0XF500..0XF8FF)
	)

	foreach ($D in $Diapasons) {
		foreach ($chr in $D) {

			# $charItem = @{
			#     Char = [char]$chr;
			#     Index = $chr;
			#     Hex = ('0x{0:x}' -f $chr)
			# }

			# $charList.Add($charItem)

			$charItem = "[`u{00a0}$(('{0:x}' -f $chr).ToUpper())`u{00a0}$([char]$chr)`u{00a0}]  "
			$charList += $charItem
		}
	}
	$charList
}

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

function m2 {
	param(
		[Parameter(ValueFromPipeline=$true)]
		[System.Management.Automation.PSObject]$InputObject
	)

	begin {
		$type = [System.Management.Automation.CommandTypes]::Cmdlet
		$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Out-Host', $type)
		$scriptCmd = {& $wrappedCmd @PSBoundParameters -Paging }
		$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
		$steppablePipeline.Begin($PSCmdlet)
	}

	process {
		try {
			$steppablePipeline.Process($_)
		}
		catch {
			break;
		}
	}

	end {
		$steppablePipeline.End()
	}

	#.ForwardHelpTargetName Out-Host
	#.ForwardHelpCategory Cmdlet
}
