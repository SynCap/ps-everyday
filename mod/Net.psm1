function dlwp {
	param(
		[parameter(mandatory,position=0)] [String] $Url,
		[parameter(position=1)] [String] $Dest = 'Yandex',
		[Alias('b')][Switch] $Bing
	)
	if($Bing){
		$Dest = 'Bing'
	}
	$Dest = join-path 'D:\Graphics\WP\' $Dest
	$FName = (join-path $Dest (split-path $Url -leaf))
	wget -O $FName $Url
	explorer.exe /select,$FName
}