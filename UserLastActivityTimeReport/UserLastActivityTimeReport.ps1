<#
=============================================================================================
Name:           Export Office 365 users real last activity time report
Version:        3.0
Website:        o365reports.com
Script by:      O365Reports Team

Script Highlights :
~~~~~~~~~~~~~~~~~

1.	Reports the user’s activity time based on the user’s last action time(LastUserActionTime). 
2.	Exports result to CSV file. 
3.	Result can be filtered based on inactive days. 
4.	You can filter the result based on user/mailbox type. 
5.	Result can be filtered to list never logged in mailboxes alone. 
6.	You can filter the result based on licensed user.
7.	Shows result with the user’s administrative roles in the Office 365. 
8.	The assigned licenses column will show you the user-friendly-name like ‘Office 365 Enterprise E3’ rather than ‘ENTERPRISEPACK’. 
9.	The script can be executed with MFA enabled account. 
10.	The script is scheduler friendly. i.e., credentials can be passed as a parameter instead of saving inside the script. 


For detailed script execution:  https://o365reports.com/2019/06/18/export-office-365-users-real-last-logon-time-report-csv/#
============================================================================================
#>
#If you connect via Certificate based authentication, then your application required "Directory.Read.All" application permission, assign exchange administrator role and  Exchange.ManageAsApp permission to your application.
#Accept input parameter
Param
(
    [string]$MBNamesFile,
    [int]$InactiveDays,
    [switch]$UserMailboxOnly,
    [switch]$LicensedUserOnly,
    [switch]$ReturnNeverLoggedInMBOnly,
    [switch]$FriendlyTime,
    [string]$TenantId,
    [string]$ClientId,
    [string]$CertificateThumbprint
)
Function ConnectModules 
{
    $MsGraphBetaModule =  Get-Module Microsoft.Graph.Beta -ListAvailable
    if($MsGraphBetaModule -eq $null)
    { 
        Write-host "Important: Microsoft Graph Beta module is unavailable. It is mandatory to have this module installed in the system to run the script successfully." 
        $confirm = Read-Host Are you sure you want to install Microsoft Graph Beta module? [Y] Yes [N] No  
        if($confirm -match "[yY]") 
        { 
            Write-host "Installing Microsoft Graph Beta module..."
            Install-Module Microsoft.Graph.Beta -Scope CurrentUser -AllowClobber
            Write-host "Microsoft Graph Beta module is installed in the machine successfully" -ForegroundColor Magenta 
        } 
        else
        { 
            Write-host "Exiting. `nNote: Microsoft Graph Beta module must be available in your system to run the script" -ForegroundColor Red
            Exit 
        } 
    }
    $ExchangeOnlineModule =  Get-Module ExchangeOnlineManagement -ListAvailable
    if($ExchangeOnlineModule -eq $null)
    { 
        Write-host "Important: Exchange Online module is unavailable. It is mandatory to have this module installed in the system to run the script successfully." 
        $confirm = Read-Host Are you sure you want to install Exchange Online module? [Y] Yes [N] No  
        if($confirm -match "[yY]") 
        { 
            Write-host "Installing Exchange Online module..."
            Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
            Write-host "Exchange Online Module is installed in the machine successfully" -ForegroundColor Magenta 
        } 
        else
        { 
            Write-host "Exiting. `nNote: Exchange Online module must be available in your system to run the script" 
            Exit 
        } 
    }
    Disconnect-MgGraph  -ErrorAction SilentlyContinue| Out-Null
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Progress -Activity "Connecting modules(Microsoft Graph and Exchange Online module)..."
    try{
        if($TenantId -ne "" -and $ClientId -ne "" -and $CertificateThumbprint -ne "")
        {
            Connect-MgGraph  -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -ErrorAction SilentlyContinue -ErrorVariable ConnectionError|Out-Null
            if($ConnectionError -ne $null)
            {    
                Write-Host $ConnectionError -Foregroundcolor Red
                Exit
            }
            $Scopes = (Get-MgContext).Scopes
            if($Scopes -notcontains "Directory.Read.All" -and $Scopes -notcontains "Directory.ReadWrite.All")
            {
                Write-Host "Note: Your application required the following graph application permissions: Directory.Read.All" -ForegroundColor Yellow
                Exit
            }
            Connect-ExchangeOnline -AppId $ClientId -CertificateThumbprint $CertificateThumbprint  -Organization (Get-MgDomain | Where-Object {$_.isInitial}).Id -ShowBanner:$false
        }
        else
        {
            Connect-MgGraph -Scopes "Directory.Read.All"  -ErrorAction SilentlyContinue -Errorvariable ConnectionError |Out-Null
            if($ConnectionError -ne $null)
            {
                Write-Host $ConnectionError -Foregroundcolor Red
                Exit
            }
            Connect-ExchangeOnline -UserPrincipalName (Get-MgContext).Account -ShowBanner:$false
        }
    }
    catch
    {
        Write-Host $_.Exception.message -ForegroundColor Red
        Exit
    }
    Write-Host "Microsoft Graph Beta PowerShell module is connected successfully" -ForegroundColor Green
    Write-Host "Exchange Online module is connected successfully" -ForegroundColor Green
}
Function Get_LastLogonTime
{
    $MailboxStatistics = Get-MailboxStatistics -Identity $UPN
    $LastActionTime = $MailboxStatistics.LastUserActionTime
    $PercentComplete=($MBUserCount/($Mailboxes.Count))*100
    Write-Progress -Activity "`n     Processed mailbox count: $MBUserCount out of $($Mailboxes.Count)"`n"  Currently Processing: $DisplayName"  -PercentComplete $PercentComplete
    $Script:MBUserCount++ 
 
    #Retrieve lastlogon time and then calculate Inactive days 
    if($LastActionTime -eq $null)
    { 
        $LastActionTime = "Never Logged In" 
        $InactiveDaysOfUser = "-" 
    } 
    else
    { 
        $InactiveDaysOfUser = (New-TimeSpan -Start $LastActionTime).Days
        #Convert Last Action Time to Friendly Time
        if($friendlyTime.IsPresent) 
        {
            $FriendlyLastActionTime = ConvertTo-HumanDate ($LastActionTime)
            $friendlyLastActionTime = "("+$FriendlyLastActionTime+")"
            $LastActionTime = "$LastActionTime $FriendlyLastActionTime" 
        }
    }
    #Get licenses assigned to mailboxes 
    $Licenses = (Get-MgBetaUserLicenseDetail -UserId $UPN -ErrorAction SilentlyContinue).SkuPartNumber 
    $AssignedLicense = @()
    if($Licenses.Count -eq 0) 
    { 
        $AssignedLicense = "No License Assigned" 
    }  
    #Convert license plan to friendly name 
    else
    {
        foreach($License in $Licenses) 
        {
            $EasyName = $FriendlyNameHash[$License]  
            if(!($EasyName))  
            {
                $NamePrint = $License
            }  
            else  
            {
                $NamePrint = $EasyName
            } 
            $AssignedLicense += $NamePrint
        }
        $AssignedLicense = @($AssignedLicense) -join ','
    }
    #Inactive days based filter 
    if($InactiveDaysOfUser -ne "-")
    { 
        if(($InactiveDays -ne "") -and ([int]$InactiveDays -gt $InactiveDaysOfUser)) 
        { 
            return
        }
    } 

    #Filter result based on user mailbox 
    if(($UserMailboxOnly.IsPresent) -and ($MBType -ne "UserMailbox"))
    { 
        return
    } 

    #Never Logged In user
    if(($ReturnNeverLoggedInMBOnly.IsPresent) -and ($LastActionTime -ne "Never Logged In"))
    {
        return
    }

    #Filter result based on license status
    if(($LicensedUserOnly.IsPresent) -and ($AssignedLicense -eq "No License Assigned"))
    {
        return
    }
    #Get admin roles assigned to user 
    $RoleList=Get-MgBetaUserTransitiveMemberOf -UserId $UPN|Select-Object -ExpandProperty AdditionalProperties
    $RoleList = $RoleList|?{$_.'@odata.type' -eq '#microsoft.graph.directoryRole'}
    $Roles = @($RoleList.displayName) -join ','
    if($RoleList.count -eq 0)
    {
        $Roles = "No roles"
    }

    #Export result to CSV file 
    $Result = [PSCustomObject] @{'UserPrincipalName'=$UPN;'DisplayName'=$DisplayName;'LastUserActionTime'=$LastActionTime;'CreationTime'=$CreationTime;'InactiveDays'=$InactiveDaysOfUser;'MailboxType'=$MBType; 'AssignedLicenses'=$AssignedLicense;'Roles'=$Roles} 
    $Result | Export-Csv -Path $ExportCSV -Notype -Append
}
Function CloseConnection
{
    Disconnect-MgGraph | Out-Null
    Disconnect-ExchangeOnline -Confirm:$false
    Exit
}

#Connecting modules
ConnectModules
Write-Host "`nNote: If you encounter module related conflicts, run the script in a fresh PowerShell window.`n" -ForegroundColor Yellow

#Friendly DateTime conversion
if($FriendlyTime.IsPresent)
{
    if(((Get-Module -Name PowerShellHumanizer -ListAvailable).Count) -eq 0)
    {
        Write-Host Installing PowerShellHumanizer for Friendly DateTime conversion 
        Install-Module -Name PowerShellHumanizer
    }
}
$Result = ""  
$MBUserCount = 1 

#Get friendly name of license plan from external file 
$FriendlyNameHash = Get-Content -Raw -Path .\LicenseFriendlyName.txt -ErrorAction SilentlyContinue -ErrorVariable LicenseFileError | ConvertFrom-StringData
if($LicenseFileError -ne $null)
{
    Write-Host $LicenseFileError -ForegroundColor Red
    CloseConnection
}

#Set output file 
$Path = (Get-Location).Path
$ExportCSV = "$Path\LastAccessTimeReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm-ss` tt).ToString()).csv"

