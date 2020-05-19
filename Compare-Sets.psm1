function Compare-Sets($a, $b) {
	$c = ($a + $b | Sort-Object | Select-Object -Unique);
	$c | ForEach-Object {
		[PSCustomObject]@{
			'Element' = $_;
			'In Set 1' = ($_ -in $a);
			'In Set 2' = ($_ -in $b);
		}
	}
}
