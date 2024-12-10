#Connect to Office 365 tenant
Connect-MsolService

#Get users and their Office location
$userList = get-msoluser -all | Where { $_.isLicensed -eq $True } | select displayname, UserPrincipalName, Office

#Set name of CSV to export list to
#$OutputCSV = "C:\Temp\userLocationList_$((Get-Date -format MM-dd-yyyy).ToString()).csv"
$preInput = "C:\Temp\"
$userInput = Read-Host "Enter name for CSV"
$postInput = "_OfficeLocation.csv"

$OutputCSV = $preInput + $userInput + $postInput
$OutputCSV
#Export to CSV
$userList | Export-Csv -NoTypeInformation $OutputCSV

#Disconnect session
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()