Get-MailboxFolderPermission -Identity john@contoso.com:\Calendar | Export-CSV c:\filepath\filename.csv
Remove-MailboxFolderPermission -Identity jen@contoso.com:\Calendar -User john@contoso.com
Add-MailboxFolderPermission -Identity jlegg@kmfpc.com:\calendar -user Nathan M. Schmidt  -AccessRights Reviewer
Get-Mailbox -Identity nathan@kmfpc.com

Add-MailboxFolderPermission -Identity jlegg@kmfpc.com:\calendar -user Nathan M. Schmidt  -AccessRights Reviewer