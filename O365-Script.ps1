$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

Get-Recipient "mbolton@jeffersoncountytn.gov" | fl

$ExportCSV = "C:\Temp\O365Report.csv"

Get-Mailbox -ResultSize Unlimited | Where { $_.DisplayName -notlike "Discovery Search Mailbox" } | ForEach-Object {
    $upn = $_.UserPrincipalName
    $CreationTime = $_.WhenCreated
    $LastLogonTime = (Get-MailboxStatistics -Identity $upn).lastlogontime
    $DisplayName = $_.DisplayName
    $MBType = $_.RecipientTypeDetails
    $Print = 1
    $MBUserCount++
    $RolesAssigned = ""
    Write-Progress -Activity "`n     Processed mailbox count: $MBUserCount "`n"  Currently Processing: $DisplayName"

    #Retrieve lastlogon time and then calculate Inactive days
    if ($LastLogonTime -eq $null) {
        $LastLogonTime = "Never Logged In"
        $InactiveDaysOfUser = "-"
    }
    else {
        $InactiveDaysOfUser = (New-TimeSpan -Start $LastLogonTime).Days
    }

    #Get licenses assigned to mailboxes
    $User = (Get-MsolUser -UserPrincipalName $upn)
    $Licenses = $User.Licenses.AccountSkuId
    $AssignedLicense = ""
    $Count = 0

    #Convert license plan to friendly name
    foreach ($License in $Licenses) {
        $Count++
        $LicenseItem = $License -Split ":" | Select-Object -Last 1
        $EasyName = $FriendlyNameHash[$LicenseItem]
        if (!($EasyName))
        { $NamePrint = $LicenseItem }
        else
        { $NamePrint = $EasyName }
        $AssignedLicense = $AssignedLicense + $NamePrint
        if ($count -lt $licenses.count) {
            $AssignedLicense = $AssignedLicense + ","
        }
    }
    if ($Licenses.count -eq 0) {
        $AssignedLicense = "No License Assigned"
    }

    #Inactive days based filter
    if ($InactiveDaysOfUser -ne "-") {
        if (($InactiveDays -ne "") -and ([int]$InactiveDays -gt $InactiveDaysOfUser)) {
            $Print = 0
        }
    }

    #License assigned based filter
    if (($UserMailboxOnly.IsPresent) -and ($MBType -ne "UserMailbox")) {
        $Print = 0
    }

    #Never Logged In user
    if (($ReturnNeverLoggedInMB.IsPresent) -and ($LastLogonTime -ne "Never Logged In")) {
        $Print = 0
    }

    #Get roles assigned to user
    $Roles = (Get-MsolUserRole -UserPrincipalName $upn).Name
    if ($Roles.count -eq 0) {
        $RolesAssigned = "No roles"
    }
    else {
        foreach ($Role in $Roles) {
            $RolesAssigned = $RolesAssigned + $Role
            if ($Roles.indexof($role) -lt (($Roles.count) - 1)) {
                $RolesAssigned = $RolesAssigned + ","
            }
        }
    }

    #Export result to CSV file
    if ($Print -eq 1) {
        $OutputCount++
        $Result = @{'UserPrincipalName' = $upn; 'DisplayName' = $DisplayName; 'LastLogonTime' = $LastLogonTime; 'CreationTime' = $CreationTime; 'InactiveDays' = $InactiveDaysOfUser; 'MailboxType' = $MBType; 'AssignedLicenses' = $AssignedLicense; 'Roles' = $RolesAssigned }
        $Output = New-Object PSObject -Property $Result
        $Output | Select-Object UserPrincipalName, DisplayName, LastLogonTime, CreationTime, InactiveDays, MailboxType, AssignedLicenses, Roles | Export-Csv -Path $ExportCSV -Notype -Append
    }
}