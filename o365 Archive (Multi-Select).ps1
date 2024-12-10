<#
.SYNOPSIS
  Made to quicky access online archiving options, to save time and to work around GUI bugs
.DESCRIPTION
  The Script will give users five options, See "menu function for full list"
.NOTES
  Version:        2021.02
  Author:         James Shell
  Creation Date:  25.2.2021
  Purpose/Change: Fixed Start-ManagedFolderAssistant, by forcing it to use mailboxGuid instead of the mailbox email address.
  
.EXAMPLE
  View policy available
  Setup user on existing archive
  Setup custom archive
  Enable Auto Expanding Archive
  Force Archive to Start
#>

$ArchiveTag
$Days
$Policy
$EmailUser
$ReSelect = $Null
$CS = $False

function menu()
{
    Write-Host "----Menu----"
    Write-Host "1. View policy available"
    Write-Host "2. Setup user on existing archive"
    Write-Host "3. Setup custom archive"
    Write-Host "4. Enable Auto Expanding Archive"
    Write-Host "5. Force Archive to Start"
}

function RePrompt()
{
    If ($ReSelect -eq "y")
    {

    }
    elseif ($ReSelect -eq "n")
    {
        Exit
    }
    else
    {
        Write-Host "Please select y or n"
        $ReSelect = Read-Host -Prompt "Would you like to make other selection?"
        RePrompt
    }
}

function o365Archive()
{
Do{

    menu

    $UserSelect = Read-Host -Prompt "Please Type your selection (1-5)"


            switch($UserSelect)
                {
    
                    1{
                    Get-RetentionPolicy -Identity *
                    $ReSelect = Read-Host -Prompt "Would you like to make other selection?"
                    RePrompt
                    }
    
                    2{
                    $Policy = Read-Host -prompt "Enter name for Retention Policy"
                    $EmailUser = Read-Host -prompt "Enter Email Address"
                    Enable-Mailbox -Identity $EmailUser -Archive
                    $EmailUser = get-mailboxLocation –user $EmailUser | Select-Object -ExpandProperty mailboxGuid
                    Set-Mailbox $EmailUser -RetentionPolicy $Policy
                    Start-ManagedFolderAssistant –Identity $EmailUser
                    $ReSelect = Read-Host -Prompt "Would you like to make other selection?"
                    RePrompt
                    }
    
                    3{
                    $Policy = Read-Host -prompt "Enter name for Retention Policy"
                    $ArchiveTag = Read-Host -prompt "Enter name For Retention Tag"
                    $Days = Read-Host -prompt "Enter Age Limit For Retention (Value is in days)"
                    New-RetentionPolicyTag $ArchiveTag –Type All –RetentionEnabled $true –AgeLimitForRetention $Days –RetentionAction MoveToArchive
                    New-RetentionPolicy $Policy –RetentionPolicyTagLinks $ArchiveTag
                    $ReSelect = Read-Host -Prompt "Would you like to make other selection?"
                    RePrompt
                    }
    
                    4{
                    $EmailUser = Read-Host -prompt "Enter Email Address"
                    Enable-Mailbox $EmailUser -AutoExpandingArchive
                    $ReSelect = Read-Host -Prompt "Would you like to make other selection?"
                    RePrompt
                    }

                    5{
                    $EmailUser = Read-Host "Enter Email Address"
                    $EmailUser = get-mailboxLocation –user $EmailUser | Select-Object -ExpandProperty mailboxGuid
                    Start-ManagedFolderAssistant –Identity $EmailUser
                    $ReSelect = Read-Host -Prompt "Would you like to make other selection?"
                    RePrompt
                    }
    
                    default{
                    Write-Host "`n Please press 1-3 only `n"
                    }
                
                }
        


        

    
    }until($CS -eq $True)
}

o365Archive


#Todo 1.add feature to replace existing archive
#2.fixed force enable to detect id, possible fix Get-Mailbox <user@domain.com> | fl Name,ExchangeGuid,LegacyExchangeDN
#   Get-Mailbox <user@domain.com> | fl Name,ExchangeGuid,LegacyExchangeDN