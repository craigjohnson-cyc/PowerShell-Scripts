function CreatePersonObject()
{
    param ($SamAccountName, $name)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName

    return $perObj
}


$groupMembers = @()
$users = Get-ADGroupMember -identity "Athens" -Recursive | Get-ADUser -Property Info,DisplayName, memberof| Select Name, SamAccountName, title, Enabled, mail,Info, memberof
foreach($user in $users)
{
    #$userName = $user.SamAccountName
    #$ADgroups = Get-ADUser -Filter {(SamAccountName -eq $userName) }  -Properties memberof | Select memberof
    foreach($group in $user.MemberOf)
    {
        if ($group -like 'CN=IDA_Nurse_UnitManager*')
        {
            $personObj = CreatePersonObject $user.SamAccountName $user.Name
            $groupMembers += $personObj
        }
    } 
}
$groupMembers