#Check for input file
if([string]$MBNamesFile -ne "") 
{ 
    #We have an input file, read it into memory 
    $Mailboxes = @()
    try{
        $Mailboxes = Import-Csv -Header "MBIdentity" $MBNamesFile
    }
    catch
    {
        Write-Host $_.Exception.Message -ForegroundColor Red
        CloseConnection
    }
    Foreach($item in $Mailboxes)
    {
        $MBDetails = Get-Mailbox -Identity $item.MBIdentity
        $DisplayName = $MBDetails.DisplayName 
        $UPN = $MBDetails.UserPrincipalName 
        $CreationTime = $MBDetails.WhenCreated
        $MBType = $MBDetails.RecipientTypeDetails
        Get_LastLogonTime    
    }
}

#Get all mailboxes from Office 365
else
{
    $MailBoxes = Get-Mailbox -ResultSize Unlimited| Where {$_.DisplayName -notlike "Discovery Search Mailbox"} 
    ForEach($Mail in $MailBoxes) {
        $DisplayName=$Mail.DisplayName  
        $UPN = $Mail.UserPrincipalName 
        $CreationTime = $Mail.WhenCreated
        $MBType = $Mail.RecipientTypeDetails
        Get_LastLogonTime
    } 
}

#Open output file after execution 
if((Test-Path -Path $ExportCSV) -eq "True")
{
    Write-Host "Detailed report available in:" -NoNewline -Foregroundcolor Yellow; Write-Host $ExportCSV
    $Prompt = New-Object -ComObject wscript.shell  
    $UserInput = $Prompt.popup("Do you want to open output file?",` 0,"Open Output File",4)  
    if ($UserInput -eq 6)  
    {  
        Invoke-Item "$ExportCSV"  
    } 
}
else
{
    Write-Host "No mailbox found" -ForegroundColor Red
}
Write-Host `n~~ Script prepared by AdminDroid Community ~~`n -ForegroundColor Green
Write-Host "~~ Check out " -NoNewline -ForegroundColor Green; Write-Host "admindroid.com" -ForegroundColor Yellow -NoNewline; Write-Host " to get access to 1800+ Microsoft 365 reports. ~~" -ForegroundColor Green `n`n
CloseConnection