function CreatePersonObject()
{
    param ($firstName, $lastName, $jobTitle, $facId, $facName)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name FirstName -Value $firstName
    $perObj | add-member -type NoteProperty -Name LastName -Value $lastName
    $perObj | add-member -type NoteProperty -Name JobTitle -Value $jobTitle
    $perObj | add-member -type NoteProperty -Name FacilityId -Value $facId
    $perObj | Add-Member -type NoteProperty -Name Facility -Value $facName

    return $perObj
}

function GetEntityId()
{
    param($FacilityName)

    [int]$EntityId = Get-ADOrganizationalUnit -Filter 'Name -eq $FacilityName' -Properties entityId | select  -expandProperty entityId

    return $EntityId
    
}


function IsPhysicianFacility()
{
    param($EntityId, $PhysicianFacArray)
    $returnValue = $PhysicianFacArray.Contains($EntityId)

    return $returnValue

}


#----------------
# START OF SCRIPT
#----------------
$HIMDusers = @()
# Create an array of physician facility Id's
#$PhysicianFacArray = 6,200,158,220,629,137,446,445,168,77,100,7,252,47,12,590,231,184,18,636,18,436,264,209,218,11,642,287,214,188,42,575,56,19,309,344,648,437,650,583,331,591,48,257,416
$PhysicianFacArray = 628,632

# Get list of members of the HIMD group
$HIMDlist = Get-ADGroupMember -identity "HIMD" -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title | Select employeeid, surname, givenname, title, SamAccountName, DistinguishedName | select *,@{l='Parent';e={(New-Object 'System.DirectoryServices.directoryEntry' "LDAP://$($_.DistinguishedName)").Parent}}

foreach($person in $HIMDlist)
{

    # Determin the person's facility name
    $test = $person.parent
    $test = $test.replace("LDAP://", "")
    $test = $test.Substring(0,$test.indexOf(",DC"))
    $test = $test.Replace("OU=","")
    $ous = $test.split(",",3)
    $FacilityName = $ous[0]

    # Get the Facility ID/Entity Id for the person's facility
    $EntityId = GetEntityId $FacilityName

    # Determine if the person's facility is in the physician's facility array
    $recFound = IsPhysicianFacility $EntityId $PhysicianFacArray

    # If the person's facility is in the physician's facility array add to array of people we want
    if($recFound)
    {
        # First name, Last name, Job title, Facility ID
        $personObj = CreatePersonObject $person.givenname $person.surname $person.title $EntityId $FacilityName
        $HIMDusers += $personObj
    }

}

# Create CSV file of the people we want
#$HIMDusers | export-csv -Path "C:\ps\HIMDusers.csv"
$HIMDusers | export-csv -Path "C:\ps\HIMDusersKennewickRichland.csv"
