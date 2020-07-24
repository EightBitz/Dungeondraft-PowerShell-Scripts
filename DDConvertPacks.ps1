<#
.SYNOPSIS
Unpack .dungeondraft_pack files, and convert any .png objects within to .webp

.DESCRIPTION
This script uses "dungeondraft-unpack.exe" to unpack .dungeondraft_pack files.
Then it uses the "DDConvertAssets.ps1" PowerShell script to create a duplicate folder structure while converting image files to .webp files.
Then it uses "dungeondraft-pack.exe" to repack the Converted Folders into .dungeondraft_pack files.
The "DDConvertAssets.ps1" script also updates the data files to reflect the changes in filenames.

.PARAMETER Source
This specifies the name of the asset pack or the name of the folder that contains the asset packs that you wish to convert.

.PARAMETER Destination
This specifies the parent folder where you wish to create the converted asset folders.
If this parameter is omitted, the default destination will be the same name as the source folder, appended with " - webp".
For example, if the source folder is "My_AssetPacks", the default destination folder will be "My_AssetPacks - webp".

Three folders will be created in the destination.
    "Unpacked Assets" will contain the original, unpacked assets.
    "Converted Folders" will contain a copy of everything in "Unpacked Assets" with all images converted to .webp and all data files updated to reflect this change.
    "Converted Packs" will contain .dungeondraft_pack files created from the folders in "Converted Folders".

.PARAMETER Include
This specifies a comma-separated list of the asset packs you wish to convert. Do not include the full path. Just include the file name.
If you omit this parameter, or if you include it with a value of *, the script will include all asset packs within the folder you specified as the source.

.PARAMETER Exclude
If you choose to include all asset packs in the source folder, this specifies a comma-separated list of any asset packs you might wish to exclude from conversion.
As with the Include parameter, Do not include the full path. Just include the file name.

