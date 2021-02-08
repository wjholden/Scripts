function Measure-Jitter {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]$ComputerName,
        [ValidateRange(1,[int]::MaxValue)][int]$Count = 10
    )

    # collect a sample of round-trip times (RTT) using ping
    $rtt = (Test-Connection -ComputerName $ComputerName -Count $Count).Latency

    # return nothing if the host does not respond
    if ($rtt.Count -eq 0) {
        Write-Warning "No response from $ComputerName";
        return;
    }

    # compute the mean ping time
    $avg = ($rtt | Measure-Object -Average).Average

    # compute variance and standard deviation from sample
    $var = 0.0;
    $rtt | % { $var = $var + [math]::Pow($_ - $avg, 2) };
    $var = $var / ($rtt.Count - 1);
    $sd = [math]::Sqrt($var);

    $diff = ($rtt | % { $_ - $avg });
    $diff3 = ($diff | % { [math]::Pow($_, 3) } | Measure-Object -Sum).Sum;
    $diff4 = ($diff | % { [math]::Pow($_, 4) } | Measure-Object -Sum).Sum;
    $ns = $rtt.Length;
    $skewness = $ns * $diff3 / ($ns-1) / ($ns-2) / [math]::Pow($sd, 3);
    $kurtosis = $ns * ($ns+1) * $diff4 / ($ns-1) / ($ns-2) / ($ns-3) / [math]::Pow($sd, 4) - 3 * ($ns-1) * ($ns-1) / ($ns-2) / ($ns-3);

    # return the test result
    [pscustomobject]@{
        ComputerName=$ComputerName;
        Responses=$rtt.Count;
        Pings = $Count;
        "Loss (%)" = [math]::Round(100 * (1 - ($rtt.Count / $Count)));
        Mean = $avg;
        SD = $sd;
        Sample = $rtt;
        Skewness = $skewness;
        Kurtosis = $kurtosis
    }

<#
.SYNOPSIS

Computes statistics on network latency ("jitter") to a remote host using the built-in ping command.

.DESCRIPTION

Measure-Jitter computes the mean, standard deviation, skewness, and kurtosis (the four "moments) in round-trip ping times (latency) to network devices. Lower is better in all four. Low standard deviation tells you that jitter (variation in latency) is very low). Negative skewness would be very strange. Large kurtosis may indicate outliers.

William John Holden (https://wjholden.com)

.EXAMPLE

Get-ADComputer -Filter * | Get-Random -Count 10 | ForEach-Object { Measure-Jitter -ComputerName $_.Name -Count 10 }

Measure jitter to 10 hosts randomly selected from Active Directory. These measurements occur in series, so this is slow.

.EXAMPLE

Resolve-DnsName $env:USERDNSDOMAIN | % { Measure-Jitter $_.IPAddress } | ft ComputerName, Mean, SD

Measure jitter to all domain controllers in series.

.EXAMPLE

$jobs = Get-ADComputer -Filter * | ForEach-Object {
    Start-Job -ArgumentList $_.Name -ScriptBlock {
        param($ComputerName)
        Import-Module .\Measure-Jitter.psd1;
        Measure-Jitter -ComputerName $ComputerName -Count 100
    }
}
Receive-Job -Job $jobs -Keep | Sort-Object Mean -Descending | Select-Object * -ExcludeProperty RunspaceId | Format-Table

Measure jitter, in parallel, to all hosts in Active Directory. Creating jobs is not fast. See the next example if you are using PowerShell 7.

You can paste the Measure-Jitter function definition into the -InitializationScript block if loading modules is problematic.

.EXAMPLE

@("wjholden.com", "google.com", "facebook.com", "cisco.com", "amazon.com") | foreach -Parallel { Import-Module .\Measure-Jitter.psd1; Measure-Jitter $_ } | ft

Measure jitter using PowerShell 7 parallel execution.

#>
}
