Connect-ExchangeOnline

$mailboxes = Get-Mailbox -filter "($_.isMailboxEnabled -eq '$True') -and ($_.isShared -eq '$False')" | select DisplayName, UserPrincipalName | Sort-Object DisplayName
write-output = "Mailbox count: "$mailboxes.count

$Result = foreach ($mailbox in $mailboxes) {
    #write-output $mailbox.DisplayName
    $mailboxRules = get-inboxrule -Mailbox $mailbox.UserPrincipalName | select "Name", "Enabled", "Description"

    if (!($null) -eq $mailboxRules) {
        foreach ($rule in $mailboxRules) {
            #Write-Output $rule.Name

            [PSCustomObject]@{
                DisplayName = $mailbox.DisplayName
                UserPrincipalName = $mailbox.UserPrincipalName
                RuleName = $rule.Name
                Enabled = $rule.Enabled
                Description = $rule.Description
            }
        }
    } 
}

#$result | Out-GridView
$Result | Export-Csv -Path C:\Temp\o365Rules.csv
