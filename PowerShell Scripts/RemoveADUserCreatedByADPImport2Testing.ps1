$DateCutOff=(Get-Date).AddDays(-2)
#Get-ADUser -Filter * -Property whenCreated | Where {$_.whenCreated -gt $datecutoff} | FT Name, whenCreated -Autosize
$users = Get-ADUser -Filter * -Property whenCreated | Where {$_.whenCreated -gt $datecutoff} | select SamAccountName
$kount = 0
foreach($user in $users)
{
    if($user.SamAccountName -eq "SV0037")
    {
        #Skip user
        $kount += 1
    }
    else
    {
        Remove-ADUser $user.SamAccountName -Confirm:$false
    }
}




#Get-ADUser -Filter {(employeeid -eq "8006433") }  -Properties entityID, mail, employeeid,  title, office, company, department | Select Name, UserPrincipalName, SamAccountName, Enabled, mail, employeeid, surname, givenname, title, office, company, department
#Get-ADUser -Filter {(employeeid -eq "2183265") -or (employeeid -eq "8006433") }  -Properties entityID, mail, employeeid,  title, office, company, department | Select Name, UserPrincipalName, SamAccountName, Enabled, mail, employeeid, surname, givenname, title, office, company, department