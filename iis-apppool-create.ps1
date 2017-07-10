## --------------------------------------------------------------------------------------
## Input
## --------------------------------------------------------------------------------------
param(
    [Parameter(Mandatory=$True)][string]$appPoolName
    )


$appPoolIdentityType = "ApplicationPoolIdentity"
IF ($appPoolIdentityType -eq "NetworkService")
{
    $appPoolIdentityUser = ""
    $appPoolIdentityPassword = ""
}

$appPoolLoadUserProfile = "true"

$appPoolAutoStart = "true"
$appPoolEnable32BitAppOnWin64 = "True"

$appPoolManagedRuntimeVersion = "v4.0"
$appPoolManagedPipelineMode = "Integrated"

$appPoolIdleTimeout = [TimeSpan]::FromMinutes("30")
$appPoolMaxProcesses = "1"
$appPoolRegularTimeInterval = [TimeSpan]::FromMinutes("1740")
$appPoolQueueLength = "1000"

$appPoolStartMode = "AlwaysRunning" #xxx

$appPoolCpuAction = "NoAction"
$appPoolCpuLimit = "0"

## --------------------------------------------------------------------------------------
## Helpers
## --------------------------------------------------------------------------------------
# Helper for validating input parameters
function Validate-Parameter([string]$foo, [string[]]$validInput, $parameterName) {
    IF (! $parameterName -contains "Password")
    {
        Write-Host "${parameterName}: $foo"
    }
    if (! $foo) {
        Write-Host "No value was set for $($parameterName), and it cannot be empty"
    }
}

# Helper to run a block with a retry if things go wrong
$maxFailures = 5
$sleepBetweenFailures = Get-Random -minimum 1 -maximum 4
function Execute-WithRetry([ScriptBlock] $command) {
	$attemptCount = 0
	$operationIncomplete = $true

	while ($operationIncomplete -and $attemptCount -lt $maxFailures) {
		$attemptCount = ($attemptCount + 1)

		if ($attemptCount -ge 2) {
			Write-Output "Waiting for $sleepBetweenFailures seconds before retrying..."
			Start-Sleep -s $sleepBetweenFailures
			Write-Output "Retrying..."
		}

		try {
			& $command

			$operationIncomplete = $false
		} catch [System.Exception] {
			if ($attemptCount -lt ($maxFailures)) {
				Write-Output ("Attempt $attemptCount of $maxFailures failed: " + $_.Exception.Message)

			}
			else {
			    throw "Failed to execute command"
			}
		}
	}
}

## --------------------------------------------------------------------------------------
## Configuration
## --------------------------------------------------------------------------------------
Validate-Parameter $appPoolName -parameterName "Application Pool Name"
Validate-Parameter $appPoolIdentityType -parameterName "Identity Type"
IF ($appPoolIdentityType -eq 3)
{
    Validate-Parameter $appPoolIdentityUser -parameterName "Identity UserName"
    Validate-Parameter $appPoolIdentityPassword -parameterName "Identity Password"
}
Validate-Parameter $appPoolLoadUserProfile -parameterName "Load User Profile"
Validate-Parameter $appPoolAutoStart -parameterName "AutoStart"
Validate-Parameter $appPoolEnable32BitAppOnWin64 -parameterName "Enable 32-Bit Apps on 64-bit Windows"

Validate-Parameter $appPoolManagedRuntimeVersion -parameterName "Managed Runtime Version"
Validate-Parameter $appPoolManagedPipelineMode -parameterName "Managed Pipeline Mode"

Validate-Parameter $appPoolIdleTimeout -parameterName "Process Idle Timeout"
Validate-Parameter $appPoolMaxProcesses -parameterName "Maximum Worker Processes"

Validate-Parameter $appPoolStartMode -parameterName "Start Mode"

Validate-Parameter $appPoolCpuAction -parameterName "CPU Limit Action"
Validate-Parameter $appPoolCpuLimit -parameterName "CPU Limit (percent)"

