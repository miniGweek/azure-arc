
param(
    [Parameter(Mandatory)][String]$RelativeDeploymentFolder,
    [Parameter(Mandatory)][String]$PCBTestTelitUpgradeFolder
)
$CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
try {
    $CurrentScriptPath = $MyInvocation.MyCommand.Path
    $CurrentScriptDir = Split-Path $CurrentScriptPath -Parent
    $CommonScriptDir = "$CurrentScriptDir";
    $env:LOGFILE_PATH = "C:\Temp\Logs\$env:computername.log"
    
    . "$CommonScriptDir\Common.ps1"
    Write-Log "*******Begin of PCBA Tools Installation Script *********"

    Write-Log "#####################"
    Write-Log "Input Paramters:"
    Write-Log "RelativeDeploymentFolder=$RelativeDeploymentFolder"
    Write-Log "PCBTestTelitUpgradeFolder=$PCBTestTelitUpgradeFolder"
    Write-Log "#####################"

    $DeploymentFolder = (Resolve-Path -Path "$RelativeDeploymentFolder").Path
    Write-Log "DeploymentFolder=$DeploymentFolder"

    Write-Log "Begin Download 7zip x64 version - 7z2201-x64.msi"
    Start-BitsTransfer -Destination "$DeploymentFolder\7z2201-x64.msi" -Source "https://7-zip.org/a/7z2201-x64.msi";
    Start-Process -FilePath "msiexec.exe" -Wait -ArgumentList "/i $DeploymentFolder\7z2201-x64.msi /qn"
    Write-Log "Install 7z2201-x64.msi"

    Write-Log "Begin Extracting arduino-1.8.19-windows.exe to $DeploymentFolder\Arduino folder."
    & "C:\Program Files\7-Zip\7z.exe" x "$DeploymentFolder\arduino-1.8.19-windows.exe" -o"$DeploymentFolder\Arduino"
    Write-Log "Finished Extracting arduino-1.8.19-windows.exe to $DeploymentFolder\Arduino."

    Extract-Cer -CatFilePath "$DeploymentFolder\Arduino\Drivers\AdafruitCircuitPlayground.cat" -OutputCerFilePath "$DeploymentFolder\AdafruitCircuitPlayground.cer"
    Extract-Cer -CatFilePath "$DeploymentFolder\Arduino\Drivers\arduino.cat" -OutputCerFilePath "$DeploymentFolder\arduino.cer"
    Extract-Cer -CatFilePath "$DeploymentFolder\Arduino\Drivers\linino-boards_amd64.cat" -OutputCerFilePath "$DeploymentFolder\linino-boards_amd64.cer"

    certutil -addstore "TrustedPublisher" "$DeploymentFolder\AdafruitCircuitPlayground.cer"
    certutil -addstore "TrustedPublisher" "$DeploymentFolder\arduino.cer"
    certutil -addstore "TrustedPublisher" "$DeploymentFolder\linino-boards_amd64.cer"

    Write-Log "Begin installing $DeploymentFolder\arduino-1.8.19-windows.exe."
    Start-Process -FilePath "$DeploymentFolder\arduino-1.8.19-windows.exe" -ArgumentList "/S" -Wait
    Write-Log "Finished Installing arduino-1.8.19-windows.exe."

    Write-Log "Begin Extracting $DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023.zip to $DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023 folder."
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -Wait -ArgumentList "x $DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023.zip -o$DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023"
    Start-Process -FilePath "$DeploymentFolder\IcpDll_setup_dll_13_25_1a_19-Jan-2023\IcpDll_setup_dll_13_25_1a_19-Jan-2023.exe" -Wait -ArgumentList "/SILENT"
    Write-Log "Finished InstallingSoftlog IcpDll_setup_dll_13_25_1a_19-Jan-2023.exe"

    Write-Log "Begin Extracting $DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer_2.19.0002.zip to $DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer folder."
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -Wait -ArgumentList "x $DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer_2.19.0002.zip -o$DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer"
    Start-Process -FilePath "msiexec.exe" -Wait -ArgumentList "/i $DeploymentFolder\Telit_Windows_10_WHQL_Drivers_Installer\Windows10WHQLDriversInstaller_2.19.0002\TelitWHQLDriversx64.msi /qn"

    Write-Log "Finished installing Telit USB Drivers"

    Reg import "$DeploymentFolder\Telit_ResuseUsbPort_Regedit.reg"

    Write-Log "Updated Registry file."

    New-item -Type Directory -Path "$PCBTestTelitUpgradeFolder" -Force | Out-Null
    Copy-Item -Path "$DeploymentFolder\ME9*" -Destination "$PCBTestTelitUpgradeFolder"

    Write-Log "Copied Telit Binaries"

    Write-Log "*******End of PCBA Tools Installation Script *********"
}
catch {
    Write-Log "***********Exception Begin***************"
    Write-Log $_
    Write-Log "***********Exception End***************"
}
finally {
    $ErrorActionPreference = $CurrentErrorActionPreference
}
