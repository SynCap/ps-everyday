
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
	# Get Node project root
	$p=Get-Item $pwd;
	while(
		!(test-path (join-path $p.FullName 'package.json'))
	) {
		$p = $p.Directory
	};
	if (!$p) {
		throw "Not inside Node project"
	}
	println "Project directory: `e[33m",$p.FullName,"`e[0m";
	Push-Location $p
	Write-Debug "`e[36m``package.json```e[0m found at `e[7m $p `e[0m"
	$r = (Test-Path yarn.lock) ?
			'yarn',$Cmd :
			((Test-Path pnpm-lock.yaml) ?
				'pnpm','run',$Cmd :
				 'npm','run',$Cmd)
	Write-Debug "Command line: `e[7m $($r -join ' ') `e[0m"
	if ($PSCmdlet.ShouldProcess($R -join ' ', 'Use command line')) {
		& $r[0] @($r[1,-1] + $Args)
	}
	Pop-Location
}

Set-Alias run Start-PackageJsonScript -Description 'Start script from ``package.json`` of current project. See: ``Get-Help Start-PackageJsonScript``'

function dev {
	Start-PackageJsonScript 'dev' @Args
}

function stg {
	Start-PackageJsonScript 'stage' @Args
}

function bld {
	Start-PackageJsonScript 'build' @Args
}

function srv {
	Start-PackageJsonScript 'serve' @Args
}

function gen {
	Start-PackageJsonScript 'build' @Args
}

function start {
	Start-PackageJsonScript 'start' @Args
}

# загрузить в Sublime тему от o-my-posh
function Edit-Theme ($name) {
	Get-Theme | Where-Object Name -ilike $name | ForEach-Object {
		Write-Verbose "Open theme `"{0}`" in SublimeText`n{1}" -f $_.Name,$_.Location
		subl $_.Location
	}
}

Set-Alias pp -Value 'pnpm' -Description 'Perfect Packager: Just alias for `e[97;7m PNPM `e[0m 😜'
Set-Alias px -Value 'pnpx' -Description 'Perfect eXecutor: Just alias for `e[97;7m PNPX `e[0m 😜'
