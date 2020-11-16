
function stat($fName) {
    Get-ItemProperty $fName | Select-Object *
}

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

Set-Alias props -Value Get-ItemProperty
function attr($f) { (Get-ItemProperty $f).Attributes }

# Colored pretty wide list, like BASH ls
function .l {
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
                @{('{0}{1}{2}' -f $color,$_.PSChildName,"`e[0m") = ''}
            } | Format-Wide @PSBoundParams
    }
}

# Like PS's ls but with extra sort
function .ll {
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
                @{l='Name';e={"`e[32m{0}`e[0m" -f $_.BaseName}},
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
        print 'Remove ';
        println "`e[33m", $_ ,"`e[0m"
        Remove-Item $_ -Force -Recurse -ErrorVariable rmrErr -ErrorAction 'SilentlyContinue'
        $rmrErr | Foreach-Object{println "`e[31m",$_.Exception.Message}
    }
}

# Lagacy naming
Set-Alias rmr rm2

function logMon($LogFilePath, $match = "Error") {
    Get-Content $LogFilePath -Wait | Where-Object { $_ -Match $match }
}

filter tail  {
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
    Param()
    DynamicParam {
        # Get drive names for ValidateSet attribute
        $DriveList = ([System.IO.DriveInfo]::GetDrives()).Name

        # Create new dynamic parameter
        New-DynamicParameter -Name Drive -ValidateSet $DriveList -Type ([array]) -Position 0 -Mandatory
    }

    Process {
        # Dynamic parameters don't have corresponding variables created,
        # you need to call New-DynamicParameter with CreateVariables switch to fix that.
        New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

        $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object {$Drive -contains $_.Name}
        $DriveInfo |
            ForEach-Object {
            if (!$_.TotalFreeSpace) {
                $FreePct = 0
            } else {
                $FreePct = [System.Math]::Round(100 * $_.TotalFreeSpace / $_.TotalSize, 2)
            }
            New-Object -TypeName psobject -Property @{
                Drive     = $_.Name
                DriveType = $_.DriveType
                'Free(%)' = $FreePct
            }
        }
    }
}
