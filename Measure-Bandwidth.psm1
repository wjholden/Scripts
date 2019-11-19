function Measure-Bandwidth {
    param(
        [parameter(ParameterSetName="t",Position=0)][switch]$Transmit = $false,
        [parameter(ParameterSetName="t",Position=1,Mandatory=$true)][string]$Destination,
        [parameter(ParameterSetName="r",Position=0)][switch]$Receive = -Not $Transmit,
        [int]$BufferSize = 8192, # For compatibility. This is much smaller than 1903's default setting of 65536.
        [int]$BufferCount = 1024,
        [int]$Port = 5001
    )

    if ($Transmit -and $Receive) {
        throw "Transmit and Receive cannot both be selected";
    }

    $startTime = $null;
    $endTime = $null;
    $ip = $null;
    $totalBytes = 0;

    # https://docs.microsoft.com/en-us/dotnet/api/system.net.sockets.tcplistener?view=netframework-4.8
    if ($Receive) {
        $server = New-Object System.Net.Sockets.TcpListener($Port);
        $server.Start();
        $buffer = New-Object System.Byte[] $BufferSize;
        $client = $server.AcceptTcpClient();

        # https://docs.microsoft.com/en-us/dotnet/api/system.net.sockets.tcpclient.client?view=netframework-4.8
        $client.Client.SetSocketOption(
            [System.Net.Sockets.SocketOptionLevel]::Socket,
            [System.Net.Sockets.SocketOptionName]::ReceiveBuffer,
            $BufferSize);

        while ($client.Connected) {
            $ip = $client.Client.RemoteEndPoint;
            $stream = $client.GetStream();
            $startTime = Get-Date;
            do {
                $bytesRead = $stream.Read($buffer, 0, $BufferSize);
                $totalBytes += $bytesRead;
            } while ($bytesRead -gt 0);
            $endTime = Get-Date;
            $stream.Close();
        }
        $client.Close();
        $server.Stop();
    } else {
        $client = New-Object System.Net.Sockets.TcpClient($Destination, $Port);

        if ($client.Connected) {
            $stream = $client.GetStream();
            $ip = $client.Client.RemoteEndPoint;

            # Filling the buffer with sequential integers [0,255] is for compatibility
            # with other TTCP programs. This program ignores the values in the buffer
            # and trusts the operating system TCP driver to guarantee data integrity.
            $buffer = New-Object System.Byte[] $BufferSize;
            (0..($BufferSize - 1)) | % { $buffer[$_] = [byte] ($_ % 256) };

            $startTime = Get-Date;
            (0..($BufferCount - 1)) | % { $stream.Write($buffer, 0, $BufferSize) };
            $endTime = Get-Date;
            $totalBytes = $BufferSize * $BufferCount;
            $stream.Close();
            $client.Close();
        }
    }

    # 10 million ticks per second, 1000 milliseconds per second
    # ticks * (1 s / 10000000 ticks) * (1000 ms / 1 s)
    $seconds = ($endTime.Ticks - $startTime.Ticks) / 10000000;

    # https://mcpmag.com/articles/2012/12/11/pshell-order.aspx
    # RFC 1177: 1 KB = 2^10 bytes, 1 MB = 2^20 bytes.
    [pscustomobject][ordered]@{Endpoint=$ip; Milliseconds=[math]::Round($seconds * 1000); Bytes=$totalBytes; KBps=[math]::Round($totalBytes / $seconds / 1024); Mbps=[math]::Round($totalBytes / $seconds * 8 / 1024 / 1024)};
}

Set-Alias -Name ttcp -Value Measure-Bandwidth
