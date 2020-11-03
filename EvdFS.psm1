
function stat($fName) {
    Get-ItemProperty $fName | Select-Object *
}

function .. { cd .. }
function ... { cd ..\.. }
function .... { cd ..\..\.. }

Set-Alias props -Value Get-ItemProperty
function attr($f) { (Get-ItemProperty $f).Attributes }

# Colored pretty wide list, like BASH ls
function .l {
    Param (
        # [System.IO.FileSystemInfo[]]
        [Parameter(ValueFromPipeline,position=0)] [String[]] $Path = '.',
        [Parameter(ValueFromPipelineByPropertyName)] [String[]] $LiteralPath,
    )
    # reset colors to defaults
    $r="`e[0m";
    # расширения "исполняемых" файлов
    $exe = $($env:PATHEXT.replace('.','').split(';'))
    Get-ChildItem $Path -Force $Force -Filter $Filter |
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

# Like GNU touch changes file lastWriteTime or create new file if it not exists

function touch {
  Param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Path = $PWD
  )
  foreach ($p in $Path) {
      if (Test-Path -LiteralPath $p) {
        (Get-Item -Path $p).LastWriteTime = Get-Date
      } else {
        New-Item -Type File -Path $p
      }
  }
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

# Lagacy naming
Set-Alias rmr rm2

function logMon($LogFilePath, $match = "Error") {
    Get-Content $LogFilePath -Wait | Where { $_ -Match $match }
}

function tail  {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Name,
        [int]$Last=5
    )
    Get-Content $Name -Last $Last
}