#Load Web Admin DLL
[System.Reflection.Assembly]::LoadFrom( "C:\\windows\\system32\\inetsrv\\Microsoft.Web.Administration.dll" )

Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
Import-Module WebAdministration -ErrorAction SilentlyContinue


## --------------------------------------------------------------------------------------
## Run
## --------------------------------------------------------------------------------------

$iis = (New-Object Microsoft.Web.Administration.ServerManager)

$pool = $iis.ApplicationPools | Where {$_.Name -eq $appPoolName} | Select-Object -First 1

IF ($pool -eq $null)
{
    Write-Output "Creating Application Pool '$appPoolName'"
    Execute-WithRetry {
        $iis = (New-Object Microsoft.Web.Administration.ServerManager)
        $pool = $iis.ApplicationPools.Add($appPoolName);
        $pool.AutoStart = $appPoolAutoStart;
        $iis.CommitChanges()
    }
}
ELSE
{
    Write-Output "Application Pool '$appPoolName' already exists, reconfiguring."
}

Execute-WithRetry {
    $iis = (New-Object Microsoft.Web.Administration.ServerManager)
    $pool = $iis.ApplicationPools | Where {$_.Name -eq $appPoolName} | Select-Object -First 1

    Write-Output "Setting: AutoStart = $appPoolAutoStart"
    $pool.AutoStart = $appPoolAutoStart;

    Write-Output "Setting: Enable32BitAppOnWin64 = $appPoolEnable32BitAppOnWin64"
    $pool.Enable32BitAppOnWin64 = $appPoolEnable32BitAppOnWin64;

    Write-Output "Setting: IdentityType = $appPoolIdentityType"
    $pool.ProcessModel.IdentityType = $appPoolIdentityType

    IF ($appPoolIdentityType -eq 3)
    {
        Write-Output "Setting: UserName = $appPoolIdentityUser"
        $pool.ProcessModel.UserName = $appPoolIdentityUser

        Write-Output "Setting: Password = [Omitted For Security]"
        $pool.ProcessModel.Password = $appPoolIdentityPassword
    }

	Write-Output "Setting: LoadUserProfile = $appPoolLoadUserProfile"
    $pool.ProcessModel.LoadUserProfile = $appPoolLoadUserProfile

    Write-Output "Setting: ManagedRuntimeVersion = $appPoolManagedRuntimeVersion"
    $pool.ManagedRuntimeVersion = $appPoolManagedRuntimeVersion

    Write-Output "Setting: ManagedPipelineMode = $appPoolManagedPipelineMode"
    $pool.ManagedPipelineMode = $appPoolManagedPipelineMode

    Write-Output "Setting: IdleTimeout = $appPoolIdleTimeout"
    $pool.ProcessModel.IdleTimeout = $appPoolIdleTimeout

    Write-Output "Setting: MaxProcesses = $appPoolMaxProcesses"
    $pool.ProcessModel.MaxProcesses = $appPoolMaxProcesses

    Write-Output "Setting: RegularTimeInterval = $appPoolRegularTimeInterval"
    $pool.Recycling.PeriodicRestart.Time = $appPoolRegularTimeInterval

    Write-Output "Setting: QueueLength = $appPoolQueueLength"
    $pool.QueueLength = $appPoolQueueLength

    Write-Output "Setting: CPU Limit (percent) = $appPoolCpuLimit"
    ## Limit is stored in 1/1000s of one percent
    $pool.Cpu.Limit = $appPoolCpuLimit * 1000

    Write-Output "Setting: CPU Limit Action = $appPoolCpuAction"
    $pool.Cpu.Action = $appPoolCpuAction

    if (Get-Member -InputObject $pool -Name StartMode -MemberType Properties)
    {
        Write-Output "Setting: StartMode = $appPoolStartMode"
        $pool.StartMode = $appPoolStartMode
    }
    else
    {
        Write-Output "IIS does not support StartMode property, skipping this property..."
    }

    $iis.CommitChanges()
}