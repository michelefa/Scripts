# --------------------------------------------------------------------------------------
## Input
## --------------------------------------------------------------------------------------
param(
    [Parameter(Mandatory=$True)][string]$WebSiteName, 
    [Parameter(Mandatory=$True)][string]$IPAddress,
    [Parameter(Mandatory=$True)][string]$port,
    [Parameter(Mandatory=$True)][string]$HostName
)

# Installation
#---------------
Import-Module WebAdministration


$Name = $WebSiteName
$Protocol = "http"
$SSL_Certificae  = ""

## --------------------------------------------------------------------------------------
## Helpers
## --------------------------------------------------------------------------------------
# Helper for validating input parameters
function Validate-Parameter([string]$foo, [string[]]$validInput, $parameterName) {
    echo "${parameterName}: $foo"
    if (! $foo) {
        throw "No value was set for $parameterName, and it cannot be empty"
    }
    
    if ($validInput) {
        if (! $validInput -contains $foo) {
            throw "'$input' is not a valid input for '$parameterName'"
        }
    }
    
}


## --------------------------------------------------------------------------------------
## Configuration
## --------------------------------------------------------------------------------------
Validate-Parameter $Name -parameterName "Name"
Validate-Parameter $Protocol -parameterName "Protocol"
Validate-Parameter $Port -parameterName "Port"
Validate-Parameter $HostName -parameterName "HostName"

Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
Import-Module WebAdministration -ErrorAction SilentlyContinue


## --------------------------------------------------------------------------------------
## Run
## --------------------------------------------------------------------------------------

$BindingString = ("*:" + $Port + ":" + $HostName)
echo($BindingString);

    if ( (get-WebBinding -Name $Name | Where-Object {$_.Protocol -eq $Protocol -and $_.bindingInformation -like $BindingString} ).Count -eq 1 ) {
	    echo "Removing WebBinding '$BindingString'"
	    Get-WebBinding -Name $Name | Where-Object {$_.Protocol -eq $Protocol -and $_.bindingInformation -like $BindingString} | Remove-WebBinding
	    echo "Removed WebBinding '$BindingString'"
    }
    else {
        echo "Binding does not exist. Creating"
        
    }

#Create Web Bindin
if ($Protocol -eq "http" -or $Protocol -eq "https") { 
    New-WebBinding -Name $Name -Protocol $Protocol -IPAddress $IPAddress -Port $Port -HostHeader $HostName
    if ($Protocol -eq "https") {
        #Binding Certificate to https
        echo ("Creating HTTPS Binding")
        Get-ChildItem 'IIS:\SslBindings\'  | Where-Object {$_.Sites -eq $Name } | Remove-Item
        echo("Binding to certificate " + $SSL_Certificae)
        $Path = "IIS:\SslBindings\0.0.0.0!" + $Port
        Get-ChildItem -Path Cert:\LocalMachine\My | where-Object {$_.Thumbprint -eq $SSL_Certificae} | new-item -path $Path -Force

    }   
}
else {
    echo "Protocol is not http or https"
    exit -5
}



