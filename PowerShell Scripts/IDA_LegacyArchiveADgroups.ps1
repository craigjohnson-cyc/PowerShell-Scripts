# This Script will:
# •	Read a CSV file created from an Excel spreadsheet from Teams
# •	For each row in the spreadsheet, 1) Add all users in the AD group named in Column A to the group named in Column B
# •                                  2) Remove all users from the AD group named in column A

# STEPS FOR EXECUTION
# 1) Create new CSV from Excel file kept in Teams
# 2) Place CSV in Input Location
# 3) Modify Line 14 with input path for CSV file
# 4) Modify Line 15 with output path for output CSV and log file

Function Main
{
    $inputPath = "C:\ps\Input\"
    $outputPath = "C:\ps\Output\"

    $operations = GetCSVdata $inputPath

    $actions = ProcessOperations $operations
    $outfile = $outputPath + "IDA_LegacyArchiveADgroups_log.csv"
    $actions | export-csv -Path $outfile -NoTypeInformation


}

Function GetCSVdata
{
    param ($path)

    $file = $path + "IDA_LegacyArchiveADgroups.csv"

    $csv = Import-Csv $file

    return $csv
}

Function ProcessOperations
{
    param ($operations)

    $actions = @()

    foreach($operation in $operations)
    {
        #Check the status column to see if this operation has any specian instructions
        #if($operation.Comments.ToString().Trim().Length -gt 0)
        #{
        #    if($operation.Completed -like "*HIM*")
        #    {
        #         $userActions = MoveHIMDusers $operation."changes needed (Add to)" $operation."sc2 Rehab AD groups (remove from)" "HIMD"
        #         $actions += $userActions
        #    }
        #}
        #else
        #{
            #Process Row
            $userActions = MoveUsers $operation."IDA AD Group (remove from)" $operation."Changes needed (Add to)"
            $actions += $userActions
        #}
    }
    return $actions
}

Function MoveUsers
{
    param ($removeGroup, $addGroup)

    Logger -color "green" -string "Processing users in $removeGroup $addGroup"


    #Get all users in the remove group
    $users = Get-ADGroupMember -identity $removeGroup -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title | Select surname, givenname, title, SamAccountName

    $userActions = @()


    foreach($user in $users)
    {
        $fname = $user.givenname 
        $lname = $user.surname 
        $userName = $user.samAccountName
        $userAction = CreateActionObj $fname $lname $userName $addGroup $removeGroup

        #If addGroup supplied, add users
        if($addGroup.Trim().Length -gt 0)
        {
            Logger -color "green" -string "     Adding user $fname $lname - $userName to group $addGroup"
            Add-ADGroupMember -Identity $addGroup -Members $user.samAccountName
        }

        $removeUser = $true
        #Special Case 1:  If removeGroup = Citrix  IDA check each user to be removed, if user is a member
        #                 of group IDA_Read_Only then do not remove from Citrix IDA
        if($removeGroup.ToLower().Trim() -eq "citrix ida")
        {
            #Get user from AD to ensure the most current Member Of list
            $usr = Get-ADUser -Filter {(SamAccountName -eq $userName)}  -Properties memberof | Select memberof
            $ous = $usr.memberof.split(",",3)
            foreach($ou in $ous)
            {
                if($ou.ToLower() -like "*ida_read_only*")
                {
                    #Do not remove from group
                    Logger -color "green" -string "     Not Removing user $fname $lname - $userName from group $removeGroup as they are in IDA_Read_Only"
                    $removeUser = $false
                    $userAction.RemovedFrom = ""
                    break
                }
            }
        }
        
        $userActions += $userAction
        if($removeUser)
        {
            Logger -color "green" -string "     Removing user $fname $lname - $userName from group $removeGroup"
            Remove-ADGroupMember -Identity $removeGroup -Members $userName  -Confirm:$false
        }
    }
    return $userActions
}

Function CreateActionObj
{
     param ($fname, $lname, $userName, $addGroup, $removeGroup)

     $userObj = New-Object PSObject
     $fullName = $fname + " " + $lname
     $userObj | Add-Member -type NoteProperty -Name Name -Value $fullName
     $userObj | add-member -type NoteProperty -Name UserId -Value $userName
     $userObj | add-member -type NoteProperty -Name RemovedFrom -Value $removeGroup
     $userObj | add-member -type NoteProperty -Name AddedTo -Value $addGroup

     if($addGroup -like "*remove*")
     {
         $userObj.AddedTo = ""
     }

     return $userObj
}


# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $logFile = $outputPath + "IDA_LegacyArchiveADgroups.log"
    Add-Content -Path $logFile -value $string
}




# Script begins here:  Execute Function Main
Main