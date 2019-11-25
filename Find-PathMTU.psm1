function Find-PathMTU {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)][string]$TargetName,
        [int]$Timeout = 500,
        [int]$Repeat = 1,
        [ValidateRange(1,[int]::MaxValue)][int]$Minimum = 68,
        [ValidateRange(1,[int]::MaxValue)][int]$Maximum = 1500
    )

    function pingtest {
        param([int]$size)

        $testResult = "$(ping -n $Repeat -w $Timeout -f -l $size $TargetName)";
        if ($testResult.Contains("Packet needs to be fragmented but DF set.")) {
            return $false;
        } else {
            $testResult -match "(\d)+% loss";
            $loss = [int]$Matches.1; # probably not thread safe
            return ($loss -lt 100);
        }
    }

    function divide {
        param([int]$lo,[int]$hi)

        Write-Verbose "Divide and conquer path MTU discovery to $TargetName between [$lo,$hi]";

        $mid = [math]::Round(($hi+$lo)/2);

        if ($hi -lt $lo) {
            throw "The upper bound is less than the lower bound.";
        }

        if ($lo -eq $hi) {
            # Base case. We must only get here from a successful ping of size $lo.
            return $lo;
        } elseif (pingtest $hi) {
            # The upper bound works. We're done!
            return $hi;
        } elseif (pingtest $mid) {
            # Recursive case: the midpoint works, so look in the upper half of the current domain.
            # It is safe to reduce the upper bound by 1 since it did not work.
            return divide $mid ($hi - 1);
        } else {
            # Recursive case: the midpoint did not work, so look in the lower half.
            # It is not safe to increase the lower bound (example: lo=1416 and mid=1417).
            return divide $lo $mid;
        }
    }

    if (-not (pingtest $Minimum)) {
        throw "MTU to $TargetName cannot be determined from $Minimum";
    }
    return divide $Minimum $Maximum;
<#
.SYNOPSIS

Discovers path MTU using ping tests.

.DESCRIPTION

Find-PathMTU (or its alias "mtu") performs a binary search to discover the Internet Protocol (IP) maximum transmission unit (MTU) along the path of routers to the destination by calling the ping command. The Windows ping program pauses between messages, which makes this O(log n) program slow when -Repeat is greater than 1.

Users of PowerShell 6 and 7 should instead use the Test-Connection cmdlet with the -MTUSizeDetect parameter.

This program searches the textual output of the classic ping command. This "screen scraping" technique is delicate and has not been designed for robustness. For example, this program does not and will not handle exceptional cases, such as name resolution failures.

This program may *not* be safe for parallel programming due to the use of the $Matches global for regular expressions.

Users of this program can reduce the number of ping attempts and their timeout (in milliseconds). Tuning these options may speed up path MTU discovery execution, however overly-aggressive values may reduce reliability.

William John Holden (https://wjholden.com)

This code is licensed under the MIT license.

.LINK

https://github.com/wjholden/Scripts/

.EXAMPLE

PS> Find-PathMTU -TargetName localhost -Timeout 10 -Repeat 1 -Minimum 20 -Maximum 0x7fffffff

.EXAMPLE

PS> mtu wjholden.com -Verbose

#>
}

Set-Alias -Name mtu -Value Find-PathMTU