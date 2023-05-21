# Parameter help description
param(
    # Parameter help description
    [Parameter(Mandatory)][String]$StorageAccount,
    [Parameter(Mandatory)][String]$Container,
    [Parameter(Mandatory)][String]$BlobPath,
    [String]$ScriptsDirectory
)
$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try {
    $CurrentScriptPath = $MyInvocation.MyCommand.Path
    $CurrentScriptDir = Split-Path $CurrentScriptPath -Parent
    $CommonScriptDir = "$CurrentScriptDir\scripts";
    $env:LOGFILE_PATH = "C:\Temp\Logs\proc_$env:computername.log"

    . "$CommonScriptDir\Common.ps1"
    . "$CommonScriptDir\Generate-SASToken.ps1"

    Write-Log "Executing $CurrentScriptPath."

    $SASTokenStartDate = Get-Date;
    $SASTokenExpirtyDate = $SASTokenStartDate.AddHours(4)

    $SASTokenBase64String = Get-StorageAccountSASToken `
        -AccountName "$StorageAccount" `
        -ContainerName "$Container" `
        -StartTime $SASTokenStartDate `
        -ExpiryTime $SASTokenExpirtyDate `
        -Permissions "rdlcw" `
        -ConvertToBase64

    if ("" -eq $ScriptsDirectory) {
        $ScriptsDirectory = $CommonScriptDir
    }

    Get-ChildItem $ScriptsDirectory |
    ForEach-Object {
        if ($False -eq $_.PSIsContainer) {
            Write-Log "*******************************"
            Write-Log "Begin upload of  $($_.FullName)"
            & "$CommonScriptDir\Upload-Blob.ps1" `
                -FilePath "$($_.FullName)" `
                -DestinationFolder "$BlobPath" `
                -StorageAccount "$StorageAccount"`
                -Container "$Container" `
                -SASTokenAsBase64String "$SASTokenBase64String" ;
            Write-Log "*******************************"
        }
    }
}
catch {
    Write-Log "***********Exception Begin***************"
    Write-Log $_
    Write-Log "***********Exception End***************"
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}