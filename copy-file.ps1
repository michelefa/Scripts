param(
    [Parameter(Mandatory=$True)][string]$source, 
    [Parameter(Mandatory=$True)][string]$destination
)

copy $source $destination