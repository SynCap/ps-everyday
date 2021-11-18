
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
	curl -F "file=@$($f.FullName)" `
		http://sass2stylus.com/api `
		> "$OutDir\$($f.BaseName).styl"
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

function nuxt {
	node (Join-Path (Get-NodeProjectRoot) node_modules\nuxt\bin\nuxt.js) @Args
}

# function parcel {
# 	println 'Evd-Dev call Parcel'
# 	& (Join-Path (Get-NodeProjectRoot) node_modules\.bin\parcel.ps1) @Args
# 	# node (Join-Path (Get-NodeProjectRoot) node_modules\parcel\lib\cli.js) @Args
# }

# function vite {
# 	node (Join-Path (Get-NodeProjectRoot) node_modules\vite\bin\vite.js) @Args
# }

# Detect node package manager for project which
# current location belong to
# Neither recurson, neither FS Get-UpDirOf/Get-TopmostDirOf
# used due to not provide extra arguments or functionality
function Get-NodeProjectRoot {
	param(
		[Switch] $Topmost
	)
	function searchUp($p) {
		while(
			$p -and
			!(test-path (join-path $p.FullName 'package.json'))
		) {
			$p = $p.Parent
		};
		$p
	}
	$p = (Get-Item $pwd);
	if ($Topmost) {
		$stack = @();
		while($p) {$p = searchUp $p;if($p){$stack+=$p;$p=$p.Parent}}
		$p=$stack.Length ? $stack : $null
	} else {$p = searchUp $p}
	if (!$p) {
		throw "Not inside Node project"
	}
	$p
}
Set-Alias npr Get-NodeProjectRoot

# Detect node package manager for project which
# current location belong to and use that manager
# to launch exact command from `package.json`
# `script` section.
# Deprecated. Use `Start-NodePackages` directly
function Start-PackageJsonScript {
	[CmdletBinding( SupportsShouldProcess = $true )]
	param(
		[string] $Cmd
	)
	Start-NodePackage $Cmd @Args -RunScript
}

# Detect node package manager for project which
# current location belong to, detect package manager
# and use it to run installed package or run package
# script
function Start-NodePackage {
	[CmdletBinding( SupportsShouldProcess = $true )]
	param(
		# Installed package having starter in `node_modules/bin` name
		# Or name of the script specified in `scripts` section of
		# `package.json` file
		[Parameter(position=0)][String] $Cmd,
		# Parameters to be passed to package manager
		[parameter(Mandatory=$False,Position=1,ValueFromRemainingArguments=$True)]
		[Object[]] $Arguments,
		# What project root to use closest to current location or
		# the topmost one
		[Switch] $Topmost,
		# Run script specified in `package.json` instead of package
		# (package starter script from `node_modules/bin` - package
		# managers looks for it by themself)
		[Switch] $RunScript
	)
	Write-Debug "Script name to be run: `e[7m $Cmd `e[0m"
	Push-Location (Get-NodeProjectRoot -Topmost:$Topmost)
	println ("Project root directory: `e[97;7m {0} `e[0m" -f $pwd.Path)
	Write-Debug "`e[36m``package.json```e[0m found at `e[7;36m $pwd `e[0m"
	$r = ((Test-Path 'yarn*') ?
			'yarn' :
			((Test-Path pnpm-*) ?
				'pnpm' :
				 'npm')),($RunScript ? 'run' :  'start'),$Cmd;
	$cmdParams = $r[1,-1] + $Arguments
	println "Command line: `e[7m $($cmdParams -join ' ') `e[0m"
	if ($PSCmdlet.ShouldProcess($R -join ' ', 'Use command line')) {
		& $r[0] @cmdParams
	}
	Pop-Location
}

Set-Alias run Start-PackageJsonScript `
	-Description "Start script from ``package.json`` `
		of current project. `
		See: ``Get-Help Start-PackageJsonScript``"

function dev {
	Start-NodePackage 'dev' @Args -RunScript
}

function stg {
	Start-NodePackage 'stage' @Args -RunScript
}

function bld {
	Start-NodePackage 'build' @Args -RunScript
}

function srv {
	Start-NodePackage 'serve' @Args -RunScript
}

function gen {
	Start-NodePackage 'generate' @Args -RunScript
}

function stt {
	Start-NodePackage 'start' @Args -RunScript
}

function nstt {
	Start-NodePackage @Args
}

# загрузить в Sublime тему от o-my-posh
function Edit-Theme ($name) {
	Get-Theme | Where-Object Name -ilike $name | ForEach-Object {
		Write-Verbose "Open theme `"{0}`" in SublimeText`n{1}" `
			-f $_.Name,$_.Location
		subl $_.Location
	}
}

Set-Alias pp -Value 'pnpm' -Description 'Perfect Packager: Just alias for `e[97;7m PNPM `e[0m 😜'
Set-Alias px -Value 'pnpx' -Description 'Perfect eXecutor: Just alias for `e[97;7m PNPX `e[0m 😜'

# Draw QR code for NUXT dev server at local machine
function Show-NuxtDevQR {
	qrcode "URL:http://$(localIP):$($env:NUXT_PORT)"
}
