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

function downloadFiles {
	param(
		[parameter(mandatory)]
		[String[]] $List,
		[String] $Dest = '.',
		[String] $BaseUrl = ''
	)
	$Cnt = 0
	foreach ($File in $List) {
		println ("{0,2}/{1} Download file: `e[33m{2}`e[0m" -f ++$Cnt,$List.Count,$File)
		$Url = "$BaseUrl$File"
		$r = Invoke-WebRequest $Url
		if ($r -and $r.StatusDescription -eq 'OK') {
			$FName = Join-Path -Path $Dest -ChildPath $File
			Write-Debug $FName
			Set-Content -Path $FName -Value $r.Content -Encoding utf8
		} else {
			throw 'Bad URL'
			$False
		}
	}
	explorer.exe $Dest
}

function ParseUrl([String]$Url) {
	$re = '^((?<Scheme>\w+)://)?(?<Site>[^/]+)(?<Path>[^#?]*?(?<FileName>[^/#?>]*?)?)(\?(?<Query>[^#]*))?(#(?<Hash>.*))?$';
	$matched = $Url -match $re ? $Matches : $False
	if ($matched.FileName -match '\.([^.]+)$') {
		$matched.Ext = $Matches[1]
	}
	$matched
}

function LocalIP {
	(
		Get-NetIPAddress `
			-AddressFamily IPv4 `
			-InterfaceIndex $(
				Get-NetConnectionProfile
			).InterfaceIndex
	).IPAddress
}

<#
	.Synopsis
		Returns EXTERNAL IP data
#>
function Get-IpInfo {
	param (
		# IP address or Domain to obtain detailed data.
		# If omitted return descriptions for external IP
		# of local system
		[parameter(position=0)][string] $TargetHost
	)
	$Response = Invoke-WebRequest http://ip-api.com/json/$TargetHost
	if ($Response.StatusDescription -eq 'OK') {
		$Result = ConvertFrom-Json $Response.Content
		$date = [DateTime]($Response.Headers.Date.Trim('{}'))
		Add-Member -MemberType NoteProperty -Name 'date' -Value $date -InputObject $Result
		$Result
	}
}
