function Format-Config {
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)][String]$Template,
        [parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][PSObject[]]$Parameters        
    )

    process {
        $configuration_template = Get-Content -Path $Template -Encoding UTF8 -Raw
        foreach ($parameter_row in $Parameters) {
            [String] $cfg = $configuration_template.Clone()
            foreach ($parameter in $parameter_row.PsObject.Properties) {
                $cfg = $cfg.Replace("<$($parameter.Name)>", $parameter.Value)
            }
            [pscustomobject]@{Hostname = $parameter_row.HOSTNAME; Configuration = $cfg}
        }
    }

<#
.SYNOPSIS

Create router/switch configurations from a template.

.DESCRIPTION

Specify the location of the template file.
The template should have all parameters enclosed in angle brackets, such as <HOSTNAME>.
Pass the parameters to this function as an array of PSObjects.
The easiest way to do this is to use the Import-Csv function.
Each row in the parameters is one router.
Each column of the parameter object is a parameter that will be substituted into the template.

This program assumes that there is a HOSTNAME field in the parameter set.
In general, all HOSTNAME entries in the input should be distinct.

.EXAMPLE

(Format-Config -Template Template.txt -Parameters (Import-Csv Parameters.csv | Select-Object -First 1))[0].Configuration

Read the first row of the parameter file and show the configuration.

.EXAMPLE

Import-Csv Parameters.csv | Format-Config -Template Template.txt | ForEach-Object { Write-Output $_.Configuration | Out-File -Path "$($_.Hostname).txt" }

Import parameters and pipe to this function. For each output, write the configuration a file with a name like <Hostname>.txt.

#>
}