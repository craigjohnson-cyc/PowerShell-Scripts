Function Main
{
# This Script will:
# •	Create a list of Division Vice Presidents, Regional Vice Presidents and Executive Directors
# •	For each user, remove from Opt_Facility_ReadOnly
# •	Add user to either Opt_DVP, Opt_RVP or Opt_ED based on their title

# Get list of users
$RVPs = Get-ADUser -Filter {(title -like '*Regional Vice President*') }  -Properties EmployeeId, WhenCreated, memberof, title| Select Employeeid, Name, SamAccountName, title, Enabled, mail,Info,WhenCreated, memberof
$DVPs = Get-ADUser -Filter {(title -like '*Division Vice President*') }  -Properties EmployeeId, WhenCreated, memberof, title| Select Employeeid, Name, SamAccountName, title, Enabled, mail,Info,WhenCreated, memberof
$Eds = Get-ADUser -Filter {(title -like '*Executive Director*') }  -Properties EmployeeId, WhenCreated, memberof, title| Select Employeeid, Name, SamAccountName, title, Enabled, mail,Info,WhenCreated, memberof


$groupMembers = @()
$groupMembers = ProcessRVPs $RVPs
$groupMembers += ProcessDVPs $DVPs
$groupMembers += ProcessEds $Eds

# Write output file

#Production Value:
$filePath = "\\fs3\edrive\User Provisioning\Missing Employee IDs\"
#------------------------------------------------------------------
    
#Test Value:
#$filePath = "\\dfs3\edrive\User Provisioning\Missing Employee IDs\"
#$filePath = "c:\ps\output\"
#--------------------------

$fileName = $filePath + "Opt_ED_RVP_DVP_RoleChanges-" + (Get-Date).ToString("MM-dd-yyyy") + ".csv"
$groupMembers | export-csv -Path $fileName -NoTypeInformation

}

function CreatePersonObject()
{
    param ($SamAccountName, $name, $title)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name Title -Value $title
    $perObj | add-member -type NoteProperty -Name Action1 -Value ""
    $perObj | add-member -type NoteProperty -Name Action2 -Value ""
    $perObj | add-member -type NoteProperty -Name Action3 -Value ""

    return $perObj
}


function ProcessRVPs()
{
    param ($RVPs)

    $processedUsers = @()
    foreach($user in $RVPs)
    {
        $personObj = CreatePersonObject $user.SamAccountName $user.Name $user.title

        # 1) Determine if user is in a Readonly group, Remove if found
        $found = $false
        foreach($group in $user.MemberOf)
        {
            if ($group -like 'CN=Opt_Facility_ReadOnly*')
            {
                $found = $true
                break
            }
        }
        if ($found)
        {
            $personObj.Action1 = "Removing user from Opt_Facility_ReadOnly"
            Remove-ADGroupMember -Identity "Opt_Facility_ReadOnly" -Members $user.SamAccountName  -Confirm:$false
        }
        else
        {
            $personObj.Action1 = "User Not Found in Opt_Facility_ReadOnly"
        }
        
        
        # 2) Determine if user is in Opt_RVP, Add if not
        $found = $false
        foreach($group in $user.MemberOf)
        {
            if ($group -like 'CN=Opt_RVP*')
            {
                $found = $true
                break
            }
        }

        if ($found)
        {
            $personObj.Action2 = "User is already a member of Opt_RVP"
        }
        else
        {
            $personObj.Action2 = "Adding user to Opt_RVP"
            Add-ADGroupMember -Identity "Opt_RVP" -Members $user.SamAccountName -Confirm:$false
        }
        $processedUsers += $personObj 
    }
    return $processedUsers
}

function ProcessDVPs()
{
    param ($DVPs)

    $processedUsers = @()
    foreach($user in $DVPs)
    {
        $personObj = CreatePersonObject $user.SamAccountName $user.Name $user.title

        # 1) Determine if user is in a Readonly group, Remove if found
        $found = $false
        foreach($group in $user.MemberOf)
        {
            
            if ($group -like 'CN=Opt_Facility_ReadOnly*')
            {
                $found = $true
                break
            }
        }

        if ($found)
        {
            $personObj.Action1 = "Removing user from Opt_Facility_ReadOnly"
            Remove-ADGroupMember -Identity "Opt_Facility_ReadOnly" -Members $user.SamAccountName -Confirm:$false
        }
        else
        {
            $personObj.Action1 = "User Not Found in Opt_Facility_ReadOnly"
        }


        # 2) Determine if user is in Opt_DVP, Add if not
        $found = $false
        foreach($group in $user.MemberOf)
        {
            if ($group -like 'CN=Opt_DVP*')
            {
                $found = $true
                break
            }
        }
        
        if ($found)
        {
            $personObj.Action2 = "User is already a member of Opt_DVP"
        }
        else
        {
            $personObj.Action2 = "Adding user to Opt_DVP"
            Add-ADGroupMember -Identity "Opt_DVP" -Members $user.SamAccountName -Confirm:$false
        }

        $processedUsers += $personObj 
    }
    return $processedUsers
}

function ProcessEds()
{
    param ($EDs)

    $processedUsers = @()
    foreach($user in $EDs)
    {
        $personObj = CreatePersonObject $user.SamAccountName $user.Name $user.title
        # 1) Determine if user is in a Readonly group, Remove if found
        $found = $false

        foreach($group in $user.MemberOf)
        {

            if ($group -like 'CN=Opt_Facility_ReadOnly*')
            {
                $found = $true
                break
            }
        }

        if ($found)
        {
            $personObj.Action1 = "Removing user from Opt_Facility_ReadOnly"
            Remove-ADGroupMember -Identity "Opt_Facility_ReadOnly" -Members $user.SamAccountName -Confirm:$false
        }
        else
        {
            $personObj.Action1 = "User Not Found in Opt_Facility_ReadOnly"
        }

        # 2) Determine if user is in Opt_ED, Add if not
        $found = $false
        foreach($group in $user.MemberOf)
        {

            if ($group -like 'CN=Opt_ED*')
            {
                $found = $true
                break
            }
        }

        if ($found)
        {
            $personObj.Action2 = "User is already a member of Opt_ED"
        }
        else
        {
            $personObj.Action2 = "Adding user to Opt_ED"
            Add-ADGroupMember -Identity "Opt_ED" -Members $user.SamAccountName -Confirm:$false
        }
        $processedUsers += $personObj 
    }
    return $processedUsers
}

# Script Begins Here - Execute Function Main


Main