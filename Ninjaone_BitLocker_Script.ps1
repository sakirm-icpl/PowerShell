##### HOW TO RUN:
##### .\script.ps1 <token>

# Define the drive letter you want to encrypt (e.g., "C:")
$driveLetter = "C:"

# Retrieve the Serial number of the machine
# try {
#     $assetSerialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber 
# }
# catch {
#     Write-Host "Error... Serial Key is not found $_.Exception"
# }
 
# For testing locally, uncomment below code and comment above try/catch block
$assetSerialNumber = "R90KWUV2" 

# Define the base URL for API calls
$baseUrl = "https://assets.ninjavan.co/api/v1/hardware"

# Define the URL to get device details
$getDeviceDetailUrl = "$baseUrl/byserial/$assetSerialNumber"

# Define the API token
$token = "Bearer " + $args[0]

# Function to get device details from API
Function Get-DeviceDetails {
    param([string]$url, [string]$token)
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
    # Check if the drive exists
    if (Test-Path -Path $driveLetter) {
        # Get the drive details
        $drive = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        # Check if the drive was found
        if ($drive) {
            # Enable BitLocker on the drive
            Enable-BitLocker -MountPoint $driveLetter -RecoveryPasswordProtector -SkipHardwareTest -UsedSpaceOnly
        }
        else {
            Write-Host "Drive $driveLetter not found."
        }
    }
    else {
        Write-Host "Invalid drive letter: $driveLetter"
    }
    # Get the recovery info for the drive
    $recoveryInfo = Get-BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } | Select-Object -Last 1
    # Return the recovery password
    return $recoveryInfo.RecoveryPassword
}

# Function to update device details on API
Function Update-DeviceDetails {
    param([string]$recoveryKey, [string]$deviceId, [string]$token)
    # Prepare the data to be sent to the API
    $data = @{ "_snipeit_bitlocker_36" = $recoveryKey } | ConvertTo-Json
    # Define the URL to update device details
    $patchDeviceDetailUrl = "$baseUrl/$deviceId"
    # Define headers for the API call
    $headers = @{ "Authorization" = $token; "Content-Type" = "application/json" }
    # Make a PATCH request to the API
    $response = Invoke-WebRequest -Uri $patchDeviceDetailUrl -Method 'PATCH' -Body $data -Headers $headers -UseBasicParsing
}

# Main script execution
try {
    try {
        # Get the device details
        $res = Get-DeviceDetails -url $getDeviceDetailUrl -token $token
    }
    catch {
        Write-Host "Error.. Device not Found"
        exit
    }
    
    # Check if BitLocker is not enabled on the device
    if ($null -eq $res.rows[0].custom_fields.Bitlocker) {
        # Enable BitLocker and get the recovery key
        $recoveryKey = Enable-BitLockerAndGetKey -driveLetter $driveLetter
        # Update the device details with the recovery key
        Update-DeviceDetails -recoveryKey $recoveryKey -deviceId $res.rows[0].id -token $token
    }
    else {
        # Check if BitLocker is turned off or not fully encrypted on the specified drive
        $bitLockerVolume = Get-BitLockerVolume -MountPoint $driveLetter
        if ($bitLockerVolume.ProtectionStatus -eq 'Off' -and $bitLockerVolume.EncryptionPercentage -ne '100') {
            Write-Host "BitLocker is turned off on drive $driveLetter"
            Write-Host "Turning on BitLocker for $driveLetter"

            # Enable BitLocker on the specified drive and retrieve the recovery key
            $recoveryKey = Enable-BitLockerAndGetKey -driveLetter $driveLetter

            # Update device details in the API with the recovery key
            Update-DeviceDetails -recoveryKey $recoveryKey -deviceId $res.rows[0].id -token $token
        }
        else {
            Write-Host "BitLocker is already turned ON on drive $driveLetter & key already exists in inventory"
        }
    }
} 
catch {
    Write-Host "Error...  $_"
}