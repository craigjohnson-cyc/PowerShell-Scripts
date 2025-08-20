param ($facList)
#

# This Script will:
# •	Access the PCC DataRelay to get a list of facilities (PCC ID {FacilityID} and FIN ID {FacilityCode})
# •	For each Facility, 1) Execute query to retrieve a list of patients currently active or active as of input 
# •                    2) A parameter (facList).  "ALL" will produce reports for All facilities, "xxx" will produce reports for a single facility
#                            "xxx,yyy,zzz......"  will product reports for each facility in the comma seperated list.
# •                    3) Write CSV file to a network file store
# Automate will perform the upload to the Facility Portal


Function Main
{
    $facList = "ALL"              #Test 1 Facility Input Parameter
#    $facList = "589"               #Test 2 Facility Input Parameter
#    $facList = "627,653"   #Test 3 Facility Input Parameter 

    #$facList = "229,196"

    set-location "\\pes1\esss\craig\powershell scripts\PCCWoundReport"
    $invocation = (Get-Variable MyInvocation).Value
    try
    {
        $directorypath = Split-Path $invocation.MyCommand.Path
    }
    catch
    {
        $directorypath = $invocation.PSScriptRoot
    }


    $SQLServer = "MRPCDRS2X"
    $SQLDBName = "PCCDataRelay"
	# Get Credentials for PccDataRelay - SQL Auth
    $sqlUser = "lccadatarelayreader"

    $PasswordFile = ".\DataRelayAuth.txt"
    $KeyFile = ".\AES.key"
	#-----------------------------------------------------------------------------------------
    $key = Get-Content $KeyFile
    $sqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlUser, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
    $pwd = $sqlCredential.GetNetworkCredential().Password


    if($facList.ToUpper() -eq "ALL")
    {
        # Get Facility list from DataRelay
        $facIds = GetFacilitiesFromDataRelay
    }
    else
    {
        $facIds = @()
        # Use Facilities provided in input parameter
        $fList = $facList.Split(",")
        foreach($facility in $fList)
        {
            # Get the PCC ID for this Facility
            $facs = GetFacilityFromDataRelayByPCCid $facility
            foreach($fac in $facs)
            {
                if($fac.FacilityID -ne $null)
                {
                    $facIds += $fac
                }
            }
        }
    }

    $logFileLocation = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\PCC_Wound_Reports\Logs\" 
	$outputLocation = "\\fs10\Xfer\{0}\Omnicare_COVID_19_MPR_Template\"

    #TODO:  Remove the following 2 lines before deploying to production!  For Testing Purposes only
    #-------------------------------------------------------------------------------------------
    $logFileLocation = "c:\ps\output\"
    #$outputLocation = "\\pes1\esss\Powershell Scripts\Output\WoundReports\"
    #-------------------------------------------------------------------------------------------

    $ReportDate = Get-Date -Format "MMddyyyy"

    $d = Get-Date
    $msg = "PCC COVID Vax LIst:  Execution began at: {0} " -f $d
    Logger -color "green" -string "$msg"
    Logger -color "green" -string "   Parameter facList value: $facList"
    Logger -color "green" -string "   "

    $pgmrTricks = "{0}"
    $fileName = "\{0}_{1}_Omnicare_COVID_19_MPR_Template.csv" -f $ReportDate,$pgmrTricks
	#Get list of ShortNames for FIN2
	#$fin2FacList = GetFacilityListFromFIN2

    foreach($facID in $facIds)
    {
        if (![string]::IsNullOrWhiteSpace($facID.FacilityID))
        {
            if($facID.FacilityID -eq 9001)
            {
                continue
            }
            $finID = $facID.FacilityCode
            Logger -color "green" -string "   Generating report for Facility ID: $finID"
            $woundQuery = GetQuery $facID.FacilityCode

            $WoundData = GetDataFromDataRelay $woundQuery


            # Write CSV file
			#---------------
			WriteOutput $WoundData $facID $spoCredential

        }
    }
    $d = Get-Date
    $msg = "PCC COVID Vax LIst:  Execution ended at: {0} " -f $d
    Logger -color "green" -string "$msg"
}

Function GetFacilityFromDataRelayByPCCid
{
	param ($lccaFacID)

    $lookup = $lccaFacID.PadLeft(4,'0')
    $SqlQuery = "select FacilityID, FacilityCode, LineOfBusiness from view_ods_facility where FacilityCode = '{0}' and IsInactive = 'N' and LineOfBusiness = 'SNF';" -f $lookup

    $facIds = GetDataFromDataRelay $SqlQuery

    return $facIds
}


Function GetFacilitiesFromDataRelay
{
    #Get list of Facility ID's
    $SqlQuery = "select FacilityID, FacilityCode, LineOfBusiness from view_ods_facility where IsInactive = 'N' and LineOfBusiness = 'SNF';"

    $facIds = GetDataFromDataRelay $SqlQuery

    return $facIds
}

Function GetDataFromDataRelay
{
    param ($SqlQuery)

    $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $SQLServer,$SQLDBName,$sqlCredential.UserName,$pwd
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $sqlConnection.Open()

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlcmd.CommandTimeout=0
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet

	$sqlAvailable = $false
	$ErrorActionPreference = 'Stop'      # needed to raise SQL error to level that can be caught
	Do
	{
		try
		{
            $SqlAdapter.Fill($DataSet)           # Attempt to execute Query
			$sqlAvailable = $true                # set condition to exit loop
		}
		catch
		{
			Logger -color "yellow" -string "   SQL error detected!! Going to sleep for 20 minutes"
			Start-Sleep -Seconds 1200            # Sleep for 20 minutes
		}

	} # End of Do
	While (!$sqlAvailable)
    
	$ErrorActionPreference = 'Continue'  # reset back to normal value


    return $DataSet.Tables[0]
}


