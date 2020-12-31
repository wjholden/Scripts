function Backup-Borderlands3() {
    $d = Get-Date -Format "yyyy-MM-dd"
    Set-Location "C:\Users\wjhol\Google Drive\BL3"
    New-Item -ItemType Directory -Name $d -ErrorAction SilentlyContinue
    $dst = Get-Item $d
    Copy-Item -Path 'C:\Users\wjhol\Documents\My Games\Borderlands 3\Saved\SaveGames\*\*' -Destination $dst -Recurse
    return $dst
}

New-Alias -Name bb -Value Backup-Borderlands3