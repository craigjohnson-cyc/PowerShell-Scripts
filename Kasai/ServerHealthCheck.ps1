#Import-Module WebAdministration -Verbose
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Include common Functions
#-------------------------
. 'C:\Development2\Powershell Scripts\KasaiFunctions.ps1'

Function Main
{

    # Set Initial Values
    #-------------------
    $logFileLocation = "C:\Development2\PowerShell Scripts\Logs\"
    $baselogFileName = "ServerHealthCheck_{0}"
    $ReportDate = Get-Date -Format "MMddyyyy"
    $logToFile = $true
    $SqlServerStatus = $()
    $AppServerStatus = $()
    $DatabaseStatus = $()
    $SqlJobStatus = $()

    # Read CSV file of Servers
    #-------------------------
    $servers = @()  #create empty array
    $servers = Import-Csv -Path "C:\Development2\Powershell Scripts\ServerList.csv" | Sort-Object -Property Type -Descending

    #Loop through servers
    #--------------------
    foreach($server in $servers)
    {

        # Create log file for each server
        #--------------------------------
        $logFileName = $baselogFileName -f $server.Server

        switch ($server.Type.ToLower()) 
        {
            "data"
                {
                    $msg = "Checking Data Server '{0}' for '{1}'" -f $server.Server, $server.Location
                    Logger -color "Green" -string "$msg"
                    CheckSQLServers $server
                }
            "app"
                {
                    # - Gateways
                    $msg = "Checking App Server '{0}' for '{1}'" -f $server.Server, $server.Location
                    Logger -color "Green" -string "$msg"
                    CheckAppServers $server
                }
        }
    }

    #3 Send e-mail



} # End of Function Main

Function CheckSQLServers
{
    param ($server)

    #check status of Databases
    #-------------------------
    $user = "SA"

    if($server.Server.ToLower() -like '*ohio*')
    {
        $pw = ""
    }
    else
    {
        $pw = GetPassword $user
    }
    $sqlCommand = " SELECT @@servername,name, state_desc as Database_status FROM sys.databases "
    $dataSource = $server.Server
    $database = "master"

    #$DBstatus = Invoke-SQL $dataSource $database $sqlCommand
    $DBstatus = Invoke-SQL $dataSource $database $sqlCommand $user $pw
    if($DBstatus -ne $null)
    {
        $errors = 0
        foreach($db in $DBstatus)
        {
            if($db.Database_status -ne "ONLINE")
            {
                $errors += 1
                $msg = "     WARNING:  Database: {0} on Server: {2} is reporting Database Status of: {1}" -f $db.name, $db.Database_status, $db.Column1
                Logger -color "Yellow" -string "$msg"
            }
        }
        if($errors -eq 0)
        {
            $msg = "  All Databases on Server: {0} are reporting 'ONLINE'" -f $server.Server
            Logger -color "Green" -string "$msg"
        }
        $DatabaseStatus += $DBstatus
    }

    #Check status of any SQL Jobs
    #----------------------------
    $sqlCommand = "SELECT  
               j.[name] AS [JobName],  
               run_status = CASE h.run_status  
               WHEN 0 THEN 'Failed' 
               WHEN 1 THEN 'Succeeded' 
               WHEN 2 THEN 'Retry' 
               WHEN 3 THEN 'Canceled' 
               WHEN 4 THEN 'In progress' 
               END, 
               h.run_date AS LastRunDate,   
               h.run_time AS LastRunTime 
            FROM sysjobhistory h  
               INNER JOIN sysjobs j ON h.job_id = j.job_id  
                   WHERE j.enabled = 1   
                   AND h.instance_id IN  
                   (SELECT MAX(h.instance_id)  
                       FROM sysjobhistory h GROUP BY (h.job_id))"
    $database = "msdb"

    # This query Must be run as SA
    # Read credential files for SA
    #-----------------------------
    $user = "SA"
    
    if($server.Server.ToLower() -like '*ohio*')
    {
        $pw = ""
    }
    else
    {
        $pw = GetPassword $user
    }
    
    $SqlSysJobs = Invoke-SQL $dataSource $database $sqlCommand $user $pw
    
    if($SqlSysJobs -ne $null)
    {
        $errors = 0
        foreach($job in $SqlSysJobs)
        {
            if($job.run_status -eq "Succeeded" -or $job.run_status -eq "In Progress")
            {
                #No Action Taken
            }
            else
            {
                #Log Warning
                $errors += 1
                $msg = "     WARNING:  SQL Job: {0} on Server: {2} is reporting Status of: {1}" -f $job.JobName, $job.run_status, $server.Server
                Logger -color "Yellow" -string "$msg"
            }
        }
        if($errors -eq 0)
        {
            $msg = "  All SQL Jobs on Server: {0} are reporting 'Succeeded'" -f $server.Server
            Logger -color "Green" -string "$msg"
        }

        $SqlJobStatus += $SqlSysJobs
    }

    if($server.user -eq "" -or $server.user -eq $null)
    {
        $msg = " NOTICE: Services and Event Logs on server {0} - {1}:  Will be skipped as there is no user name in the input file" -f $server.server, $server.REFERRED_TO_AS
        logger -color "Yellow" -string "$msg"
    }
    else
    {
        #Check Services
        #--------------
        $computer = $server.server
    
        #Get user Credentials
        $creds = GetCredentials $server.User
        if($creds -eq $null)
        {
            #No Action to be taken, Credential file not found
        }
        else
        {
            $session = New-PSSession -ComputerName $computer -Credential $creds

            if($session -eq $null)
            {
                $msg = "   Unable to establish a Session to server {0}.  Unable to report on Services or Event Log entries" -f $computer
                logger -color "Yellow" -string $msg
            }
            else
            {
                $services = PerformGetServices $session

                #Check EventLog
                #--------------
                $eventLogType = "System"
                $syslog = PerformGetEventLog $session $eventLogType
                $eventLogType = "Application"
                $applog = PerformGetEventLog $session $eventLogType



                Remove-PSSession -Session $session
            }
        }
    }
}  # End of Function CheckSQLServers

