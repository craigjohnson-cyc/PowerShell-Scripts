param ($facList)
#param ($rptStartDate, $facList) - 10/1/2020 - Start Date no longer required by the Data Relay query
#

# This Script will:
# •	Access the PCC DataRelay to get a list of facilities (PCC ID {FacilityID} and FIN ID {FacilityCode})
# •	For each Facility, 1) Execute query to retrieve a list of all wound assessments for any patient currently active or active as of input 
#                         parameter rptStartDate  ** 10/1/2020 Start Date no longer required by the Data Relay Query
# •                    2) A parameter (facList) has been added.  "ALL" will produce reports for All facilities, "xxx" will produce reports for a single facility
#                            "xxx,yyy,zzz......"  will product reports for each facility in the comma seperated list.
# •                    3) Write CSV file to a network file store
# 9/14 The two functions listed below have been removed.  Automate will now perform the upload since MobleIron is blocking the ability
#      of PowerShell to connect to SharePoint.
# •                    4) Upload CSV file to SPO Facility Documents
# •                    5) Delete CSV file from the temp location


Function Main
{
#    $facList = "ALL"              #Test 1 Facility Input Parameter
#    $facList = "589"               #Test 1 Facility Input Parameter
#    $facList = "627,653"   #Test 1 Facility Input Parameter 

#    $facList = "229"
#    $rptStartDate = "'2020-07-01'"

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

	#9/14 - It has been decided to use Automate to upload the files to SharePoint as MobileIron is blocking the connection
	#       from PowerShell to SharePoint.
	#---------------------------------------------------------------------------------------------------------------------
	## Get Credentials for SharePoint
    #$spoUser = "craig_johnson@lcca.com"
    #$PasswordFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\SharePointAuth.txt"
    #$KeyFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\AES.key"
    #$key = Get-Content $KeyFile
    #$spoCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $spoUser, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)

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
	$outputLocation = "\\fs3\xfer\SPO_Staging\Facility\WoundReport\"

    #TODO:  Remove the following 2 lines before deploying to production!  For Testing Purposes only
    #-------------------------------------------------------------------------------------------
    #$logFileLocation = "c:\ps\output\"
    #$outputLocation = "\\pes1\esss\Powershell Scripts\Output\WoundReports\"
    #-------------------------------------------------------------------------------------------

    $ReportDate = Get-Date -Format "MMddyyyy"

	#9/14 - It has been decided to use Automate to upload the files to SharePoint as MobileIron is blocking the connection
	#       from PowerShell to SharePoint.
	#---------------------------------------------------------------------------------------------------------------------
	##Load the SharePoint Online addin
	#if(-not(Get-Module -Name "SharePointPnPPowerShellOnline" -ListAvailable))
    #{
	#
    #    Install-Module -Name "SharePointPnPPowerShellOnline" -Confirm:$false -Force
	#
    #} else {
	#
    #    Import-Module -Name "SharePointPnPPowerShellOnline"
	#
    #}

    $d = Get-Date
    $msg = "PCC Wound Report:  Execution began at: {0} " -f $d
    Logger -color "green" -string "$msg"
    #Logger -color "green" -string "   Parameter rptStartDate value: $rptStartDate"
    Logger -color "green" -string "   Parameter facList value: $facList"
    Logger -color "green" -string "   "

    $pgmrTricks = "{0}"
    $fileName = "\{1}_Wound Report_{0}.csv" -f $ReportDate,$pgmrTricks

	#Get list of ShortNames for FIN2
	$fin2FacList = GetFacilityListFromFIN2

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
            $woundQuery = GetWoundQuery $facID.FacilityID #$rptStartDate

            $WoundData = GetDataFromDataRelay $woundQuery


            # Write CSV file
			#---------------
			WriteOutput $WoundData $facID $spoCredential

        }
    }
    $d = Get-Date
    $msg = "PCC Wound Report:  Execution ended at: {0} " -f $d
    Logger -color "green" -string "$msg"
}

Function GetFacilityFromDataRelayByPCCid
{
	param ($lccaFacID)

    $lookup = $lccaFacID.PadLeft(4,'0')
    $SqlQuery = "select FacilityID, FacilityCode, LineOfBusiness from view_ods_facility where FacilityCode = '{0}' and IsInactive = 'N';" -f $lookup

    $facIds = GetDataFromDataRelay $SqlQuery

    return $facIds
}


