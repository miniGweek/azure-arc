
param(
    [String]$FilePath,
    [String]$DestinationFolder,
    [String]$StorageAccount,
    [String]$Container,
    [String]$SASTokenAsBase64String
)
$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try {
       
    $CurrentScriptPath = $MyInvocation.MyCommand.Path
    Write-Log $CurrentScriptPath
    $CurrentScriptDir = Split-Path $CurrentScriptPath -Parent
    $CommonScriptDir = "$CurrentScriptDir";
    
    . "$CommonScriptDir\Common.ps1"

    Write-Log "Input Parameters"
    Write-Log "#################"
    Write-Log "FilePath=$FilePath"
    Write-Log "StorageAccount=$StorageAccount"
    Write-Log "Container=$Container"
    Write-Log "#################"
    if ("" -eq $DestinationFolder) {
        $DestinationFolder = "$(hostname)"
    }
    Write-Log "DestinationFolder=$DestinationFolder"

    $SASToken = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($SASTokenAsBase64String))

   
    $FileName = Split-Path $FilePath -Leaf
    Write-Log "FileName=$FileName"
    #The target URL wit SAS Token
    $Uri = "https://$StorageAccount.blob.core.windows.net/$Container/$DestinationFolder/$($FileName)?$SASToken"

    $BlobUploadParams = @{
        URI     = $Uri
        Method  = "PUT"
        Headers = @{
            'x-ms-blob-type'                = "BlockBlob"
            'x-ms-blob-content-disposition' = "attachment; filename=`"{0}`"" -f $FileName
            'x-ms-meta-m1'                  = 'v1'
            'x-ms-meta-m2'                  = 'v2'
        }
        Infile  = $FilePath
    }

    Write-Log "Begin uploading file to blob."
    #Upload to blob
    Invoke-RestMethod @BlobUploadParams

    Write-Log "Finished uploading file to blob."
}
catch {
    $_
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}
