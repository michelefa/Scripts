param(
    #AppPool Name
    [Parameter(Mandatory=$True)][string]$appPoolName
)


# Load IIS module:
Import-Module WebAdministration


# Get the number of retries
$retries = "20"
# Get the number of attempts
$delay = "500"

# Check if exists
if(Test-Path IIS:\\AppPools\$appPoolName) {

    # Stop App Pool if not already stopped
    if ((Get-WebAppPoolState $appPoolName).Value -ne "Stopped") {
        echo "Stopping IIS app pool $appPoolName"
        Stop-WebAppPool $appPoolName

        $state = (Get-WebAppPoolState $appPoolName).Value
        $counter = 1

        # Wait for the app pool to the "Stopped" before proceeding
        do{
            $state = (Get-WebAppPoolState $appPoolName).Value
            echo "$counter/$retries Waiting for IIS app pool $appPoolName to shut down completely. Current status: $state"
            $counter++
            Start-Sleep -Milliseconds $delay
        }
        while($state -ne "Stopped" -and $counter -le $retries)

        # Throw an error if the app pool is not stopped
        if($counter -gt $retries) {
            throw "Could not shut down IIS app pool $appPoolName. `nTry to increase the number of retries ($retries) or delay between attempts ($delay milliseconds)." }
    }
    else {
        echo "$appPoolName already Stopped"
    }
}
else {
    echo "IIS app pool $appPoolName doesn't exist"
}
