function CreatePersonObject()
{
    param ($fac, $SamAccountName, $name)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Facility -Value $fac
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName

    return $perObj
}

$facilities = "Athens","Auburn (MA)","East Ridge", "Hallmark Nursing Center (CO)","North Glendale","Orange Park","Puyallup","Westside Village Nursing Center"
$groupMembers = @()
foreach ($facility in $facilities)
{
    $users = Get-ADGroupMember -identity $facility -Recursive | Get-ADUser -Property Info,DisplayName, memberof| Select Name, SamAccountName, title, Enabled, mail,Info, memberof
    foreach($user in $users)
    {
        #$userName = $user.SamAccountName
        #$ADgroups = Get-ADUser -Filter {(SamAccountName -eq $userName) }  -Properties memberof | Select memberof
        foreach($group in $user.MemberOf)
        {
            if ($group -like 'CN=IDA_Nurse_UnitManager*')
            {
                $personObj = CreatePersonObject $facility $user.SamAccountName $user.Name
                $groupMembers += $personObj
            }
        } 
    }
}
$groupMembers
$groupMembers | export-csv -Path "C:\ps\IDAusers.csv"