Function GetPassword
{
    param([string] $user = "")

    $PasswordFile = ".\Keys\{0}.txt" -f $user
    $KeyFile = ".\Keys\{0}.key" -f $user
    $key = Get-Content $KeyFile
    $sqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
    $pwd = $sqlCredential.GetNetworkCredential().Password

    return $pwd
}  # End of Function GetPassword


Function CheckAppServers
{
    param ($server)

    if($server.user -eq "" -or $server.user -eq $null)
    {
        $msg = " NOTICE: App server {0} - {1}:  Will be skipped as there is no user name in the input file" -f $server.server, $server.REFERRED_TO_AS
        logger -color "Yellow" -string "$msg"
    }
    else
    {
        #Get user Credentials
        #--------------------
        $creds = GetCredentials $server.User
        if($creds -eq $null)
        {
            #No Action to be taken, Credential file not found
        }
        else
        {

            #1 Check App Pools
            $computer = $server.server
            $session = New-PSSession -ComputerName $computer -Credential $creds
        
            if($session -eq $null)
            {
                $msg = "   Unable to establish a Session to server {0}.  Unable to report on Services or Event Log entries" -f $computer
                logger -color "Yellow" -string $msg
            }
            else
            {
                $sb = {
                    Set-ExecutionPolicy unrestricted
                    Add-WindowsFeature Web-Scripting-Tools
                    Import-Module WebAdministration
                    $appPools = Get-ChildItem IIS:\AppPools\
                    return $appPools
                }

                $pools = Invoke-Command –Session $session –ScriptBlock $sb
                if($pools -eq $null)
                {
                    # No Action to be taken, server not running IIS
                }
                else
                {
                    foreach($pool in $pools)
                    {
                    $a = 1
                    }
                }

                #2 Check Services
                #----------------
                $services = PerformGetServices $session


                #3 Check EventLog
                #----------------
                $eventLogType = "System"
                $syslog = PerformGetEventLog $session $eventLogType
                $eventLogType = "Application"
                $applog = PerformGetEventLog $session $eventLogType

        



                #4 Check for expected running applications



                Remove-PSSession -Session $session
            }
        }

    }
} # End of Function CheckAppServers

Function PerformGetEventLog
{
    param(
        $session,
        $eventLogType
    )

    $sb = {
        Get-EventLog -LogName $Using:eventLogType -Newest 15
    }
    $sysLog = Invoke-Command –Session $session –ScriptBlock $sb
    $errorFound = $false
    foreach($logitem in $sysLog)
    {
        if($logitem.EntryType -eq "Error")
        {
            $msg = "  {3} Event Log reports error: {0} - {1}: at {2}" -f $logitem.Source, $logitem.Message, $logitem.TimeGenerated, $eventLogType
            logger -color "Red" -string "$msg"
            $errorFound = $true
        }
    }

    if(!$errorFound)
    {
        $msg = "  {0} Event Log reports No Errors" -f $eventLogType
        logger -color "Green" -string "$msg"
    }

    return $sysLog

} # End of Function PerformGetEventLog

Function PerformGetServices
{
    param ($session)

    $sb = {
        Get-Service
    }
    $services = Invoke-Command –Session $session –ScriptBlock $sb
    $errorFound = $false
    foreach($service in $services)
    {
        if($service.Status -ne "Running")
        {
            $msg =  "Service {0} - {1} reporting current status of {2}" -f $service.Name, $service.DisplayName, $service.Status
            logger -color "Yellow" -string "$msg"
            $errorFound = $true
        }
    }

    if(!$errorFound)
    {
        $msg = "  All Services report Running"
        logger -color "Green" -string "$msg"
    }

    return $services

} #End of Function PerformGetServices

# Script Begins Here
#-------------------

Main  # Execute Function Main

# End of Script ServerHealthCheck.ps1