
# Define the drive letter you want to encrypt (e.g., "C:")
$driveLetter = "C:"

# Retrieve the Serial number of the machine
$assetSerialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber

# Define the base URL for API calls
$baseUrl = "<BASE_URL>"

# Define the URL to get device details
$getDeviceDetailUrl = "$baseUrl/byserial/$assetSerialNumber"

# Define the API token
$token = "<TOKEN>"

# Define the log file location
$logFile = "C:\Program Files (x86)\ossec-agent\active-response\Bitlocker.log"

# Function to log messages
Function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
}

# Function to get device details from API
Function Get-DeviceDetails {
    param([string]$url, [string]$token)
    Write-Log "Getting device details from API."
    # Define headers for API call
    $headers = @{ "Authorization" = $token }

    # Make a GET request to the API
    $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -UseBasicParsing

    # Convert the response from JSON to a PowerShell object and return
    return $response | ConvertFrom-Json
}

# Function to enable BitLocker and get recovery key
Function Enable-BitLockerAndGetKey {
    param([string]$driveLetter)
    Write-Log "Checking if the drive exists: $driveLetter"
    # Check if the drive exists
    if (Test-Path -Path $driveLetter) {
        # Get the drive details
        $drive = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }

        # Check if the drive was found
        if ($drive) {
            Write-Log "Drive $driveLetter found. Checking for pending restart requirement."
            # Check for pending restart requirement
            $restartRequired = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue

            if ($restartRequired) {
                Write-Log "A restart is required before BitLocker can be enabled."
                Write-Host "A restart is required before BitLocker can be enabled. Please restart the computer and run the script again."
                return $null
            }

            Write-Log "Enabling BitLocker on drive $driveLetter."
            # Enable BitLocker on the drive
            Enable-BitLocker -MountPoint $driveLetter -RecoveryPasswordProtector -SkipHardwareTest -UsedSpaceOnly

            # Resume BitLocker if paused
            Write-Log "Resuming BitLocker protection if it is paused."
            Resume-BitLocker -MountPoint $driveLetter

            # Wait for encryption to complete
            Write-Log "Starting BitLocker encryption."
            $encryptStatus = Get-BitLockerVolume -MountPoint $driveLetter
            while ($encryptStatus.EncryptionPercentage -lt 100) {
                Start-Sleep -Seconds 60
                $encryptStatus = Get-BitLockerVolume -MountPoint $driveLetter
                Write-Log "Encryption in progress: $($encryptStatus.EncryptionPercentage)% completed."
            }
            Write-Log "Encryption completed for drive $driveLetter."
        }
        else {
            Write-Log "Drive $driveLetter not found."
            Write-Host "Drive $driveLetter not found."
        }
    }
    else {
        Write-Log "Invalid drive letter: $driveLetter"
        Write-Host "Invalid drive letter: $driveLetter"
    }
    # Get the recovery info for the drive
    $recoveryInfo = Get-BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } | Select-Object -First 1
    Write-Log "Recovery password obtained for drive $driveLetter."
    # Return the recovery password
    return $recoveryInfo.RecoveryPassword
}

# Function to update device details on API
Function Update-DeviceDetails {
    param([string]$recoveryKey, [string]$deviceId, [string]$token)
    Write-Log "Updating device details on API with recovery key."
    # Prepare the data to be sent to the API
    $data = @{ "_snipeit_bitlocker_36" = $recoveryKey } | ConvertTo-Json
    # Define the URL to update device details
    $patchDeviceDetailUrl = "$baseUrl/$deviceId"

    # Define headers for the API call
    $headers = @{ "Authorization" = $token; "Content-Type" = "application/json" }

    # Make a PATCH request to the API
    $response = Invoke-WebRequest -Uri $patchDeviceDetailUrl -Method 'PATCH' -Body $data -Headers $headers -UseBasicParsing
    Write-Log "Device details updated on API."
}

# Main script execution
try {
    Write-Log "Script execution started."
    # Get the device details
    $res = Get-DeviceDetails -url $getDeviceDetailUrl -token $token

    # Check if there is no Bitlocker key in inventory
    if ("" -eq $res.rows[0].custom_fields.Bitlocker.value) {
        Write-Log "No BitLocker key found in inventory."
        # Enable BitLocker and get the recovery key
        $recoveryKey = Enable-BitLockerAndGetKey -driveLetter $driveLetter
        if ($recoveryKey) {
            # Update the device details with the recovery key
            Update-DeviceDetails -recoveryKey $recoveryKey -deviceId $res.rows[0].id -token $token
            Write-Host "Key did not exist in SnipeIT, Bitlocker got enforced and key saved"
            Write-Log "BitLocker enforced and key saved."
        }
    }
    else {
        Write-Log "BitLocker key found in inventory."
        # Check if BitLocker is turned off or not fully encrypted on the specified drive
        $bitLockerVolume = Get-BitLockerVolume -MountPoint $

driveLetter

        if ($bitLockerVolume.ProtectionStatus -eq 'Off' -and $bitLockerVolume.EncryptionPercentage -ne '100') {
            Write-Log "BitLocker is turned off or not fully encrypted on drive $driveLetter."
            Write-Host "BitLocker is turned off on drive $driveLetter"
            Write-Host "Turning on BitLocker for $driveLetter"
            # Enable BitLocker on the specified drive and retrieve the recovery key
            $recoveryKey = Enable-BitLockerAndGetKey -driveLetter $driveLetter
            if ($recoveryKey) {
                # Update device details in the API with the recovery key
                Update-DeviceDetails -recoveryKey $recoveryKey -deviceId $res.rows[0].id -token $token
                Write-Host "Key already was there and Bitlocker got enforced"
                Write-Log "BitLocker enforced on drive $driveLetter and key updated in API."
            }
        }
        else {
            Write-Host "BitLocker is already turned ON on drive $driveLetter & key already exists in inventory"
            Write-Log "BitLocker is already turned ON on drive $driveLetter and key already exists in inventory."
        }
    }
}
catch {
    Write-Host "Error...  $_.Exception"
    Write-Log "Error: $_.Exception"
}
Write-Log "Script execution completed."

# Restart the Wazuh service
Restart-Service -Name "WazuhSvc" -Force

# Update ARStatus using ArStatusUpdate.exe
& "C:\Program Files (x86)\ossec-agent\active-response\bin\ArStatusUpdate.exe" bitlocker0