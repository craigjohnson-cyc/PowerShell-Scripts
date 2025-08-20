# This Script will:
# •	Read an input CSV file containing a list of Job Titles/AD Groups and a type value to use to determine
#     if Job Title or AD Group.  A third action type EmptyGroup will remove all users from that AD group
# •	Remove all users from AD Groups with a type value of 'EmptyGroup'
# •	Add all users with a job title or belongs to an AD Group from the input file to the AD Group Sofcare_Read_Only
# •	Produce output files of users removed and added

Function Main
{
    $outputPath = "C:\ps\Output\"
    $inputFile = "C:\ps\Input\LegacyArchive_SofcareReadOnly.csv"
    # output files
    $membersRemovedFileName = $outputPath + "LegacyArchive_UsersRemovedFromGroups.csv"
    $membersAddedFileName = $outputPath + "LegacyArchive_AddedTo_Sofcare_Read_Only.csv"

    ProcessUsers $inputFile $membersRemovedFileName $membersAddedFileName

}

Function ProcessUsers
{
    param ($inputFile, $membersRemovedFileName, $membersAddedFileName)

    $usersToAdd = @()
    $usersAdded = @()
    $usersRemoved = @()

    # Read Input file
    $inputRecs = Import-Csv $inputFile

    foreach($rec in $inputRecs)
    {
        $operation = $rec.Type.ToLower()
        switch ($operation)
        {
        'emptygroup'
            {
                $groupName = $rec.Description
                # Get list of users currently in the AD group
                $membersToRemove =  (get-adgroup $groupName -Properties members).members

                # Remove all users currently in the group
                Remove-ADGroupMember -Identity $groupName -Members $membersToRemove  -Confirm:$false

                foreach( $user in $membersToRemove)
                {
                    $usersRemoved += CreateRemovedUserObject $user $groupName
                }
            }
        'jobtitle'
            {
                $users = @()
                $users = GetUsersByJobTitle $rec.Description

                $reason = "Added to Sofcare_Read_Only due to Job Title: " + $rec.Description
                foreach( $user in $users)
                {
                    $usersAdded += CreateAddedUserObject $user $reason
                }
                $usersToAdd += $users
            }
        'adgroup'
            {
                $users = @()
                $users += GetUsersByAdGroup $rec.Description
                
                $reason = "Added to Sofcare_Read_Only due to AD Group membership in: " + $rec.Description
                foreach( $user in $users)
                {
                    $usersAdded += CreateAddedUserObject $user $reason
                }
                $usersToAdd += $users
            }
        }

    }
    # write output file of users removed from groups
    $usersRemoved | export-csv $membersRemovedFileName  -NoTypeInformation

    # Add users to Sofcare_Read_Only
    #Add-ADGroupMember -Identity "Sofcare_Read_Only" -Members $usersToAdd

    # write output file of users added to Sofcare_Read_Only
    $usersAdded | export-csv $membersAddedFileName  -NoTypeInformation
}

Function CreateRemovedUserObject
{
    param ($user, $groupName)

    $action = "Removed from AD Group " + $groupName
    $userObj = New-Object PSObject
    $userObj | Add-Member -type NoteProperty -Name Name -Value $user
    $userObj | add-member -type NoteProperty -Name UserId -Value $action

    return $userObj
}

Function CreateAddedUserObject
{
    param ($user, $reason)

    $userObj = New-Object PSObject
    $userObj | Add-Member -type NoteProperty -Name Name -Value $user
    $userObj | add-member -type NoteProperty -Name UserId -Value $reason

    return $userObj
}

Function GetUsersByJobTitle
{
    param ($jobTitle)

    $users = @()
    $users = Get-ADUser -Filter "(enabled -eq 'True') -and (Title -eq '$jobTitle')" | Select DistinguishedName

    return $users
}

Function GetUsersByAdGroup
{
    param ($groupName)

    $users = @()
    $users = (get-adgroup $groupName -Properties members).members

    return $users
}

# Script Begins Here - Execute Function Main
Main