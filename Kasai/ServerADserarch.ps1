Import-Module WebAdministration -Verbose
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


$servers = Get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' `
-Properties Name,Operatingsystem,OperatingSystemVersion,IPv4Address |
Sort-Object -Property Operatingsystem |
Select-Object -Property Name,Operatingsystem,OperatingSystemVersion,IPv4Address
                                            
#$servers | Export-Csv -Path "C:\Development\PowerShellScripts\ADServerList.csv" -NoTypeInformation
$user = "MANAdmin"
$PasswordFile = ".\Keys\{0}.txt" -f $user.Trim()
$KeyFile = ".\Keys\{0}.key" -f $user.Trim()
$key = Get-Content $KeyFile
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)


foreach ($server in $servers) {  
    $session = New-PSSession -ComputerName $server.Name -Credential $creds
    Invoke-Command -Session $session -cred $creds -ScriptBlock {  
        Get-LocalGroupMember -Group Administrators | Write-Host "[$($server.Name)] $($_.Name)"  
    } -Credential $creds 
}  




$OUpath = 'ou=Alabama,dc=m-tekinc,dc=com'
#$ExportPath = 'c:\data\computers_in_ou.csv'
Get-ADComputer -Filter * -SearchBase $OUpath | Select-object DistinguishedName,DNSHostName,Name
Get-ADComputer -Filter "Name -like '*TALAPPS*'" -SearchBase $OUpath | Select-object DistinguishedName,DNSHostName,Name

Get-ADComputer -Filter * -SearchBase 'OU=Alabama, DC=m-tekinc, DC=com' -SearchScope 2

$ADGroupList = (Get-ADGroup -Filter * -searchbase "OU=Alabama,DC=m-tekinc,DC=com" -Properties *).Name