# Run This command first "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Set-ExecutionPolicy RemoteSigned
winrm quickconfig
winrm get winrm/config/client/auth
winrm set winrm/config/client/auth @{Basic="true"}
Install-Module -Name ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
$UserCredential = Get-Credential
Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true
