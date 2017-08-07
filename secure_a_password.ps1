<#
Making an encripted password for using in some other scripts.
Password encrypted string must be saved in text file. 
#>
$cwd = Get-Location
Write-Host "File with secure string will be saved in this directory: '$cwd'" -ForegroundColor Green
#$unique = -join ((0..42) + (50..100) | Get-Random -Count 4)
$user = Read-Host "Input Username (without domain).."
$user = $user -replace [Regex]::Escape('\'), '-'
$user = $user -replace [Regex]::Escape('/'), '-'
$enc_passwd = "$cwd\enc_passwd-$user.txt"
Read-Host "Input Password and press 'Enter'" -AsSecureString |  ConvertFrom-SecureString | Out-File $enc_passwd