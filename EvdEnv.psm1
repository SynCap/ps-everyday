
# Управление сессионной переменной окружения PATH
function .pc {$env:Path.Split(';')[-3..-1]}
function .pp {if($env:Path -NotLike "*;$(pwd)"){$env:Path+=";$(pwd)"};.pc}
function .pd {$env:Path=$env:Path.Split(';')[0..-2].Join(';');.pc}

$Global:EvdSPF = @{}
function .spf ($SpecialFolderAlias) {
    # $keys = [Enum]::GetNames([System.Environment+SpecialFolder])
    if ($SpecialFolderAlias) {
        [Environment]::GetFolderPath($SpecialFolderAlias)
    } else {
        # [Enum]::GetNames([System.Environment+SpecialFolder]).GetEnumerator()
        if (1 -gt $Global:EvdSPF.Count) {
            [Enum]::GetNames([System.Environment+SpecialFolder]).GetEnumerator().forEach({
                $Global:EvdSPF.Add($_, [Environment]::GetFolderPath($_))
            })
        }
        $Global:EvdSPF.GetEnumerator() | select Name,Value | Sort Name
    }
}

# разворачивает %$<строки>%
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

filter TotalCmd {
    param([Parameter(ValueFromPipeline)] $Path)
    $Cmd = "{0}\totalcmd\TOTALCMD64.EXE" -f $env:ProgramFiles
    $Params =  @('/O','/T','/A',$Path)
    & $Cmd $Params
}

# Set-Alias subl -Value "C:\Program Files\Sublime Text 3\subl.exe"

$subl = Join-Path $env:ProgramFiles "Sublime Text 3" "subl.exe"
function subl {
    param (
        [Parameter(Mandatory,ValueFromPipeline)] [String[]] $Path = '.'
    )
    echo $args
    & $subl ($Path, $args)
}
