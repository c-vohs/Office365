$Alias = Read-Host -Prompt "Please enter Contact Alias ID, you wish to hide"

Set-MailContact "$Alias" -HiddenFromAddressListsEnabled $true