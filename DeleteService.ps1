<#
Deletes a service whihc is passed as a parameter
#>

Param(
  [string]$ServiceDisplayName
  )
echo "Service Name: $ServiceDisplayName"

function Confirm-WindowsServiceExists ($name)
{
    if (Get-Service -Displayname $name -ErrorAction SilentlyContinue)
    {
        return $true
    }
    return $false
}

echo "Checking if Service Exists......."
if (Confirm-WindowsServiceExists $ServiceDisplayName) {
    echo "$ServiceName Service Exists. Will attempt to Stop & Remove service"
    $ServiceName =  Get-Service  -Displayname $ServiceDisplayName | select -first 1 -ExpandProperty Name
    Get-Service  -Displayname $ServiceDisplayName  | Stop-Service
    C:\Windows\System32\sc.exe delete $ServiceName

    if (Confirm-WindowsServiceExists $ServiceDisplayName) {
        #Problem Service has not been Deleted
        echo "error: Problem Service not successfully Deleted"
        Write-Error ("Problem Service not successfully Deleted")
        Exit 1

    }
    else {
        echo "Service Deleted Successfully"

    }
}

else{
    echo "Exit Success -> Service does not exist"
}
