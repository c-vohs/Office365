

$Loc = (Read-Host "Please Enter Save location").ToString()
$Name = (Read-Host "Please Enter File Name").ToString() + ".csv"
$Path = $Loc + $Name
Write-Host $Path