# This Script will:
# •	Identify all contract and student therapist and add the AD group Opt_Labor
# •	
# • 


Function Main
{
    $outputPath = "C:\ps\Output\"
    $inputFile = "C:\ps\Input\Opt_LaborContractorStudentGroups.csv"

    $userList = @()

    $jobTitleList = MakeJobTitleList $inputFile

    Foreach($job in $jobTitleList)
    {
        $userList += GetUsersByJobTitle  $job.JobTitle $job.Group
    }

    #Produce CSV file
    $outfile = $outputPath + "AddOpt_LaborToContractorsStudents_log.csv"
    $userList | export-csv -Path $outfile -NoTypeInformation

    #Update AD
    Add-ADGroupMember -Identity Opt_Labor -Members $userList.UserId
}

Function MakeJobTitleList
{
    param ($inputFile)

    $jobTitleList = Import-Csv $inputFile

    return $jobTitleList
}

Function GetUsersByJobTitle
{
    param ($jobTitle, $class)

    $allUsers = @()
    $wantedUsers = @()

    $allUsers = Get-ADUser -Filter "(enabled -eq 'True') -and (Title -like '*$jobTitle*')"  -Properties entityID, employeeid, wwWHomePage | Select Name, SamAccountName, employeeid, wwWHomePage

    if($class -eq "Contract")
    {
        #Check Web Page field contains "Contract"
        foreach($user in $allUsers)
        {
            if($user.wwWHomePage -ne $null)
            {
                if($user.wwWHomePage.ToLower() -like '*contract*')
                {
                    $userObj = CreateUserObj $jobTitle $user
                    $wantedUsers += $userObj
                }
            }
        }
    }
    else
    {
        foreach($user in $allUsers)
        {
            $userObj = CreateUserObj $jobTitle $user
            $wantedUsers += $userObj
        }
    }

    return $wantedUsers
}

Function CreateUserObj
{
     param ($jobtitle, $user)

     $userObj = New-Object PSObject
     $userObj | Add-Member -type NoteProperty -Name Name -Value $user.Name
     $userObj | add-member -type NoteProperty -Name UserId -Value $user.SamAccountName
     $userObj | add-member -type NoteProperty -Name EmployeeId -Value $user.employeeid
     $userObj | add-member -type NoteProperty -Name WebPage -Value $user.wwWHomePage
     $userObj | add-member -type NoteProperty -Name JobTitle -Value $jobtitle

     return $userObj
}


# Script begins here:  Execute Function Main
Main