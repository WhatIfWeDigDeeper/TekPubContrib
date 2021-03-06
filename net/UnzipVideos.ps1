param([string]$ZipDir, [string]$Destination=$null, [switch]$RemoveZipFiles=$false)

# http://piers7.blogspot.com/2011/03/extract-zip-from-powershell.html
function Unzip-Tekpub($ZipDir, $destination)
{
    $shell = new-object -com shell.application;
    $zip = $shell.NameSpace($ZipDir);
    foreach($item in $zip.items()){
        if (-not $item.name.EndsWith("MACOSX"))
        {
            $shell.Namespace($destination).copyhere($item)
        }
    }
}

function Cleanup-Zip($ZipDir)
{
    Remove-Item -Path $ZipDir -Include *.zip 
}

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.ScriptName
}

function Default-ScriptDirectory($ZipDir)
{
    if ([string]::IsNullOrEmpty($ZipDir))
    {
        $ZipDir = Get-ScriptDirectory
    }
    return $ZipDir
}

function Default-ZipDir($Destination)
{
    if ([string]::IsNullOrEmpty($Destination))
    {
        $Destination = $ZipDir
    } 
    return $Destination
}

function Main-Unzip()
{
    $ZipDir = Default-ScriptDirectory $ZipDir
    $Destination = Default-ZipDir $Destination 
    
    $tempDest = join-path $ZipDir '/temp'
    if (-not (test-path $tempDest))
    {
        mkdir $tempDest
    }
    
    $ZipDirWithExtension = join-path $ZipDir '*.zip'
    
    #loop through zip files and unzip to temp directory
    Get-ChildItem -Path $ZipDirWithExtension | ForEach-Object { Unzip-Tekpub $_.FullName $tempDest }
    #have to do this twice for zip files containing zip files and put files in temp directory.
    Get-ChildItem -Path (join-path $tempDest *.zip) | ForEach-Object { Unzip-Tekpub $_.FullName $tempDest }
    
    #move out video files to original destination
    Move-Item -Path (join-path $tempDest '*.wmv')  -Destination $Destination
    Move-Item -Path (join-path $tempDest '*.mp4')  -Destination $Destination 
    
    #remove temp directory
    rmdir $tempDest
    
    if ($RemoveZipFiles)
    {
        Cleanup-Zip $ZipDirWithExtension
    }
   
}

Main-Unzip
