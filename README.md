# Instructions

## Install Azure Arc Agent on a Server

Run the following script on an elevated PowerShell window.

```PowerShell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; `
    Invoke-WebRequest -useb "https://raw.githubusercontent.com/miniGweek/azure-arc/main/Install-Arc-Agent.ps1" -OutFile Install-Arc-Agent.ps1; `
    .\Install-Arc-Agent.ps1 `
    -SUBSCRIPTION_ID "SUBSCRIPTION ID" `
    -RESOURCE_GROUP "RESOURCE GROUP" `
    -TENANT_ID "TENANT ID" `
    -LOCATION "LOCATION" -InstallAzureWindowsMonitoringAgent;
```

## Tools and Modules needed to run

- Azure Account
- Windows machine to run the scripts
- PowerShell 5.1
- Azure PowerShell Module. Download it from [here](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows)
  
## Azure RBAC Permissions

- `Azure Connected Machine Resource Administrator` RBAC role on the resource group where the Azure ARC enabled servers are deployed.
- `Storage Blob Data Contributor` RBAC role on the Storage Account that's used for uploading the custom scripts to, and upload workstation contents to.
