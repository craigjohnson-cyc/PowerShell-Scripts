$FromDate = (Get-Date).AddDays(+1)
$ToDate = (Get-Date).AddDays(+8)
$NameFilter = "Surveyor_0*"
$counter = 1

Get-ADUser -Filter ('sn -like $NameFilter') -Server LCCA -properties AccountExpirationDate | `
Where-Object{$_.AccountExpirationDate -gt ($FromDate) -and $_.AccountExpirationDate -lt ($ToDate) -and $_.AccountExpirationDate -ne $null} | select-object @{ Name = "ID" ; Expression= {$global:counter; $global:counter++} }, name, samaccountname, `
AccountExpirationDate | Sort-Object AccountExpirationDate