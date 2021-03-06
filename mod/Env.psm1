# Управление сессионной переменной окружения PATH
# для быстрого добавления текущей папки в PATH
# работает только в текущей сессии
function eps {$env:Path.Split(';')[-3..-1]}
function epp {if($env:Path -NotLike "*;$pwd"){$env:Path+=";$pwd"};eps}
function epd {$env:Path=$env:Path.Split(';')[0..-2].Join(';');eps}

# PowerShell:PSAvoidGlobalVars=$False
$Script:EvdSPF = @{}

function spf ($SpecialFolderAlias) {
	if ($SpecialFolderAlias) {
		[Environment]::GetFolderPath($SpecialFolderAlias)
	} else {
		if (1 -gt $Script:EvdSPF.Count) {
			[Enum]::GetNames([System.Environment+SpecialFolder]).GetEnumerator().forEach({
				$Script:EvdSPF.Add($_, [Environment]::GetFolderPath($_))
			})
		}
		$Script:EvdSPF.GetEnumerator() | Select-Object Name,Value | Sort-Object Name
	}
}

# разворачивает %$<строки>%
function exp ($s) {[System.Environment]::ExpandEnvironmentVariables($s)}

function .exps ([parameter(ValueFromPipeline)][string]$s) {
	$re = '#\(\s*(\w+?)\s*\)'
	$s -replace $re, {
		try{
			[Environment]::GetFolderPath($_.Groups[1].Value)
		} catch {
			''
		}
	}
}

function def($Cmd){(Get-Command $Cmd -ErrorAction SilentlyContinue).Definition}

# Аналог GNU uname или DOS ver
function ver {
	$Properties = 'Caption', 'Version', 'BuildType', 'OSArchitecture', 'CSName', 'RegisteredUser', 'SerialNumber';
	Get-CimInstance Win32_OperatingSystem | Select-Object $Properties
}

function which($cmd) {
	<#
		.synopsis
			Shortcut of Get-Command
			Аналог башевской which, вычисляем полный путь + расширение
		.Description
			BASH's `which` command analogue, return full path and extension in case of file, or content of
			function/commandlet. Get-Command used under hood.
	#>
	$o = (Get-Command $cmd -ErrorAction 'SilentlyContinue');
	if ([System.Management.Automation.CommandTypes]::Application -eq $o.CommandType){
		$o.Path
	} else {
		"[{0}]" -f $o.CommandType
		if ($o.Source) {"Source`t: {0}" -f $o.Source }
		if ($o.HelpUri) {"helpUri`t: {0}" -f $o.HelpUri }
		"`e[36m{0}`e[0m" -f $o.Definition
	}
}

function TCmd {
	<#
	.Synopsis
		Open folder on Total Commander
	.Description
		Open directory or in Total Commander in new tab within active panel.
		If $Path specifies the file, open folder and select that file if exists.
	#>
	param([Parameter(ValueFromPipeline)] $Path = '.')

	process {
		$Cmd = Join-Path $env:ProgramFiles 'totalcmd\TOTALCMD64.EXE'
		$Params =  @( '/O','/T','/S', (Resolve-Path $Path).Path )
		& $Cmd $Params
	}
}

function lg {
	[Console]::Write("`ec")
	lazygit.exe
	[Console]::Write("`ec")
}

$Global:subl = $Env:Editor
Set-Alias subl ($Env:Editor)

Set-Alias gvim -Value "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Vim 8.2\gVim.lnk"

function Get-UPath {
	param (
		[Parameter(
					position=0,ValueFromPipeline,ValueFromPipelineByPropertyName
					)]
				[string[]] $Path,
		[Parameter(
					ValueFromPipelineByPropertyName
					)]
				[Switch] $MntPrefix
	)
	process {
		foreach ($p in (Resolve-Path $Path)) {
			($MntPrefix ? '/mnt/' : '/') + ((Resolve-Path $p) -replace '\\','/') -replace '(\w+):',{$_.Groups[1].Value.ToLower()}
		}
	}
}

Set-Alias upath -Value Get-UPath

function ErrM {
	print "`e[31m"
	$Global:Error | ForEach-Object {$_.Exception.Message} | Sort-Object -Unique | ForEach-Object {">`n$_"}
	print $RC
}

function ErrC { $Global:Error.Clear() }

function Select-InExplorer($path) { explorer.exe /select, "`"$(Resolve-Path $path)`""}
function Open-InExplorer($path) { explorer.exe /e, "`"$(Resolve-Path $path)`""}

function Get-DeepHistory {
	Get-Content (Get-PSReadlineOption).HistorySavePath
}

Set-Alias hh -Value Get-DeepHistory -Description 'Show inter sessions PSReadline history'

function .sp {
	[CmdletBinding()]
	param (
		[Parameter(position=0)] [String] $Name,
		[Parameter(position=1)] [String] $Dir = $PWD
	)
	if (Test-Path $Name -ErrorAction SilentlyContinue) {
		$Name,$Dir = $null,$Name
	}
	Write-Verbose "Profile name: $Name"
	Write-Verbose "Target dir: $Dir"
	$Params = "sp -d $Dir$($Name ? " -p $Name" : '')"
	Write-Verbose "Command: wt $Params"
	& wt ($Params -split ' ')
}
