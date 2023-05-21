param(
    [Parameter(Mandatory)][String]$SUBSCRIPTION_ID,
    [Parameter(Mandatory)][String]$RESOURCE_GROUP,
    [Parameter(Mandatory)][String]$TENANT_ID,
    [Parameter(Mandatory)][String]$LOCATION,
    [Switch]$InstallAzureWindowsMonitoringAgent
)

$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; `
        if ((Get-PackageProvider -Name NuGet -Force).version -lt 2.8.5.201) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; `
    
    } `
        if (Get-Module -ListAvailable -Name 'Az.ConnectedMachine') {
        Write-Host "'Az.ConnectedMachine' is installed."; `
     
    } `
        else {
        Write-Host "'Az.ConnectedMachine' isn't installed. Installing"; `
            Install-Module -Name 'Az.ConnectedMachine' -Force -Scope CurrentUser; `
    
    } `
        Import-Module Az.ConnectedMachine; `
        $ServicePrincipalClientId = Read-Host "Enter a Service Principal Application Id"; `
        $ServicePrincipalSecret = Read-Host "Enter the Password" -AsSecureString; `
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePrincipalSecret); `
        $ServicePrincipalSecretPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); `
        $env:SUBSCRIPTION_ID = "$SUBSCRIPTION_ID"; `
        $env:RESOURCE_GROUP = "$RESOURCE_GROUP"; `
        $env:TENANT_ID = "$TENANT_ID"; `
        $env:LOCATION = "$LOCATION"; `
        $env:AUTH_TYPE = "principal"; `
        $env:CORRELATION_ID = (New-Guid).Guid; `
        $env:CLOUD = "AzureCloud"; `
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; `
        Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/azcmagent-windows" `
        -TimeoutSec 30 -OutFile "$env:TEMP\install_windows_azcmagent.ps1"; `
        & "$env:TEMP\install_windows_azcmagent.ps1"; `
        if ($LASTEXITCODE -ne 0) { exit 1; } `
        & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" `
        connect --service-principal-id "$ServicePrincipalClientId" `
        --service-principal-secret "$ServicePrincipalSecretPlainText" `
        --resource-group "$env:RESOURCE_GROUP" `
        --tenant-id "$env:TENANT_ID" `
        --location "$env:LOCATION" `
        --subscription-id "$env:SUBSCRIPTION_ID" `
        --cloud "$env:CLOUD" `
        --correlation-id "$env:CORRELATION_ID"; `
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList "$servicePrincipalClientId", $ServicePrincipalSecret; `
        if ($InstallAzureWindowsMonitoringAgent.IsPresent) {
        Connect-AzAccount -ServicePrincipal -TenantId "$env:TENANT_ID" `
            -SubscriptionId "$env:SUBSCRIPTION_ID" `
            -Credential $Credential; `
            New-AzConnectedMachineExtension -Name 'AzureMonitorWindowsAgent' -ExtensionType 'AzureMonitorWindowsAgent' `
            -Publisher 'Microsoft.Azure.Monitor' -ResourceGroupName "$env:RESOURCE_GROUP" `
            -MachineName $(hostname) `
            -Location "$env:LOCATION" -EnableAutomaticUpgrade; `
            Remove-Item ~\.Azure\AzureRmContext.json; `
            Clear-AzContext; `
    
    };
}
catch {
    $logBody = @{subscriptionId = "$env:SUBSCRIPTION_ID"; resourceGroup = "$env:RESOURCE_GROUP"; tenantId = "$env:TENANT_ID"; location = "$env:LOCATION"; correlationId = "$env:CORRELATION_ID"; authType = "$env:AUTH_TYPE"; operation = "onboarding"; messageType = $_.FullyQualifiedErrorId; message = "$_"; }; `
        Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) | out-null; `
        Write-Host  -ForegroundColor red $_.Exception;
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference;
}