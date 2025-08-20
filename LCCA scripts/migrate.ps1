# Function to connect to specified SQL server and database and run a query
Import-Module SharePointPnPPowerShell2013
Import-Module ActiveDirectory

Function Main {
    Start-Transcript -Path c:\temp\pccrollout2.txt -Force -Append


    #Populate a variable with all files.  This prevents you from having to search the file system everytime when trying to find a file.  Instead you search the variable for the file.
    #Note the variable just contains information about the file not the file contents.
    $thefiles = Get-ChildItem -Path "\\wdmv2\rapport" -Recurse -Filter *.ini | Where-Object { $_.fullname -notlike "*MCA*" }
    Logger -color "green" -string "INI files found in WDMV2\RAPPORTDB: $($thefiles.count)"


    #Connect to SharePoint site, the account that runs this task will need permission to access the Sharepoint site
    Connect-PnPOnline -Url http://lccavs/team/it/projects/ClinicalBillingSoftware -CurrentCredentials
    $filterField = "Clinical_x0020_Go_x0020_Live"
    $corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -eq [DateTime]::today -and [DateTime]$_[$filterField].ToShortTimeString() -lt [DateTime]::Now.ToShortTimeString() } | ForEach-Object { $_["CorpID"] }


    #For every faciltiy returned from the sharepoint list search AD using the corpid and return the name and url (aka: facility subnet)
    $facs = New-Object System.Collections.ArrayList 
    foreach ($corp in $corpids) {
        [void]$facs.Add( (Get-ADObject -LDAPFilter "(&(entityid=$corp)(objectCategory=organizationalUnit))" -Properties url | Select-Object name, url) )
        Logger -string "Facility Found: $($facs[-1].url)"
    }


    #This is used for testing and should be commented out for produciton use.
    #$facs = New-Object System.Object
    #$facs | Add-Member -Type NoteProperty -Name name -Value "Test Facility"
    #$facs | Add-Member -Type NoteProperty -Name url  -Value "172.22.249"


    foreach ($fac in $facs) {
        "=" * 150 #Horizontal Line
        #Query WDM for all Wyse thinclients on a specific facility subnet
        $sqlcommand = "
	    SELECT	cn.MAC as uniqueid
	    FROM	Client c INNER JOIN
			    ClientNetwork cn ON c.ClientID = cn.ClientID
	    WHERE c.CheckIn >= '2017-01-01' and cn.IP like '$($fac.url).%'"
        $dbitems = Invoke-SQL -dataSource "WDMV2\RAPPORTDB" -database RapportDB -sqlCommand $sqlcommand
	
        $sqlcommand = "
	    SELECT	SUBSTRING(c.name,3,20) as uniqueid
	    FROM	Client c INNER JOIN
			    ClientNetwork cn ON c.ClientID = cn.ClientID
	    WHERE c.CheckIn >= '2017-01-01' and cn.IP like '$($fac.url).%'"
        $dbitems += Invoke-SQL -dataSource "WDMV2\RAPPORTDB" -database RapportDB -sqlCommand $sqlcommand
        Logger -color "green" -string "$($fac.name) - $($fac.url) - WYSE Thinclients Found: $($dbitems.mac.count)"

        $uniquedbitems = $dbitems | Sort-Object uniqueid -unique

        ForEach ($dbitem in $uniquedbitems) {
            #Iterate through all WYSE devices return from the database query
            foreach ( $file in ($thefiles | Where-Object { $_.name -like $($dbitem.uniqueid + ".ini") })) {
                #Iterate throught all files returned for a single wyseDeviceMacAddress.ini file
                #No need to test for missing files the foreach only returns files that have been found.
                if (-not (Select-String -Path $file.fullname -Pattern "Command=C:\\ADL")) {
                    #Check if the file found contains a string, what to do if file does not contain string
                    #Logger -color "red" -string "$($fac.name) $($fac.url) Missing ADL`t $($file.fullname)"
                    if (Select-String -Path $file.fullname -Pattern 'Command="C:\\Program Files \(x86\)') {
                        Logger -string "$($fac.url) $($file.fullname)"
                    }
                } else {
                    #What to do if file contains the string
                    Foreach ($line in (Get-Content $file.fullname)) {
                        #Iterate through all lines in the file and replace lines with desired content.
                        $newline = $line -replace '^SignOn=.+$', "SignOn=No`r`nScreensaver=`"2`"" -replace '^Description=.+$', 'Description="PointClickCare POC" \' -replace '^Command=C:\\ADL.+$', 'Command="C:\Program Files (x86)\Internet Explorer\iexplore.exe -k https://login.pointclickcare.com/poc/userLogin.xhtml" \'
                        $newfile += "$newline`r`n"																		#Append the modified or unmodified line to the file.
                    }
                    Out-File -FilePath "$($file.fullname)" -InputObject $newfile -Encoding ASCII						#Write the file out to disk
                    Logger -string "$($fac.url) $($file.fullname)"
                    $newfile = ""
                }
            }
        }
	
        [int]$thirdOctet = $fac.url.Split(".")[2]
        $formattedThirdOctet = $thirdOctet.ToString("000")
        $filter = "F$formattedThirdOctet*"
        Get-ADComputer -Filter {Name -like $filter} -SearchBase "OU=Win 10,OU=Venue8,OU=ABAQIS,OU=Kiosks,DC=lcca,DC=net" | ForEach-Object { Add-ADGroupMember "CN=PCC POC Migration,OU=Kiosks,DC=lcca,DC=net" $_}
	
    }

    Stop-Transcript
}


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

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    Add-Content -Path C:\temp\pccrollout.txt -value $string
}

Main