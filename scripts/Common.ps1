function Write-Log {
    Param ([string]$LogString)
    $LogFile = $env:LOGFILE_PATH
    $LogDir = Split-Path $LogFile -Parent
    if ($False -eq (Test-Path -Path $LogDir)) {
        New-Item -ItemType Directory $LogDir -Force | Out-Null
    }
    $Stamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss.fff"
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    Write-Host $LogMessage
}

function Get-CurrentDate {
    return Get-Date -Format "ddMMMyyyy.HHmmss.fff"
}

Function Test-InstallAndImportModule {
    param(
        [Parameter(Mandatory)][String]$ModuleName
    )
    if (Get-Module -ListAvailable -Name "$ModuleName") {
        Write-Log "$ModuleName is installed.";
    } 
    else {
        Write-Log "$ModuleName isn't installed. Installing";
        Install-Module -Name "$ModuleName" -Force -Scope CurrentUser;
    } 
    Import-Module "$ModuleName"
    Write-Log "Imported $ModuleName module."
}

Function Extract-Cer {
    param(
        [string]$CatFilePath,
        [string]$OutputCerFilePath
    )
    Write-Host "Input:$CatFilePath - Output:$OutputCerFilePath"
    $CatFilePath = (Resolve-Path $CatFilePath).Path

    $exportType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert;
    $cert = (Get-AuthenticodeSignature $CatFilePath).SignerCertificate;
    [System.IO.File]::WriteAllBytes($OutputCerFilePath, $cert.Export($exportType));
}