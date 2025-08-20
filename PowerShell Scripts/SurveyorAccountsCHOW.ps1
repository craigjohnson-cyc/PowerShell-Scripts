param (
       [Parameter(Mandatory=$true)][String] $role,
       [Parameter(Mandatory=$true)][Int32] $newFac,
       [Parameter(Mandatory=$true)][Int32] $oldFac
       )
# Valid values for $role parameter:  'State Surveyor' OR 'CP - State Surveyor'


# This Script will:
# •	If value of parameter "role" contains "cp" then only call the SP to create PCC accounts
# •	Access database to get starting number for accounts ($startNumber)
# •	Disable all State Surveyor AD accounts for the old facility number
# •	Create new State Surveyor AD accounts for the new facility number

Function Main
{
    $outputPath = "C:\ps\output\"

# NOTE!!  Be sure SQL server names are correct for the environment!!!!!
#**********************************************************************
    # Dev SQL server values
    $mirthDB = "QARCPSDB1X"
    $mirthDBname = "Mirth_Repository_Dev"
    $upToolDB = "DDB7"

    # PROD SQL server values
    #$mirthDB = "PSDB1XV"
    #$mirthDBname = "Mirth_Repository"
    #$upToolDB = "DB7"
#**********************************************************************
    if($newFac -eq $oldFac)
    {
        #TODO:  This does exit the program if the Old Fac and New Fac are equal
        #       However, some sort of error/log message needs to be produced.
        exit -9
    }

    if($role.ToLower() -like "*cp*")
    {
        # No Action Taken
    }
    else
    {
        #Get the number of Surveyor accounts needed from the Role table
        $sqlcommand = "SELECT NumberOfGenericAccounts FROM [dbo].[Role] where RoleName = 'State Surveyor'"
        $nbr = Invoke-SQL -dataSource $upToolDB -database "UPTool" -sqlCommand $sqlcommand
        $numberNeeded = $nbr.NumberOfGenericAccounts

        # If no old FAC id provided (value will be 0) there are no surveyors to disable. 
        #   This would be a New facility, not a CHOW
        if($oldFac -gt 0)
        {
            DisableSurveyorsAtOldFac $newFac $oldFac $outputPath $numberNeeded
        }
        CreateSurveyorsAtNewFac $newFac $oldFac $outputPath $upToolDB $numberNeeded
    
    }

    CreatePCCaccounts $oldFac $newFac $role $mirthDB $mirthDBname $upToolDB

}

Function CreatePCCaccounts
{
    param ($oldFac, $newFac, $role, $mirthDB, $mirthDBname, $upToolDB)

    $appName = "PCC"

    $sqlcommand = "EXEC ChowNonADUsers '$($newFac)', '$($oldFac)', '$($role)', '$($appName)'"
    $activeFacs = Invoke-SQL -dataSource $upToolDB -database "UPTool" -sqlCommand $sqlcommand

}

Function DisableSurveyorsAtOldFac
{
    param ($newFac, $oldFac, $outputPath, $numberNeeded)

    #$facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityId=$oldFac)" -Properties *

    $paddedFac = $oldFac.ToString().PadLeft(4,'0')

    $disabledUsers = @()
    for($kounter=0;$kounter -lt $numberNeeded; $kounter++)
    {
        $paddedKount = ($kounter+1).ToString().PadLeft(2,'0')
        #$userDistinguishedName = 'CN=State Surveyor_' + $paddedFac + '_' + $paddedKount + ',' + $facilities.DistinguishedName
        $userSamAccountName = 'SVY_' + $paddedFac + '_' + $paddedKount

        #Disable-ADAccount -Identity $userDistinguishedName
        Disable-ADAccount -Identity $userSamAccountName
        $userObj = CreateDisabledUserObject $userSamAccountName
        $disabledUsers += $userObj
    }

        #Write Log File
    $fileName = $outputPath + "StateSurveyorAccountsDisabledCHOW_" +  $newFac.ToString().PadLeft(4,"0") + "to"+ $oldFac.ToString().PadLeft(4,"0") +".csv"
    $disabledUsers | export-csv -Path $fileName -NoTypeInformation

}

