# This Script will:
# •	Create a list of Facilities from AD 
# •	For each facility, getExecutive Directors and DON's


Function Main
{
    # Get list of active facilities from FIN2
    $sqlcommand = "SELECT [LocationId] AS FinId
      ,[Entity] AS FacilityName
  FROM [dbo].[OrganizationHierarchy]
  WHERE Entity NOT LIKE '%(old)%' AND Level = 4 AND LocationId <> '503'
  ORDER BY LocationId "
    $activeFacs = Invoke-SQL -dataSource "PSDB1XV" -database "Mirth_Repository" -sqlCommand $sqlcommand


    # Get list of LCCA facilities
    $facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityType=1000)" -Properties *
    $facilities += Get-ADOrganizationalUnit -LDAPFilter "(entityType=1040)" -Properties *

    $users = @()
    foreach($fac in $facilities)
    {
        if($activeFacs.finId -contains $fac.entityID)
        {
            $users += GetDirectors($fac)
        }
    }

    $fileName = "c:\ps\output\ED_DOR_by_Facility.csv"
    $users | export-csv -Path $fileName -NoTypeInformation

}

# Script Begins Here - Execute Function Main

Function GetDirectors
{
    param ($fac)
    
    $directorFoundForFac = $false
    $directors = @()
    $facName = $fac.Name
    Logger -color "green" -string "processing facility: $facName"
    #$users = Get-ADGroupMember -identity $fac.Name -Recursive | Get-ADUser -Property Info,DisplayName, title, description,mail | Select Name, SamAccountName, title, Enabled, mail,Info, Description, surname, givenname
    $users = Get-ADUser -SearchBase $fac.DistinguishedName -Property Info,DisplayName, title, description, mail, company, department -Filter "*" | Select Name, SamAccountName, title, Enabled, mail,Info, Description, surname, givenname, company, department

    foreach($user in $users)
    {
        $userName = $user.Name
        $userTitle = $user.title
        if($user.Enabled)
        {
            if ($user.title -like '*Executive Director*')
            {
                $directorFoundForFac = $true
                Logger -color "green" -string "Executive Director found: $userName - $userTitle"
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $directors += $director
            }
            if ($user.title -like '*Director of Nursing*')
            {
                $directorFoundForFac = $true
                Logger -color "green" -string "Director of Nursing found: $userName - $userTitle"
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $directors += $director
            }
            if ($user.title -like '*DON*')
            {
                $directorFoundForFac = $true
                Logger -color "green" -string "Director of Nursing found: $userName - $userTitle"
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $directors += $director
            }
            if ($user.title -like '*Development Coordinator*')
            {
                $directorFoundForFac = $true
                Logger -color "green" -string "Development Coordinator found: $userName - $userTitle"
                $director = CreateUserObj $fac.entityId $fac.Name $user.Name $user.title $user.mail $user.givenname $user.surname $user.samAccountName $user.company $user.department $fac.st
                $directors += $director
            }
        }
    }

    if (!$directorFoundForFac)
    {
        Logger -color "green" -string "No Executive Director or Director of Nursing found!"
        $director = CreateUserObj $fac.entityId $fac.Name "" "" "" "" "" "" "" "" ""
        $directors += $director
    }

    return $directors
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

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    Add-Content -Path C:\temp\ListDirectorsByFacility.txt -value $string
}

Function Invoke-SQL {
    param(
        [string] $dataSource = $(throw "Please specify a server"),
        [string] $database = $(throw "Please secify a database"),
        [string] $sqlCommand = $(throw "Please specify a query.")
    )
    $connectionString = "Data Source=$dataSource; Integrated Security=SSPI; Initial Catalog=$database"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $connection)
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $connection.Close()
    $dataSet.Tables
}   

Main