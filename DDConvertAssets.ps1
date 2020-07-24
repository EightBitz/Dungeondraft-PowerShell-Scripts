<#
.SYNOPSIS
Convert assets from supported formats to .webp format using ImageMagick.
ImageMagick can be downloaded from https://imagemagick.org
Suported formats are: bmp, dds, exr, hdr, jpg, jpeg, png, tga, svg, svgz

.DESCRIPTION
This script iterates through a specified subfolder, creates a duplicate of the folder structure, then converts each image file found in the source folder to a .webp file in the duplicate folder structure.
Supported image types are: bmp, dds, exr, hdr, jpg, jpeg, png, tga, svg, svgz

If a destination folder is not specified, the duplicate folder name will be the same as the source folder name with " - webp" appended to its name.
If the source folder is named "My Image Files", the duplicate folder will be named "My Image Files - webp"

This script uses ImageMagick to convert the files. ImageMagick can be downloaded from https://imagemagick.org

This script will also update data files to reflect the filename changes to .webp.

.PARAMETER Source
This specifies the source folder that contains the image files you wish to convert. This script is recursive, which means it will process any and all subfolders.

.PARAMETER Destination
This specifies the destination folder to which the webp files will be saved.

.EXAMPLE
DDConvertAssets.ps1 -Source "My PNG Files" -Destination "My webp Files"

.NOTES
You must have ImageMagick installed.
https://imagemagick.org
#>

param (
    [string]$Source = "",
    [string]$Destination = ""
) # param


function Test-ValidPathName {
    param([string]$PathName)

    $IndexOfInvalidChar = $PathName.IndexOfAny([System.IO.Path]::GetInvalidPathChars())

    # IndexOfAny() returns the value -1 to indicate no such character was found
    if($IndexOfInvalidChar -eq -1) {
        return $true
    } else {
        return $false
    } # if($IndexOfInvalidChar -eq -1)
} # function Test-ValidPathName

Function ValidateInput ($Src,$Dst) {
    $ReturnValue = [System.Collections.ArrayList]@()
    if ($Src -eq "") {
        $ReturnValue = "No value specified for Source."
        return $ReturnValue
    } # if ($Src -eq "")

    if (-not (Test-ValidPathName $Src)) {
        $ReturnValue = "Invalid path name for Source: $Src"
        return $ReturnValue
    } # if (-not (Test-ValidPathName $Src))

    if (-not (Test-Path $Src)) {
        $ReturnValue = "Cannot find Source: $Src."
        return $ReturnValue
    } # if (-not (Test-Path $Src))

    if ($Dst -eq "") {
        $ReturnValue = "No value specified for Destination."
        return $ReturnValue
    } # if ($Src -eq "")

    if (-not (Test-ValidPathName $Dst)) {
        $ReturnValue = "Invalid path name for Destination: $Dst"
        return $ReturnValue
    } # if (-not (Test-ValidPathName $Dst))

} # Function ValidateInput

Function InvalidExit {
    Write-Output ""
    Write-Output "SYNTAX"
    Write-Output "    $PSScriptRoot\DDConvertAssets.ps1 [[-Source] <String>] [[-Destination] <String>]"
    Write-Output ""
    Write-Output "REMARKS"
    Write-Output "    To see the examples, type: ""get-help $PSScriptRoot\DDConvertAssets.ps1 -examples""."
    Write-Output "    For more information, type: ""get-help $PSScriptRoot\DDConvertAssets.ps1 -detailed""."
    Write-Output "    For technical information, type: ""get-help $PSScriptRoot\DDConvertAssets.ps1 -full""."
    Write-Output ""
    Write-Output "REQUIRED DEPENDENCIES"
    Write-Output "    ImageMagick must be installed."
    Write-Output "    https://imagemagick.org/index.php"
    Write-Output ""
    Exit
} # Function InvalidExit

