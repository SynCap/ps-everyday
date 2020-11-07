
Set-Alias _path -Value Resolve-Path

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
