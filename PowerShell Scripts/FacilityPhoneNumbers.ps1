Function Main
{
# This Script will:
# •	Create a list of Facilities from AD 
# •	For each compare phone numberagainst FIN 2 

    # Get list of facilities
    $facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityType=1000)" -Properties *
    $facList = @()
    foreach($fac in $facilities)
    {
        $facObj = CreateFacilitiyObject $fac.Description $fac.entityId $fac.Name $fac.StreetAddress $fac.telephoneNumber $fac.PostalCode $fac.City
        $facList += $facObj
    }

    $fileName = "c:\ps\output\FacilityPhoneNumbers.csv"
    $facList | export-csv -Path $fileName -NoTypeInformation
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