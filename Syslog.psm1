function Send-Syslog {
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="IP Address", Position=0)]
        [string]$IPAddress,

        [Parameter(Mandatory=$true, ParameterSetName="IPv6 Address", Position=0)]
        [string]$IPv6Address,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Message,

        [Parameter(Mandatory=$false, Position=2)]
        [int]$Port = 514
    )

    $af = -1;
    if ($IPAddress) {
        $af = [System.Net.Sockets.AddressFamily]::InterNetwork;
        $addr = $IPAddress;
    } else {
        $af = [System.Net.Sockets.AddressFamily]::InterNetworkV6;
        $addr = $IPv6Address;
    }

    $ep = New-Object IPEndPoint ([IPAddress]::Parse($addr), $Port);

    try
    {
        $socket = [System.Net.Sockets.UdpClient]::new($af);
        $socket.Connect($ep);
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($message);
        $i = $socket.Send($bytes, $bytes.length);
    }
    catch [System.Net.Sockets.SocketException]
    {
        Write-Error "Unable to send Syslog message to $addr";
    }
    finally
    {
        $socket.Close();
    }
}

function Receive-Syslog {
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="IP Address", Position=0)]
        [string]$IPAddress,

        [Parameter(Mandatory=$true, ParameterSetName="IPv6 Address", Position=0)]
        [string]$IPv6Address,

        [Parameter(Mandatory=$false, Position=1)]
        [int]$Port = 514,

        [Parameter(Mandatory=$false)]
        [switch]$Listen = $false,

        [Parameter(Mandatory=$false)]
        [int]$Timeout = 0
    )

    if ($IPAddress) {
        $addr = [IPAddress]::Parse($IPAddress);
        $af = [System.Net.Sockets.AddressFamily]::InterNetwork;
    } else {
        $addr = [IPAddress]::Parse($IPv6Address);
        $af = [System.Net.Sockets.AddressFamily]::InterNetworkV6;
    }

    if ($Listen -and $Timeout -eq 0) {
        # CTRL+C does not work when listening for input.
        # If the user specified to listen but did not give a timeout then
        # we set it to 100 milliseconds.
        # Exceptions from the timeout will be ignored in the inner catch statement below.
        $Timeout = 100;
    }

    $ep = New-Object IPEndPoint ([IPAddress]::Any, 0);

    try
    {
        $socket = New-Object System.Net.Sockets.UdpClient @($Port, $af);
        $socket.JoinMulticastGroup($addr);
        $socket.Client.ReceiveTimeout = $Timeout;

        do
        {
            try
            {
                $bytes = $socket.Receive([ref] $ep);
                [System.Text.Encoding]::ASCII.GetString($bytes);
            }
            catch [System.Net.Sockets.SocketException]
            {
                # suppress timeout errors
                if ($Listen -eq $false)
                {
                    Write-Error "Unable to receive Syslog messages on $addr";
                }
            }
        }
        while ($Listen);
    }
    catch [System.Net.Sockets.SocketException]
    {
        # this is an error we care about
        Write-Error "Unable to receive Syslog messages on $addr";
    }
    finally
    {
        $socket.Close();
    }
}

Set-Alias -Name txs -Value Send-Syslog
Set-Alias -Name rxs -Value Receive-Syslog