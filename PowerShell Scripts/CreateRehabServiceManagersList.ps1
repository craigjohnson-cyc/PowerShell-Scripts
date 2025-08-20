Function Main
{
    $directors = @()
    $groupName = "Rehab Service Manager"
    $users = Get-ADGroupMember -identity $groupName -Recursive | Get-ADUser -Property description, enabled| Select Name, SamAccountName, description, enabled

 
    foreach($user in $users)
    {
        if($user.Enabled)
        {
            #$director = CreateUserObj $user.Name $user.description $user.samAccountName
            $director = CreateUserObj $user.samAccountName
            $directors += $director
        }
    }
    #$fileName = "c:\ps\output\RehabServiceManagerUsers.csv"
    $fileName = "c:\ps\output\RehabServiceManagerUserNames.csv"
    $directors | export-csv -Path $fileName -NoTypeInformation
}

Function CreateUserObj
{
    param ($samAccountName)
    #param ($Name, $userTitle, $samAccountName)

    $userObj = New-Object PSObject
    #$userObj | Add-Member -type NoteProperty -Name Name -Value $Name
    $userObj | Add-Member -type NoteProperty -Name userName -Value $samAccountName
    #$userObj | Add-Member -type NoteProperty -Name userTitle -Value $userTitle

    return $userObj

}

Main