New-Item -Path 'C:\Powershell\NewFolder\file.txt'-ItemType File # For Create txt,xml,hmtl any type of file 
Copy-Item 'C:\Powershell\NewFolder\file.txt' 'C:\Powershell\file.txt'# For Copy File
Get-Content 'C:\Powershell.txt' # For Check Content of file
Move-Item 'C:\Powershell\NewFolder\file.txt' C:\file.txt # For move file one directory to another directory
Remove-Item 'C:\Powershell\file.txt' # For remove file
Rename-Item 'C:\file.txt' # For rename file
Set-Content C:\file.txt 'Infopercept' # For add Content in file
Test-Path 'C:\Powershell.txt' # For Check File is available or not
Clear-Content C:\file.txt # For delete all file content