$usbStorRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
$usbStorStartEnabled = Get-ItemProperty -Path $usbStorRegistryPath | Select-Object -ExpandProperty "Start"

if ($usbStorStartEnabled -eq 3) {
    # USB storage devices are currently enabled, so disable them
    Set-ItemProperty -Path $usbStorRegistryPath -Name "Start" -Value 4
    Write-Host "USB storage devices are now disabled."
} elseif ($usbStorStartEnabled -eq 4) {
    # USB storage devices are currently disabled, so enable them
    Set-ItemProperty -Path $usbStorRegistryPath -Name "Start" -Value 3
    Write-Host "USB storage devices are now enabled."
} else {
    Write-Host "Unable to determine the current state of USB storage devices."
}
