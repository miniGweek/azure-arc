param(
    [Parameter(Mandatory)][String]$ArcHostName,
    [Parameter(Mandatory)][String]$ResourceGroupName,
    [Parameter(Mandatory)][String]$StorageAccount,
    [String]$Location = 'australiaeast',
    [Switch]$UploadRemoteContent,
    [String]$RemoteFolder,
    [String]$Container,
    [String]$SubFolder
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
    Get-ChildItem -Path $CommonScriptDir |
    ForEach-Object {
        $FileUris += "https://$StorageAccount.blob.core.windows.net/custom-scripts/scripts/$($_.Name)?$SASTokenToDownloadScripts"
    }

    $Setting = @{
        "forceUpdateTag" = "$CurrentTimeStamp"
        "fileUris"       = $FileUris
    }

    $ProtectedSetting = @{
        "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File scripts\Upload-Content.ps1 $RemoteFolder $StorageAccount $Container $SubFolder $SASTokenToUploadFile"
    };

    Write-Log "Installing CustomScriptExtension and executing script on $ArcHostName."

    New-AzConnectedMachineExtension `
        -Name "CustomScriptExtension" `
        -ResourceGroupName "$ResourceGroupName" `
        -MachineName "$ArcHostName" `
        -Location "$Location" `
        -Publisher "Microsoft.Compute"  `
        -Settings $Setting `
        -ProtectedSetting $ProtectedSetting `
        -ExtensionType CustomScriptExtension `
        -TypeHandlerVersion 1.10

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