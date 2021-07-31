
##############################################################################
##############################################################################
# DEV Common Tasks

function sass2styl($f, [string]$OutDir = '.') {
	draw 'Convert file: '
	draw $f.FullName Cyan
	''
	if ($f.Extension -ne '.scss') {
		Write-Warning 'Extension is not SCSS!'
	}
	curl -F "file=@$($f.FullName)" http://sass2stylus.com/api > "$OutDir\$($f.BaseName).styl"
}

function clrNuxt {
	rmr .nuxt/*,dist/*,node_modules/.cache/*
	rmr .nuxt,dist,node_modules/.cache
	if ($Global:Error.Count) {
		errm
	}
}

function clrParcel {
	rmr .cache/*,dist/*
	rmr .cache,dist
}

function nxt {
	node $Pwd\node_modules\nuxt\bin\nuxt.js @Args
}

function pcl {
	node $Pwd\node_modules\parcel\bin\cli.js @Args
}

function vite {
	node $PWD\node_modules\vite\bin\vite.js @Args
}

# Detect node package manager for project which
# current location belong to and use that manager
# to launch exact command from `package.json`
# `script` section
function Start-PackageJsonScript {
	[CmdletBinding( SupportsShouldProcess = $true )]	param(
		[String] $Cmd
	)
	Write-Debug "Script name to be run: `e[7m $Cmd `e[0m"
	$p=$pwd;while(!(test-path (join-path $p package.json))) {$p = $p.Directory};$p;
	Write-Debug "`e[36m``package.json```e[0m found at `e[7m $p `e[0m"
	$r = (Test-Path yarn.lock) ?
			'yarn',$Cmd :
			((Test-Path pnpm-lock.yaml) ?
				'pnpm',$Cmd :
				 'npm','run',$Cmd)
	Write-Debug "Command line: `e[7m $($r -join ' ') `e[0m"
	if ($PSCmdlet.ShouldProcess($R -join ' ', 'Use command line')) {
		& $r[0] @($r[1,-1] + $Args)
	}
}

Set-Alias nrun Start-PackageJsonScript -Description 'Start script from ``package.json`` of current project. See: ``Get-Help Start-PackageJsonScript``'

function dev {
	Start-PackageJsonScript 'dev'
}

function stg {
	Start-PackageJsonScript 'stage'
}

function bld {
	Start-PackageJsonScript 'build'
}

function gen {
	Start-PackageJsonScript 'build'
}

function start {
	Start-PackageJsonScript 'build'
}

# загрузить в Sublime тему от o-my-posh
function Edit-Theme ($name) {
	Get-Theme | Where-Object Name -ilike $name | ForEach-Object {
		Write-Verbose "Open theme `"{0}`" in SublimeText`n{1}" -f $_.Name,$_.Location
		subl $_.Location
	}
}

Set-Alias pp -Value 'pnpm' -Description 'Just alias for PNPM 😜'
Set-Alias ppx -Value 'pnpx' -Description 'Just alias for PNPX 😜'
