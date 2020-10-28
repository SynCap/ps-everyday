
##############################################################################
# folder tree navigation
#

# Управление сессионной переменной окружения PATH
function .pc {$env:Path.Split(';')[-3..-1]}
function .pp {if($env:Path -NotLike "*;$(pwd)"){$env:Path+=";$(pwd)"};.pc}
function .pd {$env:Path=$env:Path.Split(';')[0..-2].Join(';');.pc}

function .. { cd .. }
function ... { cd ..\.. }
function .... { cd ..\..\.. }

Set-Alias _path -Value Resolve-Path

function stat($fName) {
    Get-ItemProperty $fName | Select-Object *
}

function Get-PathInfo($path) {
    if ($path  -match '^(?<path>(?<drive>.*:)?.*[\\/])?(?<filename>(?<basename>[^\\/]*)(?<extension>\.[^.]*?))$') {
        $Info = @{
            FullName = $Matches.0;
            Drive = $Matches.drive;
            Path = $Matches.path;
            BaseName = $Matches.BaseName;
            Extension = $Matches.extension;
            Name = $Matches.filename;
        };
        $Info.ParentName = $Info.Path.Split('[\\/]')[-1]
    }
    $Info
}

Set-Alias props -Value Get-ItemProperty
function attr($f) { (Get-ItemProperty $f).Attributes }

##############################################################################
# file system utils

# Colored pretty wide list, like BASH ls
function .l {
    Param (
        [Parameter(ValueFromPipeline=$true,position=0)]
        # [System.IO.FileSystemInfo[]]
        [String[]]
        $Path = '.'
    )
    # reset colors to defaults
    $r="`e[0m";
    # расширения "исполняемых" файлов
    $exe = $($env:PATHEXT.replace('.','').split(';'))
    Get-ChildItem $Path |
        %{
            $f = $_ # внутри switch: $_ ~~ проверяемое значение
            if ( $f.Name.Split('.')[-1] -in $exe ) {
                $c = 36; # запускаемые файлы
            } else {
                $c = 32; # базовый цвет = 32 -- тёмно-зелёный (Green `e[32m)
                switch -regex ($f.Mode) {
                    'd' {$c += 60} # папки более якрике - 30+60 = `e[92m
                    'h' {$c += 4} # смещаем цвет в Teal/Cyan 36/96
                }
            }
            @{('{0}{1}{2}' -f "`e[${c}m",$_.PSChildName,"`e[0m") = ''}
        } | Format-Wide -AutoSize
}

# Like PS's ls but with extra sort
function .ll {
    param (
        [Parameter(Position=0,ValueFromPipeline=$true)]$Path,
        [Alias('f')][Switch]$Force = $false,
        [Alias('h')][Switch]$Hidden = $false
    )
    Get-ChildItem $Path -Force:$Force -Hidden:$Hidden | `
        Sort-Object `
            @{Expression='Mode';Descending=$true},`
            @{Expression='Extension';Descending=$false},`
            @{Expression='Name'}
}

function touch {
  Param(
    [Parameter(Mandatory=$true)]
    [string]$Path
  )

  if (Test-Path -LiteralPath $Path) {
    (Get-Item -Path $Path).LastWriteTime = Get-Date
  } else {
    New-Item -Type File -Path $Path
  }
}

# разворачивает %<строки>%
function .spf ($s) {
    $keys = [Enum]::GetNames([System.Environment+SpecialFolder])
    if ($s -in $keys) {
        [Environment]::GetFolderPath($s)
    } else {
        [Enum]::GetNames([System.Environment+SpecialFolder]).GetEnumerator() | sort
    }
}

function .exp ($s) {[System.Environment]::ExpandEnvironmentVariables($s)}

function .exps ($s) {
    $re = '%\$(?<sdir>.*?)%';
    while ($s -Match $re) {
        $_.dir
    }
    $s = $s -Match '%\$(?<sdir>.*?)%'?$Matches.sdir:$s
}

# Аналог GNU uname или DOS ver
function ver {
    $Properties = 'Caption', 'Version', 'BuildType', 'OSArchitecture', 'CSName', 'RegisteredUser', 'SerialNumber';
    Get-CimInstance Win32_OperatingSystem | Select-Object $Properties
}

# Аналог башевской which, вычисляем полный путь + расширение
function which($cmd) {
    $o = (Get-Command $cmd);
    ($o.Path.Count -eq 1) ? $o.Path : $o.Definition
}

# Рекурсивное удаление нескольких папок/файлов
# Полный путь из относительного
# @example:
# cwd == 'C:\User\Name'
# Пишет чего убить собрался, матерится если нет папки/файла, но прёт дальше
# @example: rmr dist,.cache
# @example: rmr( 'dist', '.cache' )
# @example: rmr .dist , .cache

function rm2($f) {
    $f | ForEach-Object{
        $p = _path($_);
        if (Test-Path $p) {
            draw 'Remove ';
            draw $p,$lf Yellow;
            Remove-Item $_ -Force -Recurse
        } else {
            draw 'Nothing like ' DarkRed;
            draw $p,$lf Red
        }
    }
}

Set-Alias rmr rm2

# ❯ echo "Line feed$lf here"
# Line feed
#  here
$lf = [System.Environment]::NewLine

# ❯ echo "line feed$(lf)here"
# line feed
# here
function lf {[System.Environment]::NewLine}

function hr($Char = '-', [int]$Count = 0) {$Char * ($Count ? $Count : $Host.UI.RawUI.WindowSize.Width)}

