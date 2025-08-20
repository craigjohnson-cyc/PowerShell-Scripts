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

$groupMembers = @()
$u = Get-ADGroupMember -identity "Opt_DOR_SLP" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersOpt_DOR_SLP.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "Opt_DOR_PTA" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersOpt_DOR_PTA.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "Opt_DOR_PT" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersOpt_DOR_PT.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "Opt_DOR_OT" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersOpt_DOR_OT.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "Opt_DOR_COTA" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersOpt_DOR_COTA.csv"
