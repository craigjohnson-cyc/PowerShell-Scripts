Import-Module "sqlps"
Function Main
{
    #TODO - Allow for the entering of multiple value for parameter 2 
    
    # Create empty array
    #-------------------
    $allUsers = @()

    # Get Input Parameter 1
    #---------------------
    $searchBy = Read-Host -Prompt "Enter the Type of query (JobTitle/Group): "
    
    # Word Parameter 2 prompt according to Parameter 1 value
    #-------------------------------------------------------
    Switch -Wildcard ($searchBy)
    {
        "Job*Title"
        {
            $searchString = Read-Host -Prompt "Enter Job Title: "
        }
        "*Group"
        {
            $searchString = Read-Host -Prompt "Enter AD Group name: "
        }
        default
        {
            Write-Host "Invalid Type of query entered."
            return
        }
    }

    # Process by AD Group or by Job Title (Parameter 2 value)
    #--------------------------------------------------------
    Switch -Wildcard ($searchBy)
    {
        "Job*Title"
        {
            $allUsers = GetUsersByJobTitle $searchString
        }
        "*Group"
        {
            $allUsers = GetUsersByGroup $searchString
        }
        default
        {
            Write-Host "Invalid Type of query entered."
            return
        }
    }

    #Write output file
    #-----------------
    set-location "C:\"

    #TODO - ??  Do we need to include Domain in the file name ????

    #Check for existance of local work folder (Create if needed)
    #if( -not(Test-Path 'C:\PS\Output'))
    #{
    #    if( -not(Test-Path 'C:\PS'))
    #    {
    #        md -Path 'C:\PS'
    #    }
    #    md -Path 'C:\PS\Output'
    #}

    #$outputPath = "C:\ps\output\"
    $outputPath = "\\pes1\esss\Powershell scripts\Output\"
    set-location $outputPath
    $d = Get-Date -Format "MMddyyyy_HH_mm"
    $outputFile = $outputPath + "Users by " + $searchBy.Trim() + " - " + $searchString.Trim() + "_" + $d + ".csv"
    $allUsers | export-csv $outputFile  -NoTypeInformation

    #Present Option to Open Excel and present CSV
    #--------------------------------------------
    $showFile = Read-Host -Prompt "Display Results in Excel? (Y/N) "
    if($showFile.ToLower() -eq "y")
    {
        Invoke-Item $outputFile
    }
    else
    {
        Write-Host "*** PROCESSING COMPLETE: the file ' $outputFile ' has been created."
    }
}

Function GetUsersByGroup
{
    param ($groupName)
    $updateUsers = @()

    #Get users by AD Group membership
    #--------------------------------
    $adQuery = "Get-ADGroupMember -identity '" + $groupName + "' -Recursive "
    #$UsersForGroup = Get-ADGroupMember -identity "Information Systems" -Recursive 
    $users = Invoke-Expression $adQuery

    foreach($user in $users)
    {
        #Only want enabled/active users!
        $tuser = GetUserInfo $user
        if($tuser.FirstName -eq "DISABLED ACCOUNT")
        {
            continue
        }
        $updateUsers += $tuser
    }
    return $updateUsers
}

Function GetUserInfo
{
    param ($userobj)

    $facName = ""
    $facId = ""
    $adQuery = "Get-ADUser -Identity " + $user.SamAccountName + " -Property initials, description, office, mail, Company, department,  title, employeeid, displayname, PhysicalDeliveryOfficeName | Select givenname, surname, initials, description, office, mail, Company, department, title, employeeid, displayname, samaccountname, enabled"
    $user = Invoke-Expression $adQuery

    if($user.enabled -eq "True")
    {
        if(![string]::IsNullOrWhiteSpace($user.office))
        {
            $facInfo = GetFacInfo $user.office
            $facName = $facInfo.LongName
            $facId = $facInfo.LocationId
        }
    
    
        $updateUserObj += CreateUserObject $user $facName $facId
    }
    else
    {
        #return something that can be tested in calling proc
        $user.givenName = "DISABLED ACCOUNT"
        $updateUserObj += CreateUserObject $user $facName $facId
    }
    

    
    return $updateUserObj
}