# цветной вывод c поддержкой встроенных цветов PowerShell'a
function draw {
    param (
        [Parameter(Mandatory, Position=0)]
        [string[]]$Text,
        [Parameter(Position=1)]
        $Fg = $Host.UI.RawUI.ForegroundColor,
        [Parameter(Position=2)]
        $Bg = $Host.UI.RawUI.BackgroundColor
    )
    Write-Host $Text -ForegroundColor $Fg -BackgroundColor $Bg -NoNewline
}

function print($Params){Write-Host -NoNewLine ($Params -join '')}
function println($Params){print $Params;""}

# ANSI colors table
function Show-AnsiColors {
    # $g = ' ' * (( $Host.UI.RawUI.WindowSize.Width - 80 ) / 9 ); # gutter for wide window
    print "`e[0m",(hr _ 80)
    foreach ($j in 40..47 + 100..107) {
        '';foreach ($i in 30..37) {print ' ',"`e[$i;$j","`me[$i;$j`m",($j -gt 47 ?'':' '),"`e[0m"};
        '';foreach ($i in 90..97) {print ' ',"`e[$i;$j","`me[$i;$j`m",($j -gt 47 ?'':' '),"`e[0m"};
    }
    # print "`e[0m",(hr `– 80),`n
}

<#
.Synopsys
Quick info about current screen settings
#>
function .scr([switch]$c) {cls;$host.ui.RawUI;if($c){Show-AnsiColors}}

function logMon($LogFilePath, $match = "Error") {
    Get-Content $LogFilePath -Wait | Where { $_ -Match $match }
}

set-alias grep -Value Select-String -Force
filter mgrep {
    param {
        [Alias('patt','p')]
        $Pattern,
        [Alias('c')]
        $Color = "`e[97m"
    }
    $_ | Select-String $patt | %{$_ -replace "($patt)", "$Color`$1`e[0m"}
}

##############################################################################
##############################################################################
# GIT utils

# make .gitignore file here via gitignore.io
#
# show posible configuratios list
# @example: gitignore list
#
# make common configuration
# @example: gitignore windows,macos,node
function gIgnore($mode) {
    curl -L -s "https://www.gitignore.io/api/$([string]$mode)"
}

function gAddIgnore($mode = 'universal', [Alias('n')] [Switch]$New) {
    Switch ($mode) {
        'list' {gIgnore list;return};
        'universal' {$rules = 'windows,linux,macos,visualstudiocode,sublimetext,vim'}
        default {$rules = $mode}
    }

    if ($New) {
        gIgnore $rules > .gitgnore
    } else {
        gIgnore $rules >> .gitgnore
    }

    print "`e[93;40m",".gitignore","`e[0m"," from ","`e[96;40m","gitignore.io","`e[om`n"
    "-" * 35
    println ($New ? "Created new:" : "Added:") -ForegroundColor Yellow
    $mode | Sort-Object
}

# initialize git repository here
function InitGitRepo($remoteUrl) {

    Get-Date;
    hr;

    # create .gitignore file if not exists
    if (-Not (Test-Path '.gitignore')) {
        draw "Create new " DarkRed;
        draw " .gitignore " Red Yellow;
        echo "";
        gIgnore 'windows,linux,macos,visualstudiocode,sublimetext,vim,node' > '.\.gitignore';
        "$(lf)# Parcel$(lf)/dist/$(lf)/.cache/$(lf)" >> './.gitignore';
        & $env:EDITOR .gitignore;
        hr;
    }

    # init repository in current directory and push it to origin

    git init

    git add .
    git commit -m 'init'

    if ( $remoteUrl -ne $null ) {
        hr
        git remote add origin $remoteUrl
        git push -u origin master
    }

    hr

    git checkout -b develop

    git log
    git branch --all

    echo $(lf)
}

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
    rmr('.nuxt/','dist/','node_modules/.cache/')
}

function clrParcel {
    rmr('.cache/','dist/')
}

function nxt {
    clrNuxt;
    node .\node_modules\nuxt\bin\nuxt.js
}

function pcl {
    clrParcel;
    node .\node_modules\parcel\bin\cli.js
}

function dev {
    cls;
    yarn dev
}

function bld {
    yarn build
}

# ----------------------------------------------------------------------------
##############################################################################
# History and Keyboard helpers and options

# function _h($id) {
#     if ($id -eq $null) {
#         Get-History
#     } else {
#         Invoke-History $id
#     }
# }
# Set-Alias h -Value _h

# function h. {
#     Clear-History
#     # rm (Get-PSReadLineOption | select -ExpandProperty HistorySavePath)
# }

# загрузить в Sublime тему от o-my-posh
function Edit-Theme ($name) {
    Get-Theme | Where-Object Name -ilike $name | %{
        Write-Verbose "Open theme `"{0}`" in SublimeText`n{1}" -f $_.Name,$_.Location
        subl $_.Location
    }
}

# задержка вывода построчно
# использование: SlowMotion proga.exe
function SlowMotion { process { $_; Start-Sleep -seconds .5}}

# demo для PSReadLine
# куча всяких фишек а-ля редактор
function ImportKbExtra {
    $fName = Join-Path (stat $PROFILE).DirectoryName kb.ps1 -Resolve
    . $fName
}

Set-PSReadLineOption -EditMode Vi

Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+a -Function GotoFirstNonBlankOfLine

Set-PSReadLineOption -HistorySearchCursorMovesToEnd

Set-Alias subl -Value "C:\Program Files\Sublime Text 3\subl.exe"

##----------------------------------------------------------------------------
##############################################################################
# HELP shortcuts

function whelp ($what) {Get-Help $what -ShowWindow}
function ohelp ($what) {Get-Help $what -Online}
Set-Alias whlp -Value whelp


# Register-EngineEvent PowerShell.Exiting -Action { "Exiting $(Get-Date)" >> C:\TEMP\log.txt }