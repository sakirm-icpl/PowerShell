New-Item -Path 'C:\NewPowerShellFolder' -ItemType Directory # For Create Folder
Copy-Item 'C:\NewPowerShellFolder' 'C:\Powershell' # For Copy Folder
Move-Item C:\NewPowerShellFolder C:\Powershell # For Move Folder
Rename-Item 'C:\Powershell\NewPowerShellFolder' # For Rename Folder
Remove-Item 'C:\Powershell\NewPowerShellFolder' # For Remove Folder
Test-Path 'C:\Powershell\NewFolder' # For Check Folder
