
$EmailUser = Read-Host "Enter Email Address"
$EmailUser=get-mailboxLocation –user $EmailUser | fl mailboxGuid,mailboxLocationType
Write-Host $EmailUser
