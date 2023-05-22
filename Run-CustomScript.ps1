param(
    [Parameter(Mandatory)][String]$HostName,
    [Parameter(Mandatory)][String]$ResourceGroupName,
    [Parameter(Mandatory)][String]$StorageAccount,
    [String]$Location = 'australiaeast',    
    [String]$RemoteFolderToUpload,
    [String]$CustomScriptsContainer,
    [String]$UploadContainer,
    [String]$BlobPathForRemoteUploadedContent,
    [String]$TelitBinaryCopyToFolder,
    [Switch]$UploadRemoteContent,
    [Switch]$InstallPCBATools,
    [Switch]$AzureVM
)
$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try {
    $CurrentScriptPath = $MyInvocation.MyCommand.Path
    $CurrentScriptDir = Split-Path $CurrentScriptPath -Parent
    $CommonScriptDir = "$CurrentScriptDir\scripts";

    . "$CommonScriptDir\Common.ps1"
    . "$CommonScriptDir\Generate-SASToken.ps1"

    $env:LOGFILE_PATH = "C:\Temp\Logs\proc_$env:computername.log"
    $CurrentTimeStamp = Get-Date -Format "ddMMMyyyy.HHmmss.fff"

    if ((Get-PackageProvider -Name NuGet).version -lt 2.8.5.201) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
    }
    
    Test-InstallAndImportModule -ModuleName "Az.ConnectedMachine"
    
    $SASTokenStartDate = Get-Date;
    $SASTokenExpirtyDate = $SASTokenStartDate.AddMinutes(15)

    $SASTokenToDownloadScripts = Get-StorageAccountSASToken `
        -AccountName "$StorageAccount" `
        -ContainerName "custom-scripts" `
        -StartTime $SASTokenStartDate `
        -ExpiryTime $SASTokenExpirtyDate `
        -Permissions "rl"

    Write-Log "Generated SASToken for download scripts from the storage account"

    $SASTokenToUploadFile = Get-StorageAccountSASToken `
        -AccountName "$StorageAccount" `
        -ContainerName "workstation-uploads" `
        -StartTime $SASTokenStartDate `
        -ExpiryTime $SASTokenExpirtyDate `
        -Permissions "cw" `
        -ConvertToBase64

    Write-Log "Generated SASToken for uploading content to the storage account"

    $FileUris = @();

    New-AzStorageContext -StorageAccountName "$StorageAccount"  -UseConnectedAccount | 
    Get-AzStorageBlob -Container "$CustomScriptsContainer" |
    ForEach-Object {
        $BlobAbsoluteUri = $_.ICloudBlob.Uri.AbsoluteUri 
        $FileUris += "$BlobAbsoluteUri`?$SASTokenToDownloadScripts"
    } 

    $Setting = @{
        "forceUpdateTag" = "$CurrentTimeStamp"
        "fileUris"       = $FileUris
    }

    if ($UploadRemoteContent.IsPresent) {
        $ProtectedSetting = @{
            "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File scripts\Upload-Content.ps1 $RemoteFolderToUpload $StorageAccount $UploadContainer $BlobPathForRemoteUploadedContent $SASTokenToUploadFile"
        };
    }
    elseif ($InstallPCBATools.IsPresent) {
        $ProtectedSetting = @{
            "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File scripts\Install-PCBATools.ps1 .\deployment-files $TelitBinaryCopyToFolder"
        };
    }

    Write-Log "Installing CustomScriptExtension and executing script on $HostName."

    if ($False -eq $AzureVM.IsPresent) {
        New-AzConnectedMachineExtension `
            -Name "CustomScriptExtension" `
            -ResourceGroupName "$ResourceGroupName" `
            -MachineName "$HostName" `
            -Location "$Location" `
            -Publisher "Microsoft.Compute"  `
            -Settings $Setting `
            -ProtectedSetting $ProtectedSetting `
            -ExtensionType CustomScriptExtension `
            -TypeHandlerVersion 1.10
    }
    else {
        Set-AzVMExtension `
            -Name "CustomScriptExtension" `
            -ResourceGroupName  "$ResourceGroupName" `
            -VMName "$HostName" `
            -Location "$Location" `
            -Publisher "Microsoft.Compute"  `
            -Settings $Setting `
            -ProtectedSettings $ProtectedSetting `
            -ExtensionType CustomScriptExtension `
            -TypeHandlerVersion 1.10
    }

    Write-Log "Finished running CustomScriptExtension"
}
catch {
    Write-Log "***********Exception Begin***************"
    Write-Log $_
    Write-Log "***********Exception End***************"
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}