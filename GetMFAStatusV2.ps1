Connect-MsolService
$Result = Get-msoluser -All | Where { $_.isLicensed -eq $True } | select DisplayName, UserPrincipalName, @{N = 'MFA State'; E = { ($_.StrongAuthenticationRequirements.State) } }, BlockCredential | Sort-Object DisplayName
$Result | Export-Csv -Path C:\Temp\MFA.csv