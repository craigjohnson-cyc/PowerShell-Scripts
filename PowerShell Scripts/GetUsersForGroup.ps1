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
$u = Get-ADGroupMember -identity "RITA Clinical Support" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\RitaClinicalSupportUsers.csv" -NoTypeInformation
$groupMembers = @()

$u = Get-ADGroupMember -identity "RITA User" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\RitaUserUsers.csv" -NoTypeInformation
$groupMembers = @()
