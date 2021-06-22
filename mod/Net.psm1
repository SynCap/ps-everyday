function dlst {
	param(
		[parameter(mandatory,position=0)] [String[]] $urlList,
		[parameter(position=1)] [String] $Dest = '.'
	)
	$Cnt = 1
	foreach ($Url in $urlList) {
		$r = Invoke-WebRequest $Url
		$m = (ParseUrl $Url)
		if ($m) {
			$FName = Join-Path -Path $Dest -ChildPath ('{0:d3}.{1}' -f $Cnt, ($m.Ext ?? (($r.Headers['Content-Type'] -split '/')[1] ?? '')) -join '')
			Set-Content -AsByteStream -Value $r.Content -Path $FName
		} else {
			Write-Error 'Bad URL'
			$False
		}
		$Cnt++
	}
	explorer.exe $Dest
}

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
		$False
	}
}

function ParseUrl([String]$Url) {
	$re = '^((?<Scheme>\w+)://)?(?<Site>[^/]+)(?<Path>[^#?]*?(?<FileName>[^/#?>]*?)?)(\?(?<Query>[^#]*))?(#(?<Hash>.*))?$';

	$res = $Url -match $re ? $Matches : $False

	if ($res.FileName -match '\.([^.]+)$') {
		$res.Ext = $Matches[1]
	}

	$res
}