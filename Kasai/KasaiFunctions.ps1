Function Invoke-SQL {
    param(
        [string] $dataSource = $(throw "Please specify a server"),
        [string] $database = $(throw "Please secify a database"),
        [string] $sqlCommand = $(throw "Please specify a query."),
        [string] $user = "",
        [string] $pwd = ""
    )
    if($user -eq "")
    {
        $connectionString = "Data Source=$dataSource; Integrated Security=SSPI; Initial Catalog=$database"
    }
    else
    {
        $connectionString = "Data Source=$dataSource; Initial Catalog=$database; User Id=$user; Password =$pwd"
    }
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $connection)
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    try
    {
        $adapter.Fill($dataSet) | Out-Null
        $connection.Close()
        $dataSet.Tables
    }
    catch
    {
        $msg = "     ERROR: Unable to fill dataset! Reason: {0}" -f $PSItem
        Logger -color "Red" -string "$msg"
        $sqlUser = ""
        if($user -eq "")
        {
            $sqlUser = "Windows Auth"
        }
        else
        {
            $sqlUser = $user
        }
        $msg = "     User: {0} Server: {1} Database: {2}  SQL: {3}" -f $sqlUser,$dataSource,$database,$sqlCommand
        Logger -color "Red" -string "$msg"
        return $null
    }

}   

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )

    # Verify that the Log File Directory Exists, Create if not
    #---------------------------------------------------------
    if(Test-Path -Path $logFileLocation)
    {
        #No Action taken, Directory Exists
    }
    else
    {
        #Create Directory for Log files
        New-Item -Path $logFileLocation -ItemType Directory
    }

    Write-Host -ForegroundColor $color $string
    if($logToFile)
    {
        $logFile = $logFileLocation + $logFileName +"_" + $ReportDate + ".log"
        Add-Content -Path $logFile -value $string
    }
}

# Function to ensure that a path ends in a back slash
#----------------------------------------------------
Function AddBS {
    param ([string] $dir = $(throw "Directory value must not be null")
    )
    if($dir.Substring($dir.Length-1,1) -ne "\")
        {$dir += "\"}

    return $dir
}

# Function to read encrypted credential files
#--------------------------------------------
Function GetCredentials
{
    param([string] $user = "")
    Try
    {
        $PasswordFile = ".\Keys\{0}.txt" -f $user.Trim()
        $KeyFile = ".\Keys\{0}.key" -f $user.Trim()
        $key = Get-Content $KeyFile -ErrorAction SilentlyContinue
        $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key) -ErrorAction SilentlyContinue

        return $creds
    }
    Catch
    {
        $msg = "Unable to locate Credential file {0}; Skipping Server" -f $PasswrodFile
        Logger -color "Yellow" -string $msg

        return $null
    }
}  #End of Function GetCredentials
