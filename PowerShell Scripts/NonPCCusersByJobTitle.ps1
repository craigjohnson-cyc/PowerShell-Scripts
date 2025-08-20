function CreatePersonObject()
{
    param ($SamAccountName, $fname, $lname, $title, $office)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name FirstName -Value $fname
    $perObj | Add-Member -type NoteProperty -Name LastName -Value $lname
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name JobTitle -Value $title
    $perObj | add-member -type NoteProperty -Name FacilityName -Value $office

    return $perObj
}

$PCCgroupMembers = @()
$NonPCCgroupMembers = @()
$users = @()
$u = get-aduser -LDAPFilter "(title=Registered Speech Therapist)" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Certified Occupational Therapy Assistant)" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Licensed Physical Therapist Assistant)" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Director of Rehab (Licensed OT))" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Director of Rehab (Licensed PT))" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Director of Rehab (Licensed PTA))" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Director of Rehab (Licensed COTA))" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Director of Rehab (Licensed ST))" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -LDAPFilter "(title=Director of Rehab)" -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u

#$users

foreach($user in $users)
{
    $PccUser = $false
    foreach($group in $user.MemberOf)
    {
        if ($group -like 'CN=PCC*')
        {
            $PccUser = $true
            break
        }
    } 
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    if ($PccUser -eq $true)
    {
        $PCCgroupMembers += $personObj
    }
    else
    {
        $NonPCCgroupMembers += $personObj
    }

}
$NonPCCgroupMembers | export-csv -Path "C:\ps\NonPccUsersByJobTitle.csv"