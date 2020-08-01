function Measure-Jitter {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]$ComputerName,
        [ValidateRange(1,[int]::MaxValue)][int]$Count = 10
    )

    # collect a sample of ping times
    $latency = ping -n $Count $ComputerName | ForEach-Object {
        Select-String -InputObject $_ -Pattern "Reply from" -SimpleMatch
    } | ForEach-Object {
        if ("$_" -match "time[<=](\d+)ms") {
            [int]$Matches.1
        }
    }

    # return nothing if the host does not respond
    if ($latency.Count -eq 0) {
        Write-Warning "No response from $ComputerName";
        return;
    }

    # compute the mean ping time
    $avg = ($latency | Measure-Object -Average).Average

    # compute variance and standard deviation from sample
    $var = 0.0;
    $latency | % { $var = $var + [math]::Pow($_ - $avg, 2) };
    $var = $var / ($latency.Count - 1);
    $sd = [math]::Sqrt($var);

    # return the test result
    [pscustomobject]@{
        ComputerName=$ComputerName;
        Responses=$latency.Count;
        Pings = $Count;
        "Loss (%)" = [math]::Round(100 * (1 - ($latency.Count / $Count)));
        Mean = $avg;
        SD = $sd;
        CV = $sd / $avg;
        Sample = $latency;
    }

<#
.SYNOPSIS

Computes statistics on network latency ("jitter") to a remote host using the built-in ping command.

.DESCRIPTION

Measure-Jitter computes the mean, standard deviation, and coefficient of variation (CV) of jitter to among remote devices. A low CV indicates a "smooth" network with consistent latency. Lower CV is better.

William John Holden (https://wjholden.com)

.EXAMPLE

Get-ADComputer -Filter * | Get-Random -Count 10 | ForEach-Object { Measure-Jitter -ComputerName $_.Name -Count 10 }

Measure jitter to 10 hosts randomly selected from Active Directory. These measurements occur in series, so this is slow.

.EXAMPLE

Resolve-DnsName $env:USERDNSDOMAIN | % { Measure-Jitter $_.IPAddress } | ft ComputerName, Mean, CV

Measure jitter to all domain controllers in series.

.EXAMPLE

$jobs = Get-ADComputer -Filter * | ForEach-Object {
    Start-Job -ArgumentList $_.Name -ScriptBlock {
        param($ComputerName)
        Import-Module .\Measure-Jitter.psd1;
        Measure-Jitter -ComputerName $ComputerName -Count 100
    }
}
Receive-Job -Job $jobs -Keep | Sort-Object CV -Descending | Select-Object * -ExcludeProperty RunspaceId | Format-Table

Measure jitter, in parallel, to all hosts in Active Directory. Creating jobs is not fast. See the next example if you are using PowerShell 7.

I have tried and failed to pass the Measure-Jitter function lambda as a parameter to Start-Job. You can paste the Measure-Jitter function definition into the -InitializationScript block if loading modules is problematic.

.EXAMPLE

@("wjholden.com", "google.com", "facebook.com", "cisco.com", "amazon.com") | foreach -Parallel { Import-Module .\Measure-Jitter.psd1; Measure-Jitter $_ } | ft

Measure jitter using PowerShell 7 parallel execution.

#>
}
