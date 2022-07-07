function Measure-Latency {
	Param(
		[parameter(mandatory=$true, Position=0)][string]$FilterString,
		[int]$ThrottleLimit = 100,
		[int]$Count = 10,
		[int]$TimeoutSeconds = 1
	)
	# Get a list of computers from active directory where the hostname matches the provided filter string,
	Get-ADComputer -Filter { Name -like $FilterString } |
	# iterate over all results concurrently,
	ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
		# ping the device to collect latency times in milliseconds,
		Test-Connection -TargetName $_.DNSHostName -Ping -TimeoutSeconds $TimeoutSeconds -Count $Count |
		# compute summary statistics from ping round-trip times,
		Measure-Object -Property Latency -Average -Maximum -Minimum -StandardDeviation |
		# add the hostname of the machine to the returned object,
		Add-Member -NotePropertyName Name -NotePropertyValue $_.DNSHostName -PassThru |
		# ...and select only the fields we care about.
		Select Name, Average, Maximum, Minimum, StandardDeviation
	}
<#
.SYNOPSIS

Ping devices from Active Directory and return basic summary statistics for latency and jitter.

.DESCRIPTION

Latency is the round-trip time for a computer to respond to input over a network. Jitter refers to the variability of latency.

William John Holden (https://wjholden.com)

.EXAMPLE

Measure-Latency "*" -ThrottleLimit 200

#>
}
