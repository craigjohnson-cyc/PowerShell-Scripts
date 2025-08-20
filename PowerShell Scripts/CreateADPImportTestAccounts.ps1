function main
{
    $fac1 = Get-ADOrganizationalUnit -Filter 'Name -eq "Cleveland"' -Properties *
    $fac2 = Get-ADOrganizationalUnit -Filter 'Name -eq "Chattanooga"' -Properties *
    $company = "LCCA"

    $userName1 = "yhb0001"
    $userName2 = "yb0021"
    $userName3 = "SV0037"

    $userList = @()
    #$userList += CreateSurveyorsForFacility $fac2 $userName2 $fac2.Name $fac2.distinguishedName $company $fac2.entityID
    #$userList += CreateSurveyorsForFacility $fac1 $userName1 $fac1.Name $fac1.distinguishedName $company $fac1.entityID
    $userList += CreateSurveyorsForFacility $fac1 $userName3 $fac1.Name $fac1.distinguishedName $company $fac1.entityID

    foreach($newUser in $userList)
    {
        CreateADaccounts $newUser
    }

}

function CreateSurveyorsForFacility()
{
    param ($fac, $userName, $facilityName, $dn, $company, $facId)

    $users = @()
    $newUser = CreateUserAccountObj $userName $facilityName $dn $company $facId
    $users += $newUser

    return $users
}

function CreateUserAccountObj()
{
    param ($userName, $facilityName, $dn, $company, $facId)
    
    $userObj = New-Object PSObject
    
#    $fName = "Yogi"
#    $lName = "Bear"
#    $midInit = "H."

    $fName = "Sharon"
    $lName = "Vanormer"
    $midInit = ""

    #$dispName = $fname + " " + $midInit +" " + $lName
    $dispName = $fname + " "  + $lName
    

    $userObj | Add-Member -type NoteProperty -Name firstName -Value $fName
    $userObj | Add-Member -type NoteProperty -Name lastName -Value $lName
    $userObj | Add-Member -type NoteProperty -Name initial -Value $midInit
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

function CreateADaccounts
{
    param ($user)

    $pw = GeneratePassword 3 3 3 
    #$dn = $dispName + "," + $user.parentDistingushedName
    $dn = $user.parentDistingushedName

    $desc = "Contract Nursing Aide"

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

    New-ADUser -Name $user.displayName -DisplayName $user.displayName -GivenName $user.firstName -Surname $user.lastName -SamAccountName $user.samAccountName -UserPrincipalName $principleName -AccountPassword (ConvertTo-SecureString $pw -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true -office $user.office -Path $dn -Description $desc -Title $desc -Department $dept -Company $company 
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



# Script Begins Here - Execute Function Main


Main