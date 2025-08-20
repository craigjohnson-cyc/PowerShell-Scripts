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
$u = Get-ADGroupMember -identity "Opt_DOR_SLP" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADGroupMember -identity "Opt_DOR_PTA" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADGroupMember -identity "Opt_DOR_PT" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADGroupMember -identity "Opt_DOR_OT" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADGroupMember -identity "Opt_DOR_COTA" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u

#$users
#$users | measure

foreach($user in $users)
{
    $PccUser = $false
    foreach($group in $user.MemberOf)
    {
        if ($group -like 'CN=PCC_DOR_ADOR*')
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

$NonPCCgroupMembers | export-csv -Path "C:\ps\Output\OptUsersNotPCC_DOR_ADOR.csv"
#foreach($user in $NonPCCgroupMembers)
#{
#    Add-ADGroupMember -Identity PCC_DOR_ADOR -Members $user.SamAccountName
#}
