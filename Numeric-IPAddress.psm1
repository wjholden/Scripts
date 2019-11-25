# Functions to convert dotted-decimal IPv4 address strings to integers and back.
# In integer format you can do sorting and bitwise operations.
# ("192.168.0.1", "224.0.0.1", "0.0.0.0", "255.255.255.255") | Convert-IPtoInteger | Convert-IntegerToIP

function Convert-IPtoInteger() {

    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="IP Address", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $addresses
    )

    process {
        foreach ($ip in $addresses) {
            if ($ip -match '(\d\d?\d?\.){3}\d\d?\d?') { # approximate regex, matches some impossible addresses like 999.0.0.0
                $s = "$ip".Split(".");
                [uint32] $x = 0;
                (0..3) | ForEach-Object { # positions 0, 1, 2, 3 in previous string
                    $x = $x -shl 8; # bit shift previous value to the left by 8 bits
                    $x += $s[$_];
                }
                Write-Output $x;
            }
        }
    }
}

function Convert-IntegerToIP() {

    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="IP Address", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [long] $addresses
    )

    process {
        foreach ($ip in $addresses) {
            $o1 = ($ip -shr 24) -band 0xff;
            $o2 = ($ip -shr 16) -band 0xff;
            $o3 = ($ip -shr 8) -band 0xff;
            $o4 = ($ip) -band 0xff;
            Write-Output "$o1.$o2.$o3.$o4";
        }
    }
}

