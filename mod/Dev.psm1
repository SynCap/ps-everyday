
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

function Start-PackageJsonScript([String] $Cmd) {
	$r = (Test-Path yarn.lock) ?
			'yarn',$Cmd :
			((Test-Path pnpm-lock.yaml) ?
				'pnpm','run',$Cmd :
				 'npm','run',$Cmd)
	& $r[0] $r[1,-1]
}

function dev {
	Start-PackageJsonScript 'dev'
}

function stg {
	Start-PackageJsonScript 'stage'
}

function bld {
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