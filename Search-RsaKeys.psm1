function Search-RsaKeys {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)][string[]]$ComputerName,
        [parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)][string]$Username = $env:USERNAME
    )

    process {
        $ssh_executable = 'plink.exe';
        if (Get-Command $ssh_executable -ErrorAction SilentlyContinue) {
            foreach ($h in $ComputerName) {
                $ssh_pubkeys = (& $ssh_executable -l $Username -ssh -P 22 $h "show running-config | include key-hash")
                foreach ($line in $ssh_pubkeys) {
                    $g = [regex]::Match($line, 'key-hash (.+) (.+)').Groups;
                    [pscustomobject]@{
                        ComputerName = $h;
                        KeyType = $g[1].Value;
                        FingerPrint = $g[2].Value
                    }
                }
            }
        } else {
            Write-Error "$($ssh_executable) not found on path";
        }
    }
}