Function WriteOutput
{
	param ($ReportData, $PccFacID, $Cred)

    $folder = ([string]$PccFacID.FacilityCode).PadLeft(4,'0')

    $facReportName = $fileName -f $folder
    $outputLocation = $outputLocation -f $folder


	set-location $outputLocation
	$outputFile = $outputLocation + $facReportName

    
    $ReportData | Select-Object -Property PatientType, PatientDose, FirstName, LastName, DateOfBirth, Gender, Address, City, State, Zip, Email, HomePhone, AgeStatus, MBI| export-csv $outputFile  -NoTypeInformation

    #Launch Excel
    $pathxls = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\Omnicare COVID 19 Multi-Patient Registration Template.xlsx"
    $pathcsv = $outputFile #"\\pes1\esss\Powershell Scripts\Output\WoundReports\0229_COVID_Vax_List_12282020.csv"
    $dataTab = Split-Path $pathcsv -leaf
    $dataTab = $dataTab.Substring(0,$dataTab.Length - 4)
    #Change in output file name exceeds the lenght for a Worksheet name (31 chars)  Thus need to shorten the tab name but need to keep full file name
    $outFileName = $dataTab
    $dataTab = $dataTab.Substring(0,31)

    $Excel = New-Object -ComObject excel.application
    $Excel.visible = $false
    $Workbook = $excel.Workbooks.open($pathcsv)
    $Workbook2 = $excel.Workbooks.open($pathxls)
    $Worksheet = $Workbook.WorkSheets.item($dataTab)
    $Worksheet.activate()
    $rowCount =  $worksheet.UsedRange.Rows.Count #- 1
    $rangeval = "A3:N" + $rowCount.Tostring()
    $rangeval = "N" + $rowCount.Tostring()

    $rng = $worksheet.Range("A3",$rangeval)
    $range = $WorkSheet.Range($rangeval).CurrentRegion
    #$range.Copy() | out-null
    $rng.Copy() | out-null
    $Worksheet2 = $Workbook2.Worksheets.item(“Sheet1”)
    $worksheet2.activate()
    $range2 = $Worksheet2.Range(“A3:A3”)
    $Worksheet2.Paste($range2)

    $path = "\\pes1\esss\Powershell Scripts\Output\WoundReports\" + $outFileName + ".xlsx"
    $path = $outputLocation + $outFileName + ".xlsx"
    $workbook2.SaveAs($path)
    $workbook2.close()
    $workbook.close($false)
    $Excel.Quit()
    # Delete csv work file
    Remove-Item $outputFile

}


Function GetFacilityListFromFIN2
{
	$sqlcommand = "select distinct LawsonId, ShortName from [dbo].[Entity]"
    $activeFacs = Invoke-SQL -dataSource "BDDB1V" -database "FIN2" -sqlCommand $sqlcommand

	return $activeFacs
}

Function GetQuery
{
    param ($facID)
    #param ($facID, $rptStartDate)

    $q = "SELECT patient.[FacilityCode]
      ,'Resident' as PatientType
      ,' ' as PatientDose
      ,patient.[FirstName]
      ,patient.[LastName]
      ,isnull(Convert(Varchar(500),patient.[DateOfBirth],101),'') as DateOfBirth
	  ,CASE
		WHEN patient.[Gender] is null then ''
		WHEN patient.[Gender] = 'F' then 'Female'
		WHEN patient.[Gender] = 'M' then 'Male'
	  END as Gender
      ,isnull(fac.[FacilityAddress],'') as Address
      ,isnull(fac.[FacilityCity],'') as City
      ,isnull(fac.[FacilityState],'') as State
	  ,COALESCE(LEFT(fac.[FacilityPC],5),SPACE(1)) as Zip
      ,'' as Email --isnull(patient.[Email],'') as Email
      ,isnull(fac.[FacilityPhone],'') as HomePhone
	 ,CASE
		WHEN patient.[DateOfBirth] is null then ''
		WHEN DATEADD(YEAR, 65, patient.[DateOfBirth]) < getdate() THEN 'Y'
		WHEN DATEADD(YEAR, 65, patient.[DateOfBirth]) >= getdate() THEN 'N'
	 END AS AgeStatus
	 ,patient.[MBI] as MBI
FROM [PCCDataRelay].[dbo].[view_ods_facility_patient] patient
  inner join [PCCDataRelay].[dbo].[view_ods_facility] fac on patient.facilityid = fac.facilityID
  inner join [PCCDataRelay].[dbo].[view_ods_daily_census] census on census.ClientID = patient.patientID 
  where census.CensusStatusCode = 'A' and census.CensusDate = DATEADD(dd, DATEDIFF(dd, 0, getdate()), 0)
    and patient.FacilityCode = {0}
  order by LastName "-f $facID 
    
    return $q
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


# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $logFile = $logFileLocation + "OmnicareCOVIDMultiPatientRegistration_" + $ReportDate + ".log"
    Add-Content -Path $logFile -value $string
}

# Script Begins Here - Execute Function Main
Main