# Main {
    $StartNow = Get-Date
    $ScriptName = "DDConvertAssets.ps1"
    $Version = 7

    Write-Output ""
    Write-Output "### Starting $ScriptName V.$Version at $StartNow"
    Write-Output ""

    if ($Destination -eq "") {$Destination = "$Source - webp"}
    $Validate = $null
    $Validate = ValidateInput $Source $Destination
    if ($Validate -eq $null) {
        Write-Output "    Input validated."
    } else {
        Write-Output "    $Validate"
        Write-Output "### Exiting script due to invalid input."
        Write-Output ""
        InvalidExit
    } # if ($Validate.count -ge 1)

    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $ProgramFiles = $env:ProgramFiles

    $ImageMagick = ((Get-Item $ProgramFiles\ImageMagick*\magick.exe).FullName)

    if ($ImageMagick -eq $null) {
        $Validate = "Missing dependency: ImageMagick is not installed."
    } # if ($ImageMagick = $null)
    

    if ($Validate -eq $null) {
        Write-Output "    Dependencies validated."
    } else {
        Write-Output "    $Validate"
        Write-Output "### Exiting script due to missing dependency."
        Write-Output ""
        InvalidExit
    } # if ($Validate.count -ge 1)

    Write-Output ""
    Write-Output "    Source: $Source"
    Write-Output "    Destination: $Destination"
    Write-Output ""

    $Source = Get-Item $Source
    if (Test-Path $Destination) {
        Write-Output "    Parent destination folder already exists."
    } else {
        Write-Output "    Creating parent destination folder..."
        New-Item $Destination -ItemType Directory | Out-Null
    } # if (Test-Path $Destination)
    Write-Output ""

    # Create a duplicate folder structure in a "$Source - webp" folder.
    Write-Output "    Replicating  folder structure..."
    $Destination = Get-Item $Destination
    $FolderList = (Get-ChildItem $source -Recurse -Directory).FullName.replace($source,$Destination)
    foreach ($folder in $FolderList) {
        if (Test-Path $folder) {
            Write-Output "        $folder already exists."
        } else {
            Write-Output "        Creating $folder."
            New-Item $folder -ItemType Directory | Out-Null
        } # if (Test-Path $folder)
    } # foreach ($folder in $FolderList)
    Write-Output "    Finished Replicating folder structure."
    Write-Output ""

    $FileTypes = @(".bmp",".dds",".exr",".hdr",".jpg",".jpeg",".png",".tga",".svg",".svgz",".webp")
    $Wildcards = [System.Collections.ArrayList]@()
    foreach ($Extension in $FileTypes) {[void]$Wildcards.add("*$Extension")}

    $AllFolders = Get-ChildItem -Recurse -Directory $Source
    $TexturesFolder = @($AllFolders.fullname.where({$_ -like "*\textures\*"}))

    Write-Output "    Collecting  the list of all files from the parent source."
    $AllFiles = Get-ChildItem -Recurse -File $Source

    Write-Output "    Parsing which files are to be converted vs. which files are to be copied."
    $ImageFiles = $AllFiles.Where({$_.Extension.ToLower() -in $FileTypes})
    $TagFiles = $AllFiles.Where({$_.Name -eq "default.dungeondraft_tags"})
    $OtherFiles = $AllFiles.Where({($_.Extension.ToLower() -notin $FileTypes) -and ($_.Name -ne "default.dungeondraft_tags")})

    if ($TexturesFolder.Count -ge 1) {
        $ConvertFiles = $ImageFiles.Where({($_.DirectoryName -like "*\textures\objects\*") -and ($_.Extension.ToLower() -ne ".webp")})
        $CopyFiles = $ImageFiles.Where({($_.DirectoryName  -notlike "*\textures\objects\*") -or ($_.Extension.ToLower() -eq ".webp")})

        Write-Output "    Updating all default.dungeondraft_tags files to reference the .webp extension for converted files."
        foreach ($file in $TagFiles) {
            $DestinationFile = $file.fullname.replace($Source,$Destination)

            $FileContent = Get-Content $file.fullname
            foreach ($Extension in $FileTypes) {
                $FileContent = $FileContent -replace $Extension,'.webp'
            } # foreach ($Extension in $FileTypes)
            Set-Content $DestinationFile $FileContent | Out-Null
        } # foreach ($file in $TagFiles)
    } else {
        $ConvertFiles = $ImageFiles
        $CopyFiles = $null
        $OtherFiles = $null
    } # if (Test-Path $Source\textures\objects)

    Write-Output ""
    Write-Output  "    Converting appropriate assets to webp."
    foreach ($asset in $ConvertFiles) {
        $ImageAsset = $asset.FullName
        $DestAsset = $asset.DirectoryName + "\" + $asset.BaseName + ".webp"
        $DestAsset = $DestAsset.Replace($source,$Destination)

        if (Test-Path $DestAsset) {
            Write-Output  "        $DestAsset already exists."
        } else {
            Write-Output  "        Converting $ImageAsset"
            Write-Output  "                to $DestAsset"
            & $ImageMagick convert $ImageAsset $DestAsset
        } # if (Test-Path $DestAsset)
    } # foreach ($asset in $ConvertFiles)

    Write-Output ""
    Write-Output  "    Copying assets that shouldn't be converted."
    foreach ($asset in $CopyFiles) {
        $ImageAsset = $asset.FullName
        $DestAsset = $ImageAsset.Replace($source,$Destination)

        if (Test-Path $DestAsset) {
            Write-Output  "        $DestAsset already exists."
        } else {
            Write-Output  "        Copying $ImageAsset"
            Write-Output  "             to $DestAsset"
            Copy-Item $ImageAsset $DestAsset
        } # if (Test-Path $DestAsset)
    } # foreach ($asset in $CopyFiles)

    Write-Output ""
    Write-Output  "    Copying non-image files."
    foreach ($asset in $OtherFiles) {
        $ImageAsset = $asset.FullName
        $DestAsset = $ImageAsset.Replace($source,$Destination)

        if (Test-Path $DestAsset) {
            Write-Output  "        $DestAsset already exists."
        } else {
            Write-Output  "        Copying $ImageAsset"
            Write-Output  "             to $DestAsset"
            Copy-Item $ImageAsset $DestAsset
        } # if (Test-Path $DestAsset)
    } # foreach ($asset in $CopyFiles)

    Write-Output ""
    Write-Output  "    Finished converting assets."
    $EndNow = Get-Date
    $RunTime = $EndNow - $StartNow
    Write-Output  ("### Ending $ScriptName V.$Version at $EndNow with a run time of " + ("{0:hh\:mm\:ss}" -f $RunTime))
    Write-Output  ""
# } Main