
# Управление сессионной переменной окружения PATH
function .pc {$env:Path.Split(';')[-3..-1]}
function .pp {if($env:Path -NotLike "*;$pwd"){$env:Path+=";$pwd"};.pc}
function .pd {$env:Path=$env:Path.Split(';')[0..-2].Join(';');.pc}

# PowerShell:PSAvoidGlobalVars=$False
$Script:EvdSPF = @{}
function .spf ($SpecialFolderAlias) {
    # $keys = [Enum]::GetNames([System.Environment+SpecialFolder])
    if ($SpecialFolderAlias) {
        [Environment]::GetFolderPath($SpecialFolderAlias)
    } else {
        # [Enum]::GetNames([System.Environment+SpecialFolder]).GetEnumerator()
        if (1 -gt $Script:EvdSPF.Count) {
            [Enum]::GetNames([System.Environment+SpecialFolder]).GetEnumerator().forEach({
                $Script:EvdSPF.Add($_, [Environment]::GetFolderPath($_))
            })
        }
        $Script:EvdSPF.GetEnumerator() | Select-Object Name,Value | Sort-Object Name
    }
}

# разворачивает %$<строки>%
function .exp ($s) {[System.Environment]::ExpandEnvironmentVariables($s)}

function .exps ([parameter(ValueFromPipeline)][string]$s) {
    $re = '#\(\s*(\w+?)\s*\)'
    $s -replace $re, {
        try{
            [Environment]::GetFolderPath($_.Groups[1].Value)
        } catch {
            ''
        }
    }
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

$sublPath = Join-Path -Path $env:ProgramFiles -ChildPath "Sublime Text 3" "subl.exe"
function subl {
    param (
        [Parameter(ValueFromPipeline)] [String[]] $Path = '.'
    )
    Process {
        Write-Debug "`$args: $args"
        & $sublPath ($Path, $args)
    }
}
