function dlwp {
	param(
		[parameter(mandatory,position=0)] [String] $Url,
		[Switch] $Bing,
		[parameter(position=1)] [String] $Dest = ( Join-Path -Path 'D:\Graphics\WP\' -ChildPath ($Bing ? 'Bing' : 'Yandex') )
	)
	$r = Invoke-WebRequest $Url
	if ($Url -Match '(?<=/)[^/#?]+?(?<Ext>\.[^/.#?]*?)?(?=[#?]|$)') {
		$FName = Join-Path -Path $Dest -ChildPath ($Matches[0],($Matches.Ext ?? ('.' + ($r.Headers['Content-Type'] -split '/')[1] ?? '')) -join '')
		Set-Content -AsByteStream -Value $r.Content -Path $FName
		explorer.exe /select,$FName
	} else {
		Write-Error 'Bad URL'
	}
}