
# demo для PSReadLine
# куча всяких фишек а-ля редактор
function Import-KbExtra {
    $fName = Join-Path (stat $PROFILE).DirectoryName kb.ps1 -Resolve
    . $fName
}

Set-PSReadLineOption -EditMode Vi

Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+a -Function GotoFirstNonBlankOfLine

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
