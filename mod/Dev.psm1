
##############################################################################
##############################################################################
# DEV Common Tasks

function sass2styl($f, [string]$OutDir = '.') {
    draw 'Convert file: '
    draw $f.FullName Cyan
    echo ''
    if ($f.Extension -ne '.scss') {
        Write-Warning 'Extension is not SCSS!'
    }
    curl -F "file=@$($f.FullName)" http://sass2stylus.com/api > "$OutDir\$($f.BaseName).styl"
}

function clrNuxt {
    rmr .nuxt/*,dist/*,node_modules/.cache/*
    rmr .nuxt,dist,node_modules/.cache
    if ($Global:Error.Count) {
        errm.
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

function dev {
    yarn dev
}

function bld {
    yarn build
}

# загрузить в Sublime тему от o-my-posh
function Edit-Theme ($name) {
    Get-Theme | Where-Object Name -ilike $name | ForEach-Object {
        Write-Verbose "Open theme `"{0}`" in SublimeText`n{1}" -f $_.Name,$_.Location
        subl $_.Location
    }
}
