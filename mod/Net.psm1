function dlwp {
	param(
		[parameter(mandatory,position=0)] [String] $Url,
		[Switch] $Bing,
		[parameter(position=1)] [String] $Dest = $Bing ? 'Bing' : 'Yandex'
	)
	$Dest = join-path 'D:\Graphics\WP\' $Dest
	$FName = (join-path $Dest (split-path $Url -leaf))
	wget -O $FName $Url
	explorer.exe /select,$FName
}