Function Main
{
# This Script will:
# •	Create a list of Facilities from AD 
# •	For each facility, create 15 State Surveyor AD accounts


    # Get list of active facilities from FIN2
    $sqlcommand = "EXEC GetFacForPS"
    $activeFacs = Invoke-SQL -dataSource "QARCPSDB1X" -database "Mirth_Repository_Dev" -sqlCommand $sqlcommand

    $userList = @()
    # Get list of LCCA facilities
    $facilities = Get-ADOrganizationalUnit -LDAPFilter "(entityType=1000)" -Properties *

    $memberList = ProcessFacilities $facilities "LCCA" $activeFacs

}

function ProcessFacilities
{
    param ($facilities, $company, $activeFacs)

    $facList = @()
    foreach($fac in $facilities)
    {
        #Determine if facility is in the Active Facility list
        #Skip if not in list
        if($activeFacs.finId -contains $fac.entityID)
        {
            $facObj = CreateFacilitiyObject $fac.Description $fac.entityId $fac.Name $fac.StreetAddress $fac.telephoneNumber $fac.PostalCode $fac.City $fac.DistinguishedName
            $facList += $facObj
        }
    }

    foreach($fac in $facList)
    {
    
        Add-ADGroupMember -Identity PCC_Implementation -Members $fac.Name


    }
    
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

function Invoke-SQL {
    param(
        [string] $dataSource = $(throw "Please specify a server"),
        [string] $database = $(throw "Please specify a database"),
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