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
                    'd' {$c += 60} # папки более яркике - 30+60 = `e[92m
                    'h' {$c += 4} # смещаем цвет в Teal/Cyan 36/96
                }
                $color = "`e[$c;${b}m"
                @{('{0}{1}{2}' -f $color,$_.PSChildName,$RC) = ''}
            } | Format-Wide -AutoSize
    }
}

# Like PS's ls but with
# Extra sort and
# More field control
filter ll {
    [CmdletBinding()]

    param (
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [String[]]
        $Path,

        [Switch] $Expand    = $false, # Expand Name --> Name + Ext + FullName
        [Switch] $Recurse   = $false,
        [Switch] $Force     = $false,
        [Switch] $Directory = $false,
        [Switch] $File      = $false,
        [Switch] $Hidden    = $false
    )

    $Fields = `
        'Mode',
        'LastWriteTime',
        @{l='Size';e={
                    'Directory' -in $_.Attributes ? '' :
                    ( 2kb -gt $_.Length ? ('{0,7:n0} ' -f $_.Length) :
                        2mb -gt $_.Length ? ('{0,7:n1}K' -f ($_.Length/1kb)) :
                        2gb -gt $_.Length ? ('{0,7:n1}M' -f ($_.Length/1mb)) :
                            ('{0,7:n1}G' -f ($_.Length/1gb))
                    )}
                }
    $Fields += $Expand ?
            @(
                @{l='Name';e={"`e[32m{0}$RC" -f $_.BaseName}},
                @{l='Ext';e={($_.Extension.Length)?$_.Extension.Substring(1):''}},
                'FullName'
            ) :
            @('Name');

    Get-ChildItem -Path $Path -Force:$Force -Hidden:$Hidden -Recurse:$Recurse -Directory:$Directory -File:$File | `
        Sort-Object `
            @{Expression='Mode';Descending=$true},`
            @{Expression='Extension';Descending=$false},`
            @{Expression='Name'} |`
        Format-Table $Fields -AutoSize
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
    param (
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            position=0
        )] [String[]] $Path='.\*'
    )
    if (1 -eq $Path.Count -and (Test-Path $Path)) {
        $Path = (join-path $Path '*' -Resolve) + (resolve-path $Path).Path
    }
    Resolve-Path -Path $Path -ErrorVariable rmrErr -ErrorAction 'SilentlyContinue' |
        ForEach-Object{
            print 'Remove ';
            print "`e[33m", $_ , "`t`e[6;32m→`e[0m"
            if (Test-Path $_){
                Remove-Item $_ -Force -Recurse -ErrorVariable rmrErr -ErrorAction 'SilentlyContinue'
                if ($rmrErr.Count) {
                    $rmrErr | Foreach-Object { println "`b`e[31m",$_.Exception.Message,$RC }
                } else {println "`b… done"}
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

# Analogue of GNU tail command – write last lines of file to stdout
filter tail {
    param (
        [Parameter(Mandatory,ValueFromPipeline)] $Name,
        [int] $Last=5
    )
    Get-Content $Name -Last $Last
}

# Make symlink
function Mount-Symlink ($Target, $Link) {
    New-Item -Path $Link -Value $Target -ItemType SymbolicLink
}

# Convert size to human friendly look
function ShortSize {
    param  (
        [Parameter(Position=0)] [UInt64] $Length = 0
    )

    switch ($Length) {
        {$Length -gt 1Tb} {return "{0:n1}`e[95mT`e[m" -f ($Length / 1Tb)}
        {$Length -gt 1Gb} {return "{0:n1}`e[91mG`e[m" -f ($Length / 1Gb)}
        {$Length -gt 1Mb} {return "{0:n1}`e[93mM`e[m" -f ($Length / 1Mb)}
        {$Length -gt 1Kb} {return "{0:n1}`e[96mK`e[m" -f ($Length / 1Kb)}
        default {return "{0:n0}`e[32mb`e[m" -f $Length}
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
        )] $Drives
    )

    process {
        [System.IO.DriveInfo]::GetDrives() |
            Where-Object {$_.IsReady -and $Drives -contains $_.Name.Chars(0)} |
                ForEach-Object {
                    if (!$_.TotalFreeSpace) {
                        $FreePct = 0
                        $Free = 0
                    } else {
                        $FreePct = [System.Math]::Round(100 * $_.TotalFreeSpace / $_.TotalSize, 2)
                        $Free = ShortSize $_.TotalFreeSpace
                    }

                    New-Object -TypeName PSObject -Property @{
                        Drive     = $_.Name
                        DriveType = $_.DriveType
                        '%' = $FreePct
                        'Space' = $Free
                    }
                }
    }
}

function urlget($Url, $Out) {
    (New-Object System.Net.WebClient).DownloadFile($Url, $Out)
}

filter Get-FolderSize {
    [CmdletBinding()]
    param (
        [Parameter(position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string] $Path = $PWD,

        [Switch] $Force = $False
    )

   Write-Verbose "Path: $Path"
   Write-Verbose "Force: $Force"
   (Get-ChildItem $Path -Recurse -Force:$Force | Measure-Object Length -Sum).sum
}

filter Get-SubfolderSizesHT {
    [CmdletBinding()]
    param (
        [Parameter(position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string] $Path = $PWD,

        [Switch] $Force = $False
    )

    Get-ChildItem $Path -Directory -Force:$Force | ForEach-Object{ @{ $_.Name = (Get-FolderSize $_) } }
}

# Calculate sizes of ol subfolders
filter Get-SubfolderSizes {
    [CmdletBinding()]
    param (
        # Target path of parent folder in wich the immediate descendants sizes are calculated
        [Parameter(position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string] $Path = $PWD,

        # Include Hidden and System folders
        [Switch] $Force = $False,
        # ExtraFields – FullName of dirs and calculated human readable lingth as Size field
        [Switch] $ExtraFields,
        # Directories only
        [Switch] $DirsOnly,
        # Width of Size field to align with table view
        [UInt] $szWidth = 16 # to get proper length use doubled length because of color data
    )

    # function hlm ($s) {return $s.Insert($s.Length - 1, "`e[96m") + "`e[0m"}

    Get-ChildItem $Path -Directory:$DirsOnly -Force:$Force |
        ForEach-Object {
            $len = (Get-FolderSize $_ -Force:$Force)
            $rec = New-Object PSObject

            Add-Member -InputObject $rec -MemberType NoteProperty -Name "Name" -Value $_.Name
            if ($ExtraFields) {
                # Add-Member -InputObject $rec -MemberType NoteProperty -Name "FullName" -Value $_.FullName
                Add-Member -InputObject $rec -MemberType NoteProperty -Name "Date" -Value $_.LastWriteTime.ToShortDateString()
                Add-Member -InputObject $rec -MemberType NoteProperty -Name "Time" -Value ('{0,8}' -f ($_.LastWriteTime.ToLongTimeString()))
                Add-Member -InputObject $rec -MemberType NoteProperty -Name "Size" -Value ("{0,$szWidth}" -f (ShortSize $len))
            }
            Add-Member -InputObject $rec -MemberType NoteProperty -Name "Length" -Value $len

            $rec
        }
}

function Show-FolderSizes {
    [CmdletBinding()]
    param (
        [Parameter(position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string] $Path = $PWD,

        [Switch] $DirsOnly,
        [Switch] $Force = $False,
        [Switch] $AscendingSort = $False,
        [Switch] $SortBySize = $False -or $AscendingSort
    )

    process {
        hr;
        println "`e[33m",(Resolve-Path $Path),"`e[0m"
        if ($SortBySize) {
            Get-SubfolderSizes $Path -ExtraFields -DirsOnly:$DirsOnly -Force:$Force | Sort-Object Length -Descending:(!$AscendingSort) | Select-Object Name,Date,Time,Size
        } else {
            Get-SubfolderSizes $Path -ExtraFields -DirsOnly:$DirsOnly -Force:$Force | Select-Object Name,Date,Time,Size
        }
        hr;
        "Total size: `e[33m{0}`e[0m" -f (ShortSize (Get-FolderSize $Path -Force:$Force))
    }
}