.PARAMETER CleanUp
Setting this to true will delete the working folders ("Unpacked Assets" and "Converted Folders" when the script completes, leaving you only with "Converted Packs".
Setting this to false will leave the working folders in place.
The default setting is true.

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets"

Convert all the all the asset packs in "C:\Custom Assets" with the resulting files and folders to be stored in "C:\Custom Assets - webp"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets" -Include *

Convert all the the asset packs in "C:\Custom Assets" with the resulting files and folders to be stored in "C:\Custom Assets - webp"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets" -Include "AssetPack1.dungeondraft_pack"

Convert AssetPack1.dungeondraft_pack in "C:\Custom Assets" with the resulting files and folders to be stored in "C:\Custom Assets - webp"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets" -Include "AssetPack1.dungeondraft_pack,AssetPack2.dungeondraft_pack"

Convert AssetPack1.dungeondraft_pack and AssetPack2.dungeondraft_pack in "C:\Custom Assets" with the resulting files and folders to be stored in "C:\Custom Assets - webp"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets" -Exclude "AssetPack3.dungeondraft_pack,AssetPack4.dungeondraft_pack"

Convert all the the asset packs in "C:\Custom Assets", except for AssetPack3.dungeondraft.pack and AssetPack4.dungeondraft.pack, with the resulting files and folders to be stored in "C:\Custom Assets - webp"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets" -Destination "C:\webp Assets"

Convert all the all the asset packs in "C:\Custom Assets" with the resulting files and folders to be stored in "C:\webp Assets"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets\AssetPack1.dungeondraft.pack"

Convert only "C:\Custom Assets\AssetPack1.dungeondraft.pack" with the resulting files and folders to be stored in "C:\Custom Assets - webp"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets\AssetPack1.dungeondraft_pack" -Destination "C:\webp Assets"

Convert only "C:\Custom Assets\AssetPack1.dungeondraft_pack" with the resulting files and folders to be stored in "C:\webp Assets"

.EXAMPLE
DDConvertPacks -Source "C:\Custom Assets\AssetPack1.dungeondraft_pack" -Destination "C:\webp Assets" -Cleanup False

Convert only "C:\Custom Assets\AssetPack1.dungeondraft_pack" with the resulting files and folders to be stored in "C:\webp Assets"
Then leave the working folders in place. Do not delete them.

.NOTES

You must have the "DDConvertAssets.ps1" PowerShell script in the same folder as this script.
This can be found at https://github.com/EightBitz/Dungeondraft-Scripts

You must have "dungeondraft-unpack.exe" and "dungeondraft-pack.exe" in the same folder as this script.
These can be found at https://github.com/Ryex/Dungeondraft-GoPackager/releases/tag/v1.0.0

You must have "dungeondraft-pack.exe" and "dungeondraft-pack.exe" in the same folder as this script.
These can be found at https://github.com/Ryex/Dungeondraft-GoPackager/releases/tag/v1.0.0 
#>

# Command line parameters
param (
    [string]$Source = "",
    [string]$Destination = "",
    [string]$Include = "",
    [string]$Exclude = "",
    [string]$CleanUp= '$true'
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

function Test-ValidFileName {
    param([string]$FileName)

    $IndexOfInvalidChar = $FileName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars())

    # IndexOfAny() returns the value -1 to indicate no such character was found
    if($IndexOfInvalidChar -eq -1) {
        return $true
    } else {
        return $false
    } # if($IndexOfInvalidChar -eq -1)
} # function Test-ValidFileName

Function ValidateInput ($Src,$Dst,$IncList,$ExcList,$Cln) {

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

    if ($IncList.count -ge 1) {
        foreach ($Pck in $IncList.Split(",")) {
            if (-not (Test-ValidFileName $Pck)) {
                $ReturnValue = "Invalid file name in inclusion list: $Pck"
                return $ReturnValue
            } # if (-not (Test-ValidPathName $Src))

            if (-not (Test-Path $Src\$Pck)) {
                $ReturnValue = "Included pack file not found: $Pck"
                return $ReturnValue
            } # if (-not (Test-ValidPathName $Src))
        } # foreach ($Pck in $IncList)
    } # if ($IncList.count -ge 1)

    if ($ExcList.count -ge 1) {
        foreach ($Pck in $ExcList.Split(",")) {
            if (-not (Test-ValidFileName $Pck)) {
                $ReturnValue = "Invalid file name in exclusion list: $Pck"
                return $ReturnValue
            } # if (-not (Test-ValidPathName $Src))

            if (-not (Test-Path $Src\$Pck)) {
                $ReturnValue = "Excluded pack file not found: $Pck"
                return $ReturnValue
            } # if (-not (Test-ValidPathName $Src))
        } # foreach ($Pck in $ExcList)
    } # if ($ExcList.count -ge 1)

    $Cln = $Cln.ToLower()
    Switch ($Cln) {
        'true' {}
        '$true' {}
        "$true" {}
        $true {}

        'false' {}
        '$false' {}
        "$false" {}
        $false {}
        default {
            $ReturnValue = 'CleanUp must be True or False'
            return $ReturnValue
        } # default
    } # Switch ($Cln)

} # Function ValidateInput

Function StringToBool ($Str) {
    $Str = $Str.ToLower()
    Switch ($Str) {
        'true' {[bool]$Bool = $true}
        '$true' {[bool]$Bool = $true}
        "$true" {[bool]$Bool = $true}
        $true {[bool]$Bool = $true}

        'false' {[bool]$Bool = $false}
        '$false' {[bool]$Bool = $false}
        "$false" {[bool]$Bool = $false}
        $false {[bool]$Bool = $false}
    } # Switch ($Tag)
    return $Bool
} # Function StringToBool

Function Check-Dependencies {
    param([System.Collections.ArrayList]$DepList)

    foreach ($Dep in $DepList) {
        if (-not (Test-Path $Dep)) {
            $ReturnValue = "Missing dependency: $Dep"
            return $ReturnValue
        } # foreach ($Dep in $DepList)
    } # foreach ($Dep in $DepList)
} # Function Check-Dependencies

Function InvalidExit {
    Write-Output ""
    Write-Output "SYNTAX"
    Write-Output "    $PSScriptRoot\DDConvertPacks.ps1 [[-Source] <String>] [[-Destination] <String>] [[-Include] <String>] [[-Exclude] <String>] [[-CleanUp] <String>]"
    Write-Output ""
    Write-Output "REMARKS"
    Write-Output "    To see the examples, type: ""get-help $PSScriptRoot\DDConvertPacks.ps1 -examples""."
    Write-Output "    For more information, type: ""get-help $PSScriptRoot\DDConvertPacks.ps1 -detailed""."
    Write-Output "    For technical information, type: ""get-help $PSScriptRoot\DDConvertPacks.ps1 -full""."
    Write-Output ""
    Write-Output "REQUIRED DEPENDENCIES"
    Write-Output "    $PSScriptRoot\DDConvertAssets.ps1"
    Write-Output "    $PSScriptRoot\dungeondraft-unpack.exe"
    Write-Output "    $PSScriptRoot\dungeondraft-pack.exe"
    Write-Output ""
    Exit
} # Function InvalidExit

# Main {
    $StartNow = Get-Date
    $ScriptName = "DDConvertPacks.ps1"
    $Version = 5

    Write-Output ""
    Write-Output "### Starting $ScriptName V.$Version at $StartNow"
    Write-Output ""

    if ($Source.EndsWith(".dungeondraft_pack")) {
        $PackFileName = $Source.Substring($Source.LastIndexOf("\")+1)
        $SourcePath = $Source.Replace("\$PackFileName","")
        $Source = $SourcePath
        $Include = $PackFileName
    } # if ($SourcePath.Extension -eq ".dungeondraft_pack")

    if ($Destination -eq "") {$Destination = "$Source - webp"}

    if ($Include -eq "*") {$IncludeList = ""} else {$IncludeList = $Include.Split(",")}
    $ExcludeList = $Exclude
    $Validate = $null
    $Validate = ValidateInput $Source $Destination $IncludeList $ExcludeList $CleanUp
    if ($Validate -eq $null) {
        Write-Output "    Input validated."
    } else {
        Write-Output "    $Validate"
        Write-Output "### Exiting script due to invalid input."
        Write-Output ""
        InvalidExit
    } # if ($Validate.count -ge 1)

    $Dependencies = @(
        ($PSScriptRoot + "\DDConvertAssets.ps1")
        ($PSScriptRoot + "\dungeondraft-unpack.exe")
        ($PSScriptRoot + "\dungeondraft-pack.exe")
    ) # $Dependencies

    $Validate = Check-Dependencies $Dependencies
    if ($Validate -eq $null) {
        Write-Output "    Dependencies validated."
    } else {
        Write-Output "    $Validate"
        Write-Output "### Exiting script due to missing dependency."
        Write-Output ""
        InvalidExit
    } # if ($Validate.count -ge 1)

    # If an asterisk was used for $AssetFolders, get the full folder list for $AssetParent.
    #     Otherwise, split the comma-separated folder list into an array.
    #     Store the appropriate result in the $Include array
    $SourceItem = Get-Item $Source
    if (($SourceItem).PSIsContainer) {
        if (($Include -eq "*") -or ($Include -eq "")) {
            if ($Exclude -ne "") {
                $ExcludeArray = $Exclude.Split(",")
                $SelectedPacks = (Get-ChildItem $Source -Recurse -File -Filter "*.dungeondraft_pack") | Where-Object {$_.Name -NotIn $ExcludeArray}
                $Manifest = "all packs except $Exclude"
            } else {
                $SelectedPacks = Get-ChildItem $Source -Recurse -File -Filter "*.dungeondraft_pack"
                $Manifest = "all packs"
            } # if ($Exclude -ne "")
        } else {
            $SplitPacks = $Include.Split(",")
            $SelectedPacks = [System.Collections.ArrayList]@()
            foreach ($Pack in $SplitPacks) {[void]$SelectedPacks.add((Get-Item $Source\$Pack))}
            $Manifest = $Include
        } # if ($Include -eq "*")
    } else {
        if ($Destination -eq "") {$Destination = $SourceItem.Directory.FullName + " - webp"}
        $SelectedPacks = $SourceItem
        $Manifest = $SourceItem.Name
    } # if (($SourceItem).PSIsContainer)

    if (($Include -eq "*") -or ($Include -eq "")) {$PackSelection = "<all folders>"}
    Write-Output ""
    Write-Output "    Source: $Source"
    Write-Output "    Destination: $Destination"
    Write-Output "    Packs to include: $Manifest"
    Write-Output "    Packs to exclude: $Exclude"
    Write-Output ""

    $UnpackDestination = "$Destination\Unpacked Assets"
    $ConvertDestination = "$Destination\Converted Folders" 
    $RepackDestination = "$Destination\Converted Packs"

    Write-Output "    Processing each pack file..."
    Write-Output ""
    foreach ($Pack in $SelectedPacks) {
        $PackBaseName = $Pack.BaseName
        $PackName = $Pack.Name
        $UnpackSource = $Pack.FullName

        # Only process this particular pack if there's no folder for it yet.
        if (Test-Path $PackName) {
            Write-Output "        Skipping $PackName" + ": This pack file has already been unpacked."
        } else {
            Write-Output "        Unpacking ""$PackName"" with dungeondraft-unpack.exe..."
            & $PSScriptRoot\dungeondraft-unpack.exe $UnpackSource $UnpackDestination | Out-Null

            # If the destination folder does not yet exist, run the conversion.
            if (Test-Path "$ConvertDestination\$PackBasename") {
                Write-Output "        Skipping conversion of ""$PackName"": The destination folder already exists."
            } else {
                Write-Output "        Converting objects in $UnpackDestination\$PackBaseName to .webp with DDConvertAssets.ps1..."
                & $PSScriptRoot\DDConvertAssets.ps1 "$UnpackDestination\$PackBaseName" "$ConvertDestination\$PackBaseName"
            } # if (Test-Path $GUIDDestination)

            Write-Output "        Packing $ConvertDestination\$PackBaseName with dungeondraft-pack.exe..."
            & $PSScriptRoot\dungeondraft-pack.exe "$ConvertDestination\$PackBaseName" $RepackDestination | Out-Null

        } # if (Test-Path $PackName)
        Write-Output "        Finished unpacking and converting $PackName."
        Write-Output ""
    } # foreach ($Pack in $Include)
    Write-Output "    Finished processing pack files."
    Write-Output ""

    [bool]$CleanUp = StringToBool $CleanUp
    if ($CleanUp) {
        if (Test-Path $UnpackDestination) {
            Write-Output "    Removing $UnpackDestination..."
            Remove-Item $UnpackDestination -Recurse
        } # if (Test-Path $UnpackDestination)

        if (Test-Path $ConvertDestination) {
            Write-Output "    Removing $ConvertDestination..."
            Remove-Item $ConvertDestination -Recurse
        } # if (Test-Path $ConvertDestination)
        Write-Output "    Finished CleanUp"
    } # if ($CleanUp)

    Write-Output "    Finished converting packs."
    $EndNow = Get-Date
    $RunTime = $EndNow - $StartNow
    Write-Output ("### Ending $ScriptName V.$Version at $EndNow with a run time of " + ("{0:hh\:mm\:ss}" -f $RunTime))
    Write-Output ""
# } Main