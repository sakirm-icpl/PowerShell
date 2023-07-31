#A Hello world ps script

#param($firstName,$lastName)

#Write-Host "Hello $firstName $lastName"
#Write-Host "You are login form $env:COMPUTERNAME"
#Write-Host "We will meet someday"


#B Hello world ps script

$firstName = $args[0]
$lastName = $args[1]

Write-Host "Hello $firstName $lastName"
Write-Host "You are login form $env:COMPUTERNAME"
Write-Host "We will meet someday"
