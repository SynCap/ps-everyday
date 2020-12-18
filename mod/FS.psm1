$RC = "`e[0m"

function stat($fName) {
    Get-ItemProperty $fName | Select-Object *
}

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

Set-Alias props -Value Get-ItemProperty
function attr($f) { (Get-ItemProperty $f).Attributes }

# Colored pretty wide list, like BASH ls
function ls. {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,position=0)] [String[]] $Path = '.'
        #,
        # [Parameter(ValidateSet('Hidden','Directory','System','Archive', ...))]
        # [Alias('Attr','a')][String[]] $Attributes,
        # [Parameter(ValidateRange(0,20))]
        # [Alias()][int] $Cols = 0
    )
    Process {

        # расширения "исполняемых" файлов
        $exe = $($env:PATHEXT.replace('.','').split(';'))
        Get-ChildItem $Path @PSBoundParams |
            ForEach-Object {
                $f = $_ # внутри switch: $_ ~~ проверяемое значение
                if ( $f.Name.Split('.')[-1] -in $exe ) {
                    $c = 33; # запускаемые файлы (EXE;COM;BAT;CMD;... ;PS1 :) )
                    $b = 44;
                } else {
                    $c = 32; # базовый цвет = 32 -- тёмно-зелёный (Green `e[32m)
                    $b = 40;
                }
                switch -regex ($f.Mode) {
                    'd' {$c += 60} # папки более якрике - 30+60 = `e[92m
                    'h' {$c += 4} # смещаем цвет в Teal/Cyan 36/96
                }
                $color = "`e[$c;${b}m"
                @{('{0}{1}{2}' -f $color,$_.PSChildName,$RC) = ''}
            } | Format-Wide @PSBoundParams
    }
}

# Like PS's ls but with extra sort
function ll {
    param (
        [Parameter(Position=0,ValueFromPipeline=$true)]$Path,
        [Alias('f')][Switch]$Force = $false,
        [Alias('h')][Switch]$Hidden = $false
    )

    Process {
        Get-ChildItem $Path -Force:$Force -Hidden:$Hidden | `
            Sort-Object `
                @{Expression='Mode';Descending=$true},`
                @{Expression='Extension';Descending=$false},`
                @{Expression='Name'} |`
            Format-Table `
                Mode,
                LastWriteTime,
                @{l='Size';e={'Directory' -in $_.Attributes ? '' : ( 2kb -gt $_.Length ? ('{0,7} ' -f $_.Length) : ('{0,7:n1}k' -f ($_.Length/1kb)) )}},
                @{l='Name';e={"`e[32m{0}$RC" -f $_.BaseName}},
                @{l='Ext';e={($_.Extension.Length)?$_.Extension.Substring(1):''}},
                FullName `
                -AutoSize
    }
                # @{l='Size';e={('Directory' -in $_.Attributes)?'':"{0:d}" -f $($_.Length/1kb)}},
}

# Like GNU touch changes file lastWriteTime or create new file if it not exists

function touch {
    Param(
    [Parameter(ValueFromPipeline)] [string[]] $Path = $PWD
    )
    PROCESS {
      foreach ($p in $Path) {
          if (Test-Path -LiteralPath $p) {
            (Get-Item -Path $p).LastWriteTime = Get-Date
          } else {
            New-Item -Type File -Path $p
          }
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

function rmr {
    param ([Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,position=0)][String[]]$Path='.\*')
    Resolve-Path $Path -ErrorVariable rmrErr -ErrorAction 'SilentlyContinue' | ForEach-Object{
        print 'Remove ';
        print "`e[33m", $_ , "`t`e[6;32m→`e[0m"
        if (Test-Path $_){
            Remove-Item $_ -Force -Recurse -ErrorVariable rmrErr -ErrorAction 'SilentlyContinue'
            if ($rmrErr.Count) { $rmrErr | Foreach-Object { println "`b`e[31m",$_.Exception.Message,$RC } } else {println "`b… done"}
        } else {
            println "`b`e[36m",'not found',$RC
        }
    }
}

# Lagacy naming
Set-Alias rm2 rmr

function logMon($LogFilePath, $match = "Error") {
    Get-Content $LogFilePath -Wait | Where-Object { $_ -Match $match }
}

filter tail {
    param (
        [Parameter(Mandatory,ValueFromPipeline)] $Name,
        [int] $Last=5
    )
    Get-Content $Name -Last $Last
}

function Mount-Symlink ($Target, $Link) {
    New-Item -Path $Link -Value $Target -ItemType SymbolicLink
}

function ShortSize ($val) {
    switch ($val) {
        {$val -gt 1Gb} {return '{0:n1}G' -f ($val/1Gb)}
        {$val -gt 1Mb} {return '{0:n1}M' -f ($val/1Mb)}
        {$val -gt 1Kb} {return '{0:n1}k' -f ($val/1Kb)}
        default {return '{0:n0} ' -f $val}
    }
}

function Get-FreeSpace {
    [CmdletBinding()]
    Param (
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position=0,
            ValueFromRemainingArguments
        )] $Drive
    )

    [System.IO.DriveInfo]::GetDrives() |
        Where-Object {$_.IsReady -and $Drive -contains $_.Name} |
            ForEach-Object {
                if (!$_.TotalFreeSpace) {
                    $FreePct = 0
                    $Free = 0
                } else {
                    $FreePct = [System.Math]::Round(100 * $_.TotalFreeSpace / $_.TotalSize, 2)
                    $Free = ShortSize $_.TotalFreeSpace
                }

                New-Object -TypeName psobject -Property @{
                    Drive     = $_.Name
                    DriveType = $_.DriveType
                    '%' = $FreePct
                    'Space' = $Free
                }
            }
}

function urlget($url, $out) {
    (New-Object System.Net.WebClient).DownloadFile($url, $out)
}