Function GetUsersByJobTitle
{
    param ($jobTitle)

    #Get users by Job Title
    #----------------------
    #$users = Get-ADUser -Filter {((title -like '*Social Services*') -or (title -like '*Care Manager*'))} -Property initials, description, office, mail, Company, department,  title, employeeid, displayname, PhysicalDeliveryOfficeName | Select givenname, surname, initials, description, office, mail, Company, department, title, employeeid, displayname, samaccountname
    $adQuery = "-Property initials, description, office, mail, Company, department,  title, employeeid, displayname, PhysicalDeliveryOfficeName | Select givenname, surname, initials, description, office, mail, Company, department, title, employeeid, displayname, samaccountname, enabled"
    
    $filterClause = "Get-ADUser -Filter "
    #$filterClause += "{((title -like '*Social Services*') -or (title -like '*Care Manager*'))}"
    $filterClause += "{(title -like '*" + $jobTitle + "*')}"

    $getUserStmt = $filterClause + $adQuery
    $users = Invoke-Expression $getUserStmt

       
    $updateUsers = @()
    foreach($user in $users)
    {
        $facName = ""
        $facId = ""

        #Only want active/enabled users
        if($user.enabled -eq "True")
        {
            if(![string]::IsNullOrWhiteSpace($user.office))
            {
                $facInfo = GetFacInfo $user.office
                $facName = $facInfo.LongName
                $facId = $facInfo.LocationId
            }

            # create new object
            $updateUsers += CreateUserObject $user $facName $facId
        }

    }
    return $updateUsers
}

Function GetFacInfo
{
    param ($office)

    switch -Wildcard ($env:USERDNSDOMAIN)
    {
        "LCDEV*"
        {
            $ServerInstance = "Qarcpsdb1x\"  #dev
            $Database = "Mirth_Repository_Dev"  #Dev
        }
        "LCCA*"
        {
            $ServerInstance = "psdb1xv\"  #Prod
            $Database = "Mirth_Repository"  #Prod
        }
    }

    # query the OrganizationalHierarchy table in the Mirth_Repository for the FacID
    $query = "SELECT LongName, LocationId FROM [dbo].[OrganizationHierarchy] where longName like '%" + $office + "%'"

    $facInfo = Invoke-SqlCmd -Query $query -ServerInstance "$ServerInstance" -Database "$Database"

    return $facInfo
 }


Function CreateUserObject
{
    param ($user, $facName, $facId)

    $userObj = New-Object PSObject
    #givenname, surname, initials, description, office, mail, Company, department, title, employeeid, displayname, samaccountname"
    $userObj | Add-Member -type NoteProperty -Name First_Name -Value $user.givenName
    $userObj | add-member -type NoteProperty -Name Last_Name -Value $user.surName
    $userObj | add-member -type NoteProperty -Name Middle_Initial -Value $user.initials
    $userObj | add-member -type NoteProperty -Name Description -Value $user.description
    $userObj | Add-Member -type NoteProperty -Name Department-Facility -Value $user.office
    $userObj | add-member -type NoteProperty -Name Email_Address -Value $user.mail
    $userObj | add-member -type NoteProperty -Name Division -Value $user.Company
    $userObj | add-member -type NoteProperty -Name Region -Value $user.department
    $userObj | add-member -type NoteProperty -Name Facility_Name -Value $facName
    $userObj | add-member -type NoteProperty -Name Facility_Number -Value $facId
    $userObj | add-member -type NoteProperty -Name Job_Title -Value $user.title
    $userObj | Add-Member -type NoteProperty -Name Employee_Id -Value $user.employeeid
    $userObj | add-member -type NoteProperty -Name Display_Name -Value $user.displayname
    $userObj | add-member -type NoteProperty -Name Account_Name -Value $user.samaccountname

    return $userObj
}

# Script Begins Here - Execute Function Main
Main