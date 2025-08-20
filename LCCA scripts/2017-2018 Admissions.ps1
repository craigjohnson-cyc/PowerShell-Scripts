#Import-Module sqlps

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

function CreateFacilityObject()
{
    param ($facId, $division, $name, $Admins2017, $Admins2018, $finId)
    
    $facilityObj = New-Object PSObject
    $facilityObj | Add-Member -type NoteProperty -Name FacilityID -Value $facId
    $facilityObj | Add-Member -type NoteProperty -Name FacilityIdentifier -Value $finId
    $facilityObj | Add-Member -type NoteProperty -Name Division -Value $division
    $facilityObj | add-member -type NoteProperty -Name FacilityName -Value $name
    $facilityObj | add-member -type NoteProperty -Name Admissions2017 -Value $Admins2017
    $facilityObj | add-member -type NoteProperty -Name Admissions2018 -Value $Admins2018

    return $facilityObj
}

function CreatePccFacObject()
{
    param ($facId, $goLiveDate)
    $pccObj = New-Object PSObject
    $pccObj | Add-Member -type NoteProperty -Name FacilityID -Value $facId
    $pccObj | Add-Member -type NoteProperty -Name GoLiveDate -Value $goLiveDate

    return $pccObj
}

function CreatePccFacCollection()
{
    $pccFacs = @()
    $p = CreatePccFacObject  222 '3/6/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  109 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  229 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  215 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  89 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  178 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  64 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  169 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  104 '6/5/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  202 '7/10/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  115 '7/10/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  8 '7/10/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  203 '7/10/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  56 '7/10/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  139 '7/10/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  180 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  117 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  4 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  96 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  196 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  156 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  73 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  195 '8/7/2018'
    $pccFacs += $p
    $p = CreatePccFacObject  72 '8/7/2018'
    $pccFacs += $p
    return $pccFacs
}


$facilityAdmissions = @()
$sqlcommand = "
	    SELECT DISTINCT FacilityId, Division, Region, Name, FacilityIdentifier, 0
        FROM   dbo.Facility Where IsActive = 1 and TestFacility = 0 "
$dbitems = Invoke-SQL -dataSource "MRSCRSD4V\AG" -database SofCareClin -sqlCommand $sqlcommand
	
foreach ($facility in $dbitems)
{
    $finId = $facility.FacilityIdentifier
    $facId = $facility.FacilityId
    $sqlcommand = "
        		Select	FacilityId,
				Sum(Case When DatePart(YEAR,AdmitDate) = '2017' Then 1 Else 0 End),
				Sum(Case When DatePart(YEAR,AdmitDate) = '2018' Then 1 Else 0 End)
		        From Admission
		        Where FacilityID = $facId and Status = 2 And ResidentType = 1
                Group By FacilityID"
    $facAdmissions = Invoke-SQL -dataSource "MRSCRSD4V\AG" -database SofCareClin -sqlCommand $sqlcommand

    $facObj = CreateFacilityObject $facId $facility.Division $facility.Name $facAdmissions.Column1 $facAdmissions.Column2 $finId
    $facilityAdmissions += $facObj
}


$pccFacilities = CreatePccFacCollection
foreach ($pccFac in $pccFacilities)
{
    $facId = $pccFac.FacilityId
    $date = $pccFac.GoLiveDate
    $sqlcommand = "
        	Select	FacilityId,
			Sum(Case When DatePart(YEAR,AdmitDate) = '2018' Then 1 Else 0 End)
        	From Admission
	        Where FacilityID = $facId and Status = 2 And ResidentType = 1 and DatePart(YEAR,AdmitDate) = '2018' and AdmitDate < '$date'
	        Group By FacilityID"
    $facAdmissions = Invoke-SQL -dataSource "MRSCRSD4V\AG" -database SofCareClin -sqlCommand $sqlcommand

    foreach ($facility in $facilityAdmissions)
    {
        if ($facility.FacilityId -eq $facId)
        {
            $facility.Admissions2018 = $facAdmissions.column1
            break
        }
    }

}
$facilityAdmissions | Sort-Object -Property Division |export-csv -Path "C:\ps\Admissions2017-2018.csv"
