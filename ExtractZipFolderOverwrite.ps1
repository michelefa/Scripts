<#
Extras an archive into a destination folder. 
Checks if file exists in the destinatio and overwrites
#>

param(
    [Parameter(Mandatory=$True)][string]$zipfile, 
    [Parameter(Mandatory=$True)][string]$outpath
)

function CreatePath($DirectoryPath) {
    if(!(Test-Path -Path $DirectoryPath )){
        New-Item -ItemType directory -Path $DirectoryPath
    }
}



# Load the required assembly.
Add-Type -AssemblyName System.IO.Compression.FileSystem
echo "Extracting ZIP: $zipfile"

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipfile)

# Loop through each item contained in the zip file.
foreach ($item in $zip.Entries) {
    # Attempt to unzip the file. If a file with the same name already exists, jump to the catch block.
    try {
        
        $ItemPath = (Join-Path -Path $outpath -ChildPath $item.FullName)
        CreatePath(Split-Path -Path $ItemPath)   

        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($item,$ItemPath,$false)
        echo "Extracted: $ItemPath"


    } catch {

        # If we're here, that means that a file already exists with the same name as the file that's being unzipped.
        # To work around this, we'll figure out what number can be appended to the name to make it unique.


        #Deletes the File since it will need to be replaced

            $FileToDelete = (Join-Path -Path $outpath -ChildPath $item.FullName)
            if (Test-Path $FileToDelete) {
                #if path is not directory
                if ((Get-Item $FileToDelete) -isnot [System.IO.DirectoryInfo] ) {
                    #Delete the old file
                    Remove-Item $FileToDelete -Force 
                    # Unzip the new File 
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($item,$FileToDelete,$false)
                    Write-Host("Replaced: $FileToDelete")
                    }
            }

    }

}