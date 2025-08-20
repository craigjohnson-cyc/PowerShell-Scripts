Function Main
{
# This Script will:
# •	Access the PCC DataRelay to get a list of active ALF facilities (PCC ID {FacilityID} and FIN ID {FacilityCode})
# •	Access the PCC DataRelay to get Closure status of those facilities
# •	For each Facility, 1) Execute stored procedure to merge the facilities to the Mirth_Repository
# •                    2) Execute Stored procedure to merge the closure status to the Mirth_Repository
#

    $logFileLocation = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\PCC_Wound_Reports\Logs\" 

    #TODO:  Remove the following 2 lines before deploying to production!  For Testing Purposes only
    #-------------------------------------------------------------------------------------------
    #$logFileLocation = "c:\ps\output\"
    #-------------------------------------------------------------------------------------------

    $ReportDate = Get-Date -Format "MMddyyyy"
    $SQLServer = "MRPCDRS2X"
    $SQLDBName = "PCCDataRelay"
	# Get Credentials for PccDataRelay - SQL Auth
    $sqlUser = "lccadatarelayreader"
    $PasswordFile = ".\DataRelayAuth.txt"
    $KeyFile = ".\AES.key"
    $key = Get-Content $KeyFile
    $sqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlUser, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
    $pwd = $sqlCredential.GetNetworkCredential().Password
    
    $facilities = GetFacilitiesFromDataRelay

    $closeState = GetCloseStateFromDataRelay
    
    if($facilities.Count -gt 0)
    {
        $SQLDBName = "Mirth_Repository_Dev"
        $SQLServer = "QARCPSDB1X"
        # 3) Add New Data to MirthRepository
        foreach($fac in $facilities)
        {
            if($fac.FacilityCode -ne $null)
            {
                $sqlcommand = "EXEC [PCC].[MergeALFFacilityCode] @FacilityID = {0}, @FacilityCode = '{1}'" -f  $fac.FacilityID, $fac.FacilityCode.ToString()
                $activeFacs = Invoke-SQL -dataSource $SQLServer -database $SQLDBName -sqlCommand $sqlcommand
            }
        }

        foreach($state in $closeState)
        {
            if($state.ConfigurationName -ne $null)
            {
                $sqlcommand = "EXEC [PCC].[MergeALFClosureStatus] @FacilityID = {0}, @ConfigurationName = '{1}', @ConfigurationValue = '{2}', @FacilityCode = '{3}', @FacilityName = '{4}'" -f $state.FacilityID, $state.ConfigurationName.ToString(), $state.ConfigurationValue.ToString(), $state.FacilityCode.ToString(), $state.FacilityName.ToString()
                $activeFacs = Invoke-SQL -dataSource $SQLServer -database $SQLDBName -sqlCommand $sqlcommand
            }
        }
    }
}

Function GetFacilitiesFromDataRelay
{
    #Get list of Facility ID's
    $SqlQuery = "select FacilityCode, FacilityID from [PCCDataRelay].[DBO].[view_ods_facility] where LineOfBusiness = 'ALF' and IsInactive = 'N';"

    $facIds = GetDataFromDataRelay $SqlQuery

    return $facIds
}

Function GetCloseStateFromDataRelay
{
    #Get Closure Status data
    $SqlQuery = "select pr.ConfigurationName,pr.ConfigurationValue,f.FacilityCode,f.FacilityName,f.FacilityID
                from view_ods_configuration_parameter pr
                inner join view_ods_facility f on pr.FacilityID=f.FacilityID
                where ConfigurationName = SUBSTRING(DATENAME(MONTH, DATEADD(Month,-1,GetDate())), 1, 3) + '_' + CAST(DATEPART(YEAR, DATEADD(Month,-1,GetDate())) AS VARCHAR(4)) + ' closed' and 
                f.FacilityCode in (select FacilityCode from view_ods_facility where LineOfBusiness = 'ALF' and IsInactive = 'N')
                order by RIGHT(pr.ConfigurationValue,14);"

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