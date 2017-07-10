## --------------------------------------------------------------------------------------
## Stops a Website passed
## --------------------------------------------------------------------------------------

param(
    # Get WebSite Name
    [Parameter(Mandatory=$True)][string]$webSiteName
    )

# Load IIS module:
Import-Module WebAdministration

# Get the number of retries
$retries = 5
# Get the number of attempts
$delay = 5

# Check if exists
if(Test-Path IIS:\\Sites\\$webSiteName) {

    # Stop Website if not already stopped
    if ((Get-WebSiteState $webSiteName).Value -ne "Stopped") {
        echo "Stopping IIS Website $webSiteName"
        Stop-WebSite $webSiteName

        $state = (Get-WebSiteState $webSiteName).Value
        $counter = 1

        # Wait for the Website to the "Stopped" before proceeding
        do{
            $state = (Get-WebSiteState $webSiteName).Value
            echo "$counter/$retries Waiting for IIS Website $webSiteName to shut down completely. Current status: $state"
            $counter++
            Start-Sleep -Milliseconds $delay
        }
        while($state -ne "Stopped" -and $counter -le $retries)

        # Throw an error if the Website is not stopped
        if($counter -gt $retries) {
            throw "Could not shut down IIS Website $webSiteName. `nTry to increase the number of retries ($retries) or delay between attempts ($delay milliseconds)." }
    }
}
else {
    echo "IIS Website $webSiteName doesn't exist"
}
