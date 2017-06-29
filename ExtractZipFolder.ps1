#Cleans and Extracts a zipfile into a destination directory
#param1 = zipfile eg toUnzip.zip
#$param2 = Destination Directory eg c:\temp

param(
    [Parameter(Mandatory=$True)][string]$zipfile, 
    [Parameter(Mandatory=$True)][string]$outpath)

echo "Cleanup the folder $outpath"
Get-ChildItem -Path $outpath -Recurse | sort -Property @{ Expression = {$_.FullName.Split('\').Count} } -Desc | Remove-Item -force -recurse

echo "Unzip content"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)