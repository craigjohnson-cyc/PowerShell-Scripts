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
$u = Get-ADGroupMember -identity "SofCare_Dashboard_read_only" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersSofCare_Dashboard_read_only.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "SofCare_Dashboard_read_print_only" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersSofCare_Dashboard_read_print_only.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "SofCare_Lab" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersSofCare_Lab.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "SofCare_Lab_Read_Only" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersSofCare_Lab_Read_Only.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "SofCare_Lab_Read_Print_only" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersSofCare_Lab_Read_Print_only.csv"
$groupMembers = @()

$u = Get-ADGroupMember -identity "SofCare_PO_Dashboard" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
foreach($user in $u)
{
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    $groupMembers += $personObj
}
$groupMembers | export-csv -Path "C:\ps\Output\ADusersSofCare_PO_Dashboard.csv"
$groupMembers = @()