Function CreateSurveyorsAtNewFac
{
    param ($NewFac, $oldFac, $outputPath, $upToolDB, $numberNeeded )

    $userList = @()
    $activeFacs = @()
    $activeFacs += $NewFac

    $facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityId=$newFac)" -Properties *

    $userList = ProcessFacilities $facilities "LCCA" $activeFacs $numberNeeded

    foreach($newUser in $userList)
    {
        CreateADaccounts $newUser
    }

    #Write Log File
    $fileName = $outputPath + "StateSurveyorAccountsCreatedCHOW_" +  $newFac.ToString().PadLeft(4,"0") + "to"+ $oldFac.ToString().PadLeft(4,"0") +".csv"
    $userList | export-csv -Path $fileName -NoTypeInformation
}


function CreateADaccounts
{
    param ($user)

    $pw = GeneratePassword 3 3 3 
    #$dn = $dispName + "," + $user.parentDistingushedName
    $dn = $user.parentDistingushedName

    $desc = "State Surveyor"
    if($user.firstName.ToUpper().Substring(0,2) -eq "CP") {$desc = "CP " + $desc}

    $ray = $user.parentDistingushedName -split ","
    #Since the Distingushed Name is from a facility level we know the resulting array will be:
    # [0] - Facility
    # [1] - Region
    # [2] - Division
    # [3] & [4] DC values
    $dept = $ray[1].Substring(3).Trim()  #AD Department field holds Region name
    $company = $ray[2].Substring(3).Trim()  #AD Company field holds Division name

    #Get the domain name
    $sysInfo = Get-ADDomain
    $domain = ""

    if($sysInfo.DNSRoot.ToLower() -like '*lcdev*')
    {
        $domain = "@lcdev.net"
    }
    else
    {
        $domain = "@lcca.com"
    }
    $principleName = $user.samAccountName + $domain
    

    $user.description = $desc
    $user.department = $dept
    $user.company = $company
    $user.principleName = $principleName
    $user.path = $dn
    $expireDate = Get-Date

    # the statement below creates new AD accounts that are enabled 
    #New-ADUser -Name $user.displayName -DisplayName $user.displayName -GivenName $user.firstName -Surname $user.lastName -SamAccountName $user.samAccountName -UserPrincipalName $principleName -AccountPassword (ConvertTo-SecureString $pw -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true -office $user.office -Path $dn -Description $desc -Title $desc -Department $dept -Company $company

    # 9/18/2019 - Requirement Change:  Surveyor accounts are now to be created Expired.
    New-ADUser -Name $user.displayName -DisplayName $user.displayName -GivenName $user.firstName -Surname $user.lastName -SamAccountName $user.samAccountName -UserPrincipalName $principleName -AccountPassword (ConvertTo-SecureString $pw -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true -office $user.office -Path $dn -Description $desc -Title $desc -Department $dept -Company $company -AccountExpirationDate $expireDate
    Add-ADGroupMember -Identity PCC_Deny -Members $user.samAccountName
}

function GeneratePassword()
{
    param ($upper, $lower, $number)
    $forceUpper = $true
    $forceLower = $true
    $forceNumber = $true

    $result = ""
    if ($forceUpper) {$result += GenerateUpper $upper}
    if ($forceLower) {$result += GenerateLower $lower}
    if ($forceNumber) {$result += GenerateNumbers $number}
    
    return $result;
}

function GenerateLower
{
    param ($lower)

    $letters = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    $list = $letters | Get-Random -Count $lower

    $result = ""
    foreach($letter in $list) {$result += $letter.Trim()}

    return $result
}

function GenerateUpper
{
    param ($upper)

    $letters = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    $list = $letters | Get-Random -Count $upper

    $result = ""
    foreach($letter in $list) {$result += $letter.Trim()}

    return $result
}

function GenerateNumbers
{
    param ($numberLimit)
    
    $numbers = '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    $list = $numbers | Get-Random -Count $numberLimit

    $result = ""
    foreach ($number in $list) {$result += $number.Trim()}

    return $result
}


function ProcessFacilities
{
    param ($facilities, $company, $activeFacs, $numberNeeded)

    $facList = @()
    foreach($fac in $facilities)
    {
        #Determine if facility is in the Active Facility list
        #Skip if not in list
        if($activeFacs -contains $fac.entityID)
        {
            $facObj = CreateFacilitiyObject $fac.Description $fac.entityId $fac.Name $fac.StreetAddress $fac.telephoneNumber $fac.PostalCode $fac.City $fac.DistinguishedName
            $facList += $facObj
        }
    }

    foreach($fac in $facList)
    {
        $facId = $fac.entityID.ToString().Trim()
        $facIdLen = $facid.Length
        switch ($facIdLen)
        {
            1
                {
                    $facId = "000" + $facId
                }
            2
                {
                    $facId = "00" + $facId
                }
            3
                {
                    $facId = "0" + $facId
                }
        }

        $userName = "SVY_" + $facId + "_"
        $userList += CreateSurveyorsForFacility $fac $userName $fac.Name $fac.ADdistinguishedName $company $facId $numberNeeded
    }
    
    return $userList
}


function CreateFacilitiyObject()
{
    param ($description, $entityId, $name, $AdAddress, $AdPhoneNunmber, $zipCode, $city, $dn)
    
    $perObj = New-Object PSObject
    $perObj | add-member -type NoteProperty -Name EntityId -Value $entityId
    $perObj | Add-Member -type NoteProperty -Name Description -Value $description
    $perObj | add-member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name ADaddress -Value $AdAddress
    $perObj | add-member -type NoteProperty -Name ADcity -Value $city
    $perObj | add-member -type NoteProperty -Name ADzipCode -Value $zipCode
    $perObj | add-member -type NoteProperty -Name ADphoneNumber -Value $AdPhoneNunmber
    $perObj | add-member -type NoteProperty -Name ADdistinguishedName -Value $dn

    return $perObj
}

function CreateDisabledUserObject()
{
    param ($samAccountName)
    
    $perObj = New-Object PSObject
    $perObj | add-member -type NoteProperty -Name AccountName -Value $samAccountName
    $perObj | Add-Member -type NoteProperty -Name Action -Value "Account Disabled"

    return $perObj
}


function CreateSurveyorsForFacility()
{
    param ($fac, $userNameBase, $facilityName, $dn, $company, $facId, $numberNeeded)

    $users = @()
    for($kounter=0;$kounter -lt $numberNeeded; $kounter++)
    {
        $surveyorNumber = ($kounter+1).ToString().Trim()
        $surveyorNumberLen = $surveyorNumber.Length
        switch ($surveyorNumberLen)
        {
            1
                {
                    $surveyorNumber = "0" + $surveyorNumber
                }
        }
        $userName = $userNameBase + $surveyorNumber
        $newUser = CreateUserAccountObj $userName $facilityName $dn $company $facId
        $users += $newUser
    }

    return $users
}


function CreateUserAccountObj()
{
    param ($userName, $facilityName, $dn, $company, $facId)
    
    $userObj = New-Object PSObject
    
    $fName = "State"
    $surveyorNumber = $userName.Substring($userName.Length-2,2)
    $lName = "Surveyor_" + $facId + "_" + $surveyorNumber 

    if($company -eq "CP") 
    {
        $fName = "CP " + $fName
    }
    $dispName = $fname + " " + $lName
    

    $userObj | Add-Member -type NoteProperty -Name firstName -Value $fName
    $userObj | Add-Member -type NoteProperty -Name lastName -Value $lName
    $userObj | Add-Member -type NoteProperty -Name displayName -Value $dispName
    $userObj | Add-Member -type NoteProperty -Name office -Value $facilityName
    $userObj | Add-Member -type NoteProperty -Name samAccountName -Value $userName
    $userObj | Add-Member -type NoteProperty -Name parentDistingushedName -Value $dn

    $userObj | Add-Member -type NoteProperty -Name description -Value ""
    $userObj | Add-Member -type NoteProperty -Name department -Value ""
    $userObj | Add-Member -type NoteProperty -Name company -Value ""
    $userObj | Add-Member -type NoteProperty -Name principleName -Value ""
    $userObj | Add-Member -type NoteProperty -Name path -Value ""
    
    return $userObj
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

# Script Begins Here - Execute Function Main
Main