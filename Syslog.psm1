function Send-Syslog {
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="IP Address")]
        [string]$IPAddress,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    $ep = New-Object IPEndPoint (
        [IPAddress]::Parse($IPAddress), 514);
    try
    {
        $socket = New-Object System.Net.Sockets.UdpClient;
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
        [Parameter(Mandatory=$true, ParameterSetName="IP Address")]
        [string]$IPAddress
    )

    $ep = New-Object IPEndPoint ([IPAddress]::Any, 0);

    try
    {
        $socket = New-Object System.Net.Sockets.UdpClient 514;
        $socket.JoinMulticastGroup(([IPAddress]::Parse($IPAddress)));
        $bytes = $socket.Receive([ref] $ep);
        [System.Text.Encoding]::ASCII.GetString($bytes);
    }
    catch [System.Net.Sockets.SocketException]
    {
        Write-Error "Unable to receive Syslog messages on $IPAddress";
    }
    finally
    {
        $socket.Close();
    }
}