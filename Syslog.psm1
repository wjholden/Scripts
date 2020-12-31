function Send-Syslog {
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="IP Address", Position=0)]
        [string]$IPAddress,

        [Parameter(Mandatory=$true, ParameterSetName="IPv6 Address", Position=0)]
        [string]$IPv6Address,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Message
    )

    $af = -1;
    if ($IPAddress) {
        $af = [System.Net.Sockets.AddressFamily]::InterNetwork;
        $ep = New-Object IPEndPoint ([IPAddress]::Parse($IPAddress), 514);
    } else {
        $af = [System.Net.Sockets.AddressFamily]::InterNetworkV6;
        $ep = New-Object IPEndPoint ([IPAddress]::Parse($IPv6Address), 514);
    }

    try
    {
        $socket = [System.Net.Sockets.UdpClient]::new($af);
        $socket.Connect($ep);
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($message);
        $i = $socket.Send($bytes, $bytes.length);
    }
    catch [System.Net.Sockets.SocketException]
    {
        Write-Error "Unable to send Syslog message to $IPAddress";
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
        [string]$IPv6Address
    )

    if ($IPAddress) {
        $addr = [IPAddress]::Parse($IPAddress);
        $af = [System.Net.Sockets.AddressFamily]::InterNetwork;
    } else {
        $addr = [IPAddress]::Parse($IPv6Address);
        $af = [System.Net.Sockets.AddressFamily]::InterNetworkV6;
    }

    $ep = New-Object IPEndPoint ([IPAddress]::Any, 0);

    try
    {
        $socket = New-Object System.Net.Sockets.UdpClient @(514, $af);
        $socket.JoinMulticastGroup($addr);
        $bytes = $socket.Receive([ref] $ep);
        [System.Text.Encoding]::ASCII.GetString($bytes);
    }
    catch [System.Net.Sockets.SocketException]
    {
        Write-Error "Unable to receive Syslog messages on $addr";
    }
    finally
    {
        $socket.Close();
    }
}