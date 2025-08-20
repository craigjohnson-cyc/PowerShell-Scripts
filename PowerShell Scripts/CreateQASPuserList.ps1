# This Script will:
# •	Create a list of Facilities from AD to get the facility distinguised name
# •	for Each California facility ($facList) produce a list of users with certain job titles


Function Main
{
 
    $facList = 70, 174, 72, 172, 76, 126, 73, 146, 75, 135, 8008
    
    # Get list of LCCA facilities
    $facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityType=1000)" -Properties *
    $facilities += Get-ADOrganizationalUnit -LDAPFilter "(entityType=1040)" -Properties *

    $QASPaccess = @()
    foreach ($fac in $facilities)
    {
        if ($facList -contains $fac.entityID)
        {
            $QASPaccess += GetUsers($fac)
        }
    }

    $fileName = "c:\ps\output\QASPusers.csv"
    $QASPaccess | export-csv -Path $fileName -NoTypeInformation
}


Function GetUsers
{
    param ($fac)
    
    $qUsers = @()
    $users = Get-ADUser -SearchBase $fac.DistinguishedName -Property Info,DisplayName, title, description, mail, company, department -Filter "*" | Select Name, SamAccountName, title, Enabled, mail,Info, Description, surname, givenname, company, department
 
    foreach($user in $users)
    {
        $userName = $user.Name
        $userTitle = $user.title


#ASSISTANT EXECUTIVE DIRECTOR,
#SENIOR EXECUTIVE DIRECTOR,
#INTERIM EXECUTIVE DIRECTOR,
#INTERIM DIRECTOR OF NURSING,


        if($user.Enabled)
        {
            $userJobTitle = ""
            $userJobTitle = $user.title.ToLower()

            if ($userJobTitle -like '*executive director*')
            {
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $qUsers += $director
            }
            if ($userJobTitle -like '*director of nursing*')
            {
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $qUsers += $director
            }
            if ($userJobTitle -like '*administrator in training*')
            {
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $qUsers += $director
            }
            if ($userJobTitle -like '*mds coordinator*')
            {
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $qUsers += $director
            }
        }
    }

     return $qUsers

}

Function CreateUserObj
{
    param ($entityId, $facilityName, $userName, $userTitle, $userEmail, $firstName, $lastName, $samAccountName, $division, $region, $state)

    $userObj = New-Object PSObject
    $userObj | Add-Member -type NoteProperty -Name facilityId -Value $entityId
    $userObj | Add-Member -type NoteProperty -Name facilityName -Value $facilityName
    $userObj | Add-Member -type NoteProperty -Name userName -Value $samAccountName
    $userObj | Add-Member -type NoteProperty -Name userFirstName -Value $firstName
    $userObj | Add-Member -type NoteProperty -Name userLastName -Value $lastName
    $userObj | Add-Member -type NoteProperty -Name userTitle -Value $userTitle
    $userObj | Add-Member -type NoteProperty -Name userEmail -Value $userEmail
    $userObj | Add-Member -type NoteProperty -Name Division -Value $division
    $userObj | Add-Member -type NoteProperty -Name Region -Value $region
    $userObj | Add-Member -type NoteProperty -Name State -Value $state

    return $userObj

}

Main