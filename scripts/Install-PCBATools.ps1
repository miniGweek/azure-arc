
param(
    [Parameter(Mandatory)][String]$DeploymentFolder,
    [Parameter(Mandatory)][String]$PCBTestTelitUpgradeFolder
)
$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

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

try {
    Start-BitsTransfer -Destination 7z2201-x64.msi -Source https://7-zip.org/a/7z2201-x64.msi;
    Start-Process -FilePath msiexec.exe -Wait -ArgumentList "/i 7z2201-x64.msi /qn"
    & "C:\Program Files\7-Zip\7z.exe" x .\arduino-1.8.19-windows.exe -oarduino

    Extract-Cer -CatFilePath "$DeploymentFolder\arduino\Drivers\AdafruitCircuitPlayground.cat" -OutputCerFilePath "$DeploymentFolder\AdafruitCircuitPlayground.cer"
    Extract-Cer -CatFilePath "$DeploymentFolder\arduino\Drivers\arduino.cat" -OutputCerFilePath "$DeploymentFolder\arduino.cer"
    Extract-Cer -CatFilePath "$DeploymentFolder\arduino\Drivers\linino-boards_amd64.cat" -OutputCerFilePath "$DeploymentFolder\linino-boards_amd64.cer"

    certutil -addstore "TrustedPublisher" "$DeploymentFolder\AdafruitCircuitPlayground.cer"
    certutil -addstore "TrustedPublisher" "$DeploymentFolder\arduino.cer"
    certutil -addstore "TrustedPublisher" "$DeploymentFolder\linino-boards_amd64.cer"

    Start-Process -FilePath "$DeploymentFolder\arduino-1.8.19-windows.exe" -ArgumentList "/S" -Wait

    Write-Host "Installed Arduino"

    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -Wait -ArgumentList "x $DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023.zip -oIcpDll_setup_dll_13_25_1a_19-Jan-2023"
    Start-Process -FilePath "$DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023\IcpDll_setup_dll_13_25_1a_19-Jan-2023.exe" -Wait -ArgumentList "/SILENT"

    Write-Host "Installed Softlog ICP"

    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -Wait -ArgumentList "x $DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer_2.19.0002.zip -oTelit_Windows_10_WHQL_Drivers_Installer"
    Start-Process -FilePath "msiexec.exe" -Wait -ArgumentList "/i $DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer\Windows10WHQLDriversInstaller_2.19.0002\TelitWHQLDriversx64.msi /qn"

    Write-Host "Installed Telit USB Drivers"

    reg import "$DeploymentFolder\Telit_ResuseUsbPort_Regedit.reg"

    Write-Host "Updated Registry file."

    New-item -Type Directory -Path .\test -Force | Out-Null
    Copy-Item -Path "$DeploymentFolder\" -Destination "$PCBTestTelitUpgradeFolder"

    Write-Host "Copied Telit Binaries"
}
catch {
    Write-Host $_
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}
