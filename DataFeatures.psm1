# Import-Csv .\100.csv | Get-Random -Count 5 | Enter-DataFeature -Features @('Sex', 'Age', 'Bodyweight', 'Kettlebell', 'Repetitions') -Display @("text")
# Import-Csv .\100.csv | Get-Random -Count 5 | % { If ($_.video_thumbnail) { Show-WebImage $_.video_thumbnail }; Enter-DataFeature -Features @('Sex', 'Age', 'Bodyweight', 'Kettlebell', 'Repetitions') -Observations $_ -Display @('text') } | Export-Csv test2.csv
function Enter-DataFeature {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)][PSObject[]]$Observations,
        [String[]] $Display,
        [String[]] $Features
    )

    process {
        foreach ($observation in $Observations) {
            $o = $Observation.PsObject.Copy()
            $title = If ($Features.Length -gt 1) { "Add features?" } Else { "Add feature?" }
            $result = $Host.UI.PromptForChoice($title, (Select-Object -InputObject $o -Property $Display | Format-List | Out-String), @('&Discard', '&Enter'), 0)
            if ($result -eq 1) {
                foreach ($feature in $Features) {
                    $value = Read-Host -Prompt $feature
                    Add-Member -InputObject $o -NotePropertyName $feature -NotePropertyValue $value
                }
                $o
            }
        }
    }
}

# mostly stolen from https://gist.github.com/zippy1981/969855
function Show-WebImage ($url) {
    $t = New-TemporaryFile
    Invoke-WebRequest -Uri $url -OutFile $t
    Add-Type -AssemblyName 'System.Windows.Forms'
    $img = [System.Drawing.Image]::Fromfile($t)

    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form = new-object Windows.Forms.Form
    $form = new-object Windows.Forms.Form
    $form.Text = "Image Viewer"
    $form.Width = $img.Size.Width;
    $form.Height =  $img.Size.Height;
    $pictureBox = new-object Windows.Forms.PictureBox
    $pictureBox.Width =  $img.Size.Width;
    $pictureBox.Height =  $img.Size.Height;

    $pictureBox.Image = $img;
    $form.controls.add($pictureBox)
    $form.Add_Shown( { $form.Activate() } )
    $form.ShowDialog()
}