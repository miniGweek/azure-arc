param(
    [String]$DirectoryToUpload,
    [String]$StorageAccount,
    [String]$Container,
    [String]$ContainerDirectoryToUploadTo,
    [String]$SASTokenAsBase64String
)

$CurrentTimeStamp = Get-Date -Format "ddMMMyyyy.HHmmss.fff"
$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try {
    $CurrentScriptPath = $MyInvocation.MyCommand.Path
    $CurrentScriptDir = Split-Path $CurrentScriptPath -Parent
    $CommonScriptDir = "$CurrentScriptDir";
    $env:LOGFILE_PATH = "C:\Temp\Logs\$env:computername.log"
    
    . "$CommonScriptDir\Common.ps1"

    Write-Log "Input Parameters"
    Write-Log "#################"
    Write-Log "Directory=$DirectoryToUpload"
    Write-Log "StorageAccount=$StorageAccount"
    Write-Log "Container=$Container"
    Write-Log "ContainerDirectoryToUploadTo=$ContainerDirectoryToUploadTo"
    Write-Log "#################"
    Write-Log "Other local variables"
    Write-Log "CurrentScriptPath=$CurrentScriptPath"
    Write-Log "CurrentScriptDir=$CurrentScriptDir"
    Write-Log "CommonScriptDir=$CommonScriptDir"

    $FolderName = Split-Path -Path $DirectoryToUpload -Leaf
    $DestinationFile = "C:\Temp\$FolderName.$CurrentTimeStamp.zip"

    Compress-Archive -Path $DirectoryToUpload -DestinationPath $DestinationFile -CompressionLevel Fastest

    Write-Log "Compressed content of $Directory to the path $DestinationFile"

    Write-Log "Begin uploading file to blob."

    & "$CommonScriptDir\Upload-Blob.ps1" `
        -FilePath "$DestinationFile" `
        -DestinationFolder "$(hostname)\$ContainerDirectoryToUploadTo" `
        -StorageAccount "$StorageAccount"`
        -Container "$Container" `
        -SASTokenAsBase64String "$SASTokenAsBase64String" ;

    Write-Log "Finished uploading file to blob."
}
catch {
    $_
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}