#(Get-Credential).Password | ConvertFrom-SecureString | Out-File "C:\ps\output\SQLAuthDevBox.txt"


$password = Get-Content "C:\ps\output\sqlAuth.txt"
$a = [System.Net.NetworkCredential]::new("", $password).Password

#$cred = New-Object System.Management.Automation.PSCredential ("lccadatarelayreader",$password)



$file = "C:\ps\output\sqlAuth.txt"

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "lccadatarelayreader", (Get-Content $file | ConvertTo-SecureString)

    $SQLServer = "MRPCDRS2X"
    $SQLDBName = "PCCDataRelay"
    #$uid ="lccadatarelayreader"
    $uid = $cred.UserName

    #$pwd = "d35%FJ923ls78/*333##()#"
    #$pwd = $cred.Password
    $pwd = $cred.GetNetworkCredential().Password

    $SqlQuery = "select FacilityID, FacilityCode from view_ods_facility where IsInactive = 'N';"


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
    $a = 1