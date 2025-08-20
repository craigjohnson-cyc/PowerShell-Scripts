Function Main
{
# This Script will:
# •	Produce a listing of State Surveyors, listing the user's name and facility

$u = Get-ADUser -Filter {(surname -like '*')  } -Properties entityID, mail, employeeid,  title, office, company, department | Select Name, UserPrincipalName, SamAccountName, Enabled, mail, employeeid, surname, givenname, title, office, company, department
$userList = @()
foreach($user in $u)
    {
         if ($user.Title -like '*Surveyor*')
         {
            # determine if account is active
            if ($user.Enabled)
            {
                # Create person object
                $obj = CreatePersonObject $user.SamAccountName $user.Name $user.title $user.department $user.company $user.office
                $userList += $obj
            }

         }
    }

    #Production Value:
    #$filePath = "\\fs3\edrive\User Provisioning\Missing Employee IDs\"
    #------------------------------------------------------------------
    
    #Test Value:
    #$filePath = "\\dfs3\edrive\User Provisioning\Missing Employee IDs\"
    $filePath = "c:\ps\output\"
    #--------------------------

    $fileName = $filePath + "ActiveStateSurveyors-" + (Get-Date).ToString("MM-dd-yyyy") + ".csv"
    $userList | export-csv -Path $fileName -NoTypeInformation
}


function CreatePersonObject()
{
    param ($SamAccountName, $name, $title, $department, $company, $office)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name Title -Value $title
    $perObj | add-member -type NoteProperty -Name Department -Value $department
    $perObj | add-member -type NoteProperty -Name Company -Value $company
    $perObj | add-member -type NoteProperty -Name Office -Value $office

    return $perObj
}



# Script Begins Here - Execute Function Main


Main