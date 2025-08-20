Function Main
{
# This Script will:
# •	Create a list of Facilities from AD 
# •	For each facility, create 15 State Surveyor AD accounts

    # Get list of LCCA facilities
    $facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityType=1000)" -Properties *

    # Get list of Century Park facilities
    $facilities += Get-ADOrganizationalUnit -LDAPFilter "(entityType=1040)" -Properties *

    $facList = @()
    foreach($fac in $facilities)
    {
        $facObj = CreateFacilitiyObject $fac.Description $fac.entityId $fac.Name $fac.StreetAddress $fac.telephoneNumber $fac.PostalCode $fac.City
        $facList += $facObj
    }

    $userList = @()
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
        $userList += CreateSurveyorsForFacility $fac $userName $fac.Name
    }

    foreach($newUser in $userList)
    {
        CreateADaccounts $newUser
    }

    #Write Log File
    $fileName = "c:\ps\output\StateSurveyorAccounts.csv"
    $userList | export-csv -Path $fileName -NoTypeInformation
}

function CreateADaccounts
{
    param ($user)

    $pw = GeneratePassword 3 3 3

    #New-ADUser -Name $user.displayName -GivenName $user.firstName -Surname $user.lastName -SamAccountName $user.samAccountName -UserPrincipalName "J.Robinson@enterprise.com" -Path "OU=Managers,DC=enterprise,DC=com" -AccountPassword(Read-Host -AsSecureString "Input Password") -Enabled $true
    New-ADUser -Name $user.displayName -GivenName $user.firstName -Surname $user.lastName -SamAccountName $user.samAccountName -AccountPassword (ConvertTo-SecureString $pw -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true
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

function CreateSurveyorsForFacility()
{
    param ($fac, $userNameBase, $facilityName)

    $users = @()
    for($kounter=0;$kounter -lt 15; $kounter++)
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
        $newUser = CreateUserAccountObj $userName $facilityName
        $users += $newUser
    }

    return $users
}

function CreateUserAccountObj()
{
    param ($userName, $facilityName)
    
    $userObj = New-Object PSObject

    $userObj | Add-Member -type NoteProperty -Name firstName -Value "State"
    $userObj | Add-Member -type NoteProperty -Name lastName -Value "Surveyor"
    $userObj | Add-Member -type NoteProperty -Name displayName -Value "State Surveyor"
    $userObj | Add-Member -type NoteProperty -Name office -Value $facilityName
    $userObj | Add-Member -type NoteProperty -Name samAccountName -Value $userName

    $userObj | Add-Member -type NoteProperty -Name password -Value ""

    return $userObj
}

function CreateFacilitiyObject()
{
    param ($description, $entityId, $name, $AdAddress, $AdPhoneNunmber, $zipCode, $city)
    
    $perObj = New-Object PSObject
    $perObj | add-member -type NoteProperty -Name EntityId -Value $entityId
    $perObj | Add-Member -type NoteProperty -Name Description -Value $description
    $perObj | add-member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name ADaddress -Value $AdAddress
    $perObj | add-member -type NoteProperty -Name ADcity -Value $city
    $perObj | add-member -type NoteProperty -Name ADzipCode -Value $zipCode
    $perObj | add-member -type NoteProperty -Name ADphoneNumber -Value $AdPhoneNunmber

    return $perObj
}


# Script Begins Here - Execute Function Main


Main