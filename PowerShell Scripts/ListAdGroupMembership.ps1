# This Script will:
# •	Read an input CSV file containing a list AD Groups
# • Create an output file listing users in the groups listed in the input file.

Function Main
{
    #$outputPath = "\\pes1\esss\Craig\PowerShell Scripts\Output\"
    $outputPath = "c:\\ps\Output\"
    $inputFile = "\\pes1\esss\Craig\PowerShell Scripts\Input\LegacyArchive_SofcareGroups.csv"
    # output files
    $d = Get-Date -Format "MMddyyyy_HH_mm"
    $SofcareGroupMembership = $outputPath + "LegacyArchive_ADGroupMembership_" + $d + ".csv"

    ProcessUsers $inputFile $SofcareGroupMembership

}

Function ProcessUsers
{
    param ($inputFile, $SofcareGroupMembership)

    $users = @()

    # Read Input file
    $inputRecs = Import-Csv $inputFile

    foreach($rec in $inputRecs)
    {
        $groupName = $rec.Description # "SofCare_BO"
        #$members = (get-adgroup $groupName -Properties members).members
        #$mKount = $members | measure
        #$membersKount = $mKount.Count

        $members2 = Get-ADGroupMember -identity $groupName -Recursive | Get-ADUser -Property Info,DisplayName, memberof| Select Name, SamAccountName, title, Enabled, mail,Info, memberof
        $mKount = $members2 | measure
        $members2Kount = $mKount.Count
        
        if($members2Kount -gt 0)
        {
            foreach($member in $members2)
            {
                #Create object
                $user = CreateUserObject $groupName $member.Name $member.SamAccountName
                #Add object to array
                $users += $user
            }
        }
        else
        {
            #Create object for 0 membership
            $user = CreateUserObject $groupName "Group contain No Members" ""
            #Add object to array
            $users += $user
        }

    }
    # write output file of users with membership to groups in input file
    $users | export-csv $SofcareGroupMembership  -NoTypeInformation
}

Function CreateUserObject
{
    param ($group, $name, $userId)

    $userObj = New-Object PSObject
    $userObj | Add-Member -type NoteProperty -Name ADGroup -Value $group
    $userObj | add-member -type NoteProperty -Name UserName -Value $name
    $userObj | add-member -type NoteProperty -Name UserId -Value $userId

    return $userObj
}

# Script Begins Here - Execute Function Main
Main