$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange-ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

# Create an object to hold the results
$addresses = @()
# Get every mailbox in the Exchange Organisation
$Mailboxes = Get-Mailbox -ResultSize Unlimited

# Recurse through the mailboxes
ForEach ($mbx in $Mailboxes) {
    # Recurse through every address assigned to the mailbox
    Foreach ($address in $mbx.EmailAddresses) {
        # If it starts with “SMTP:” then it’s an email address. Record it
        if ($address.ToString().ToLower().StartsWith(“smtp:”)) {
            # This is an email address. Add it to the list
            $obj = “” | Select-Object Alias, EmailAddress
            $obj.Alias = $mbx.Alias
            $obj.EmailAddress = $address.ToString().SubString(5)
            $addresses += $obj
        }
    }
}
# Export the final object to a csv in the working directory
$addresses | Export-csv -path C:\temp\Alias_addresses.csv

Remove-PSSession $Session