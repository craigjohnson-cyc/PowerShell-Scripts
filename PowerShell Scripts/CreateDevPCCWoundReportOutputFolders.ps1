#Install-Module SQLServer
Function Main
{
    #Get list of Facility ID's
    $SQLServer = "MRPCDRS2X"
    $SQLDBName = "PCCDataRelay"
    $uid ="lccadatarelayreader"
    $pwd = "d35%FJ923ls78/*333##()#"
    $SqlQuery = "select FacilityCode from view_ods_facility where IsInactive = 'N';"


    $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $SQLServer,$SQLDBName,$uid,$pwd
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $sqlConnection.Open()

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlcmd.CommandTimeout=0
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet)
    $facIds = $DataSet.Tables[0]
    
    $WoundDataSet = New-Object System.Data.DataSet
    foreach($facID in $facIds)
    {
        if (![string]::IsNullOrWhiteSpace($facID.FacilityCode))
        {
            if($facID.FacilityID -eq 9001)
            {
                continue
            }
            $newFac = ([string]$facID.FacilityCode).PadLeft(4,'0') #$facID.FacilityID.ToString
            #$newFac = $newFac.PadLeft(4,'0')
            #$newDir = "c:\ps\Output\PCC WoundReports\{0}" -f $facID.FacilityID
            $newDir = "\\pes1\esss\Craig\PowerShell Scripts\Output\PCC WoundReports\{0}" -f $newFac
            [System.IO.Directory]::CreateDirectory($newDir)
        }
    }
}


# Script Begins Here - Execute Function Main
Main