Function GetFacilitiesFromDataRelay
{
    #Get list of Facility ID's
    $SqlQuery = "select FacilityID, FacilityCode, LineOfBusiness from view_ods_facility where IsInactive = 'N';"

    $facIds = GetDataFromDataRelay $SqlQuery

    return $facIds
}

Function GetDataFromDataRelay
{
    param ($SqlQuery)

    #$connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $SQLServer,$SQLDBName,$sqlCredential.UserName,$sqlCredential.Password
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

	#9/14 - It has been decided to use Automate to upload the files to SharePoint as MobileIron is blocking the connection
	#       from PowerShell to SharePoint.
	#---------------------------------------------------------------------------------------------------------------------
	# Leaving the following code as it is also used for Empty report file
	#---------------------------------------------------------------------------------------------------------------------
	# Find ShortName of Fac being processed - Needed to locate the SharePoint folder, folder names should match FIN2 Short Name
	$facShortName = ""
	foreach($facility in $fin2FacList)
	{
    	if ($PccFacID.FacilityCode -eq  ([string]$facility.LawsonID).PadLeft(4,'0')  )
		{
			$facShortName = $facility.ShortName
            break
		}
	}

    $folder = ([string]$PccFacID.FacilityCode).PadLeft(4,'0')
    if($PccFacID.LineOfBusiness -eq "ALF")
    {
        $folder = $folder + "_ALF"
    }

    $facReportName = $fileName -f $folder

	set-location $outputLocation
	$outputFile = $outputLocation + $facReportName

    $noDataMsg = "No records for facility {0}, {1} - {2}" -f $PccFacID.FacilityCode, $facShortName, $PccFacID.LineOfBusiness
    $validData = $false
    foreach($rec in $ReportData)
    {
        if($rec.AssessmentDate -ne $null)
        {
            $validData = $true
            break
        }
    }

    if($validData)
    {
        $ReportData | Select-Object -Property AssessmentDate, 'Unit Room-Bed', Name, 'Onset Date', 'Admitted or Acquired', Location, Type, 'Stage/Category', Length, Width, Depth, 'Undermining/Tunneling', Drainage, 'Signs of Infection?', 'Pain?', Treatment, 'Overall Impression'| export-csv $outputFile  -NoTypeInformation
    }
    else
    {
        $noDataMsg | Out-File $outputFile
    }

	#9/14 - It has been decided to use Automate to upload the files to SharePoint as MobileIron is blocking the connection
	#       from PowerShell to SharePoint.
	#---------------------------------------------------------------------------------------------------------------------
    ## Connect to SharePoint
	##Connect-PnPOnline -Url https://lcca.sharepoint.com/sites/FacilityDocumentPortal -Credentials $Cred
	#Connect-msolservice -Url https://lcca.sharepoint.com/sites/FacilityDocumentPortal -Credentials $Cred
	##Connect-PnPOnline -Url https://lcca.sharepoint.com/sites/FacilityDocumentPortal -CurrentCredentials

	## Upload File
	#$DocLibName = "/Shared Documents/{0}/PCC Wound Reports" -f $facShortName
	#Add-PnPFile -Path $outputFile -Folder $DocLibName

	##Clean up
	#Remove-Item $outputFile
	#---------------------------------------------------------------------------------------------------------------------

}
Function GetFacilityListFromFIN2
{
	$sqlcommand = "select distinct LawsonId, ShortName from [dbo].[Entity]"
    $activeFacs = Invoke-SQL -dataSource "BDDB1V" -database "FIN2" -sqlCommand $sqlcommand

	return $activeFacs
}

Function GetWoundQuery
{
    param ($facID)
    #param ($facID, $rptStartDate)

    $q = "IF OBJECT_ID('tempdb..#WoundAssessments') IS NOT NULL
DROP TABLE #WoundAssessments;

CREATE TABLE #WoundAssessments
([AssessmentDate]        DATETIME, 
 [Unit Room-Bed]         VARCHAR(127), 
 [Name]                  VARCHAR(102), 
 [AssessmentID]          INT, 
 [PatientID]             INT, 
 [Onset Date]            DATE, 
 [Admitted or Acquired]  VARCHAR(350), 
 [Location]              VARCHAR(2000), 
 [Type]                  VARCHAR(350), 
 [Stage]                 VARCHAR(350), 
 [DetailsB]              VARCHAR(350), 
 [DetailsC]              VARCHAR(350), 
 [DetailsD]              VARCHAR(350), 
 [DetailsDC]             VARCHAR(2000), 
 [DetailsF]              VARCHAR(2000), 
 [Suspected DTI]         VARCHAR(350), 
 [Length]                VARCHAR(2000), 
 [Width]                 VARCHAR(2000), 
 [Depth]                 VARCHAR(2000), 
 [Undermining/Tunneling] VARCHAR(2000), 
 [Drainage]              VARCHAR(350), 
 [Signs of Infection?]   VARCHAR(350), 
 [Pain?]                 VARCHAR(350), 
 [Treatment]             VARCHAR(2000), 
 [Overall Impression]    VARCHAR(350)
);

INSERT INTO #WoundAssessments
([AssessmentDate], 
 [AssessmentID], 
 [PatientID], 
 [Onset Date], 
 [Admitted or Acquired], 
 [Location], 
 [Type], 
 [Stage], 
 [DetailsB], 
 [DetailsC], 
 [DetailsD], 
 [DetailsDC], 
 [DetailsF], 
 [Suspected DTI], 
 [Length], 
 [Width], 
 [Depth], 
 [Undermining/Tunneling], 
 [Drainage], 
 [Signs of Infection?], 
 [Pain?], 
 [Treatment], 
 [Overall Impression]
)
       SELECT a.AssessmentDate, 
              r.AssessmentID, 
              a.PatientID, 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_1a'
                             THEN r.ItemValue
                         END), '') AS [Onset Date], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_1'
                             THEN r.ItemDesc
                         END), '') AS [Admitted or Acquired], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_2'
                             THEN r.ItemValue
                         END), '') AS [Location], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3'
                             THEN r.ItemDesc
                         END), '') AS [Type], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3a'
                             THEN r.ItemDesc
                         END), '') AS [Stage], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3b'
                             THEN r.ItemDesc
                         END), '') AS [DetailsB], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3c'
                             THEN r.ItemDesc
                         END), '') AS [DetailsC], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3d'
                             THEN r.ItemDesc
                         END), '') AS [DetailsD], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3dc'
                             THEN r.ItemValue
                         END), '') AS [DetailsDC], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3f'
                             THEN r.ItemValue
                         END), '') AS [DetailsF], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3ae'
                             THEN r.ItemDesc
                         END), '') AS [Suspected DTI], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6a'
                             THEN r.ItemValue
                         END), '') AS [Length], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6b'
                             THEN r.ItemValue
                         END), '') AS [Width], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6c'
                             THEN r.ItemValue
                         END), '') AS [Depth], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6d'
                             THEN r.ItemValue
                         END), '') AS [Undemining/Tunneling], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_5a'
                             THEN r.ItemDesc
                         END), '') AS [Drainage], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_7a'
                             THEN r.ItemDesc
                         END), '') AS [Signs of Infection?], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_8a'
                             THEN r.ItemDesc
                         END), '') AS [Pain?], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_C_1'
                             THEN r.ItemValue
                         END), '') AS [Treatment], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_4a'
                             THEN r.ItemDesc
                         END), '') AS [Overall Impression]
       FROM [dbo].[view_ods_std_assessment_with_responses] AS r WITH(NOLOCK)
            INNER JOIN [dbo].[view_ods_assessment] AS a WITH(NOLOCK) ON a.assessmentid = r.assessmentid
       WHERE a.FacilityID = {0}
             AND r.StdAssessID = 11027
			 AND a.AssessmentDate >= '2020-10-01'
             AND a.Deleted = 'N'
             AND a.AssessmentStatus = 'Complete'
             AND r.QuestionKey IN('Cust_B_1', 'Cust_B_1', 'Cust_B_2', 'Cust_B_3', 'Cust_B_3a', 'cust_B_3b', 'cust_B_3c', 'cust_B_3d', 'cust_B_3dc', 'cust_B_3f', 'Cust_B_6a', 'Cust_B_6b', 'Cust_B_6c', 'Cust_B_6d', 'Cust_B_5a', 'Cust_B_7a', 'Cust_B_8a', 'Cust_B_8a1', 'Cust_C_1', 'Cust_B_4a', 'Cust_B_1a', 'Cust_B_3ae')
       GROUP BY r.AssessmentID, 
                a.PatientID, 
                a.AssessmentDate;


UPDATE #WoundAssessments
  SET 
      Name = concat(p.LastName, ', ', p.FirstName)
FROM [dbo].[view_ods_facility_patient] p WITH(NOLOCK)
     INNER JOIN #WoundAssessments w ON p.PatientID = w.PatientID
WHERE p.FacilityID = {0};

UPDATE #WoundAssessments
  SET 
      [Unit Room-Bed] = concat(unit.unitdescription, ' ', room.roomdescription, '-', bed.beddesc)
FROM #woundassessments w
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_patient_census] AS census WITH(NOLOCK) ON census.PatientID = w.PatientID -- = census.patientid
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_bed] AS bed WITH(NOLOCK) ON bed.BedId = census.BedID -- = bed.BedID
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_unit] AS unit WITH(NOLOCK) ON unit.UnitID = bed.UnitID
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_room] AS room WITH(NOLOCK) ON room.RoomID = bed.RoomID
WHERE unit.facilityid = {0}
      AND bed.facilityid = {0}
	  and census.EndEffectiveDate is null;

SELECT --[AssessmentId], 
[AssessmentDate], 
[Unit Room-Bed], 
[Name], 
[Onset Date], 
[Admitted or Acquired], 
[Location], 
[Type], 
[Stage/Category], 
[Length], 
[Width], 
[Depth], 
[Undermining/Tunneling], 
[Drainage], 
[Signs of Infection?], 
[Pain?], 
[Treatment], 
[Overall Impression]
FROM
(
    SELECT [AssessmentID], 
           CONVERT(DATE, [AssessmentDate]) AS [AssessmentDate], 
           [Unit Room-Bed], 
           [Name], 
           CONVERT(DATE, [Onset Date]) AS [Onset Date], 
           [Admitted or Acquired], 
           [Location], 
           [Type], 
           LTRIM(Replace(CONCAT([Stage], [Suspected DTI], [DetailsB], [DetailsC], Replace([DetailsD], 'Other', 'Other: '), [DetailsDC], [DetailsF]), 'Unstageable', '')) AS [Stage/Category], 
           [Length], 
           [Width], 
           [Depth], 
           [Undermining/Tunneling], 
           [Drainage], 
           [Signs of Infection?], 
           [Pain?], 
           [Treatment], 
           [Overall Impression], 
           ROW_NUMBER() OVER(PARTITION BY w.name, 
                                          w.location ORDER BY w.assessmentdate DESC) AS rank
    FROM #WoundAssessments w
         INNER JOIN view_ods_patient_census c WITH(NOLOCK) ON w.patientid = c.patientid
    WHERE c.FacilityId = {0}
          AND c.censusid IN
    (
        SELECT CensusID
        FROM
        (
            SELECT CensusID, 
                   ROW_NUMBER() OVER(PARTITION BY PATIENTID ORDER BY ISNULL(endeffectivedate, '9999-12-31') DESC) AS Row#
            FROM view_ods_patient_census WITH(NOLOCK)
            WHERE facilityid = {0}
                  AND endeffectivedate IS NULL
        ) A
        WHERE Row# = 1
    )
) x
WHERE x.rank = 1
and [Overall Impression] <> 'Healed/Resolved'
ORDER BY name, 
         AssessmentDate DESC;

DROP TABLE #WoundAssessments;"-f $facID #, $rptStartDate - 10/1/2020 Start Date no longer needed by the Query
    
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
    $logFile = $logFileLocation + "PccWoundReport_" + $ReportDate + ".log"
    Add-Content -Path $logFile -value $string
}

# Script Begins Here - Execute Function Main
Main