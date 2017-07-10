## --------------------------------------------------------------------------------------
## Starts a Website passed in the parameter
## --------------------------------------------------------------------------------------

param(
    [Parameter(Mandatory=$True)][string]$webSiteName
    )


# Load IIS module:
Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
Import-Module WebAdministration -ErrorAction SilentlyContinue

echo "Starting Website $webSiteName"


# Get web site object
$webSite = Get-Item "IIS:\\Sites\\$webSiteName"


Write-Output "Starting IIS web site $webSiteName"
$webSite.Start()
