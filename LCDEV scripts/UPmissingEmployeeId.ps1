param (
       [Parameter(Mandatory=$true)][String] $searchValue
       )

#Missing Employee ID Report
Function Main 
{
    # This report will:
    # •	be used by UP to periodically look for accounts that have not had an Employee ID assigned to them.
    # •	look at all facility level accounts that do not include “Student” in the Description (AD Job Title Attribute).
    # •	Be ran once a week with a 14-day look back. (day of the week to be determined)
    #    o	An initial report for all accounts should be ran
    #    o	Then include only account created in the past 14 days.

    #$outputPath = "C:\ps\Output\"
    $userList = @()
    $lookBackDate = (Get-Date).AddDays(-14)

    #Get the cn of all OU with an entityType = 1000 - List of Facilities
    $facilities = Get-ADOrganizationalUnit   -Filter 'entityType -eq 1000'  -Properties:allowedChildClassesEffective,allowedChildClasses,entityType | Select Name,DistinguishedName

    foreach ($fac in $facilities) 
    {
        #$users = Get-ADGroupMember -identity $fac.Name -Recursive | Get-ADUser  -Property Info,DisplayName,title,whenCreated,Enabled,employeeId | Select Name, SamAccountName, title,Info, whenCreated, Enabled, employeeID
        $users = Get-ADUser -SearchBase $fac.DistinguishedName -Filter * -Property Info,DisplayName,title,whenCreated,Enabled,employeeId,office | Select Name, SamAccountName, title,Info, whenCreated, Enabled, employeeID,office


        #$users = Get-ADOrganizationalUnit -Filter 'entitytype -eq 1000' | % {Get-ADUser -SearchBase $_.DistinguishedName -Filter * -Properties Info,DisplayName,title,whenCreated,Enabled,employeeId,office | ft -a Name, SamAccountName, title,Info, whenCreated, Enabled, employeeID, office }
        $usersProcessed = 0
        foreach ($user in $users)
        {
            $usersProcessed += 1
            #Look only at active accounts
            if ($user.Enabled)
            {
                if ($searchValue.toLower() -eq "all")
                {
                    #No Action Taken
                }
                elseif ($user.whenCreated -lt $lookBackDate)
                {
                    #Look only at account created in the last 14 days
                    continue
                }

                #Disregard Studens
                if ($user.Title -like '*Student*')
                {
                    continue
                }
                #Disregard Surveyors
                if ($user.Title -like '*Surveyor*')
                {
                    continue
                }
                #Disregard kiosk
                if ($user.SamAccountName.toLower() -like '*kiosk*')
                {
                    continue
                }
                #Disregard abaqis
                if ($user.SamAccountName.toLower() -like '*abaqis*')
                {
                    continue
                }
                #Disregard accounts that start with SVC_
                if ($user.SamAccountName.toLower().StartsWith("svc_"))
                {
                    continue
                }
                #Disregard accounts that start with T_ (Test accounts)
                if ($user.SamAccountName.toLower().StartsWith("t_"))
                {
                    continue
                }
                #Look only at accounts missing Employee ID
                if (!$user.employeeId)
                {
                    #Report on this user
                    $userObj = CreatePersonObject $user.Office $user.SamAccountName $user.Name $user.title $user.whenCreated $user.employeeID
                    $userList += $userObj
                }
            }
        }
    }
    # Create CSV file

    #Production Value:
    #$filePath = "\\fs3\edrive\User Provisioning\Missing Employee IDs\"
    #------------------------------------------------------------------
    #Test Value:
    $filePath = "\\dfs3\edrive\User Provisioning\Missing Employee IDs\"
    #--------------------------

    $fileName = $filePath + "UPmissingEmployeeId-" + (Get-Date).ToString("MM-dd-yyyy") + ".csv"
    $userList | export-csv -Path $fileName -NoTypeInformation

    # Send email
    if ($searchValue.toLower() -eq "all")
    {
        $body = "The attached file lists accounts that do not have an Employee ID in Active Directory"
    }
    else
    {
        $body = "The attached file lists accounts that have been created since $lookBackDate (in the last 14 days) but do not have an Employee ID in Active Directory"
    }
    $body += "<br><br>"
    $body += "This report, and previous reports for the past 30 days, can be found at:<br>"
    $body += "<a href='$filePath'>$filePath</a>"

    #Production 
     #Send-MailMessage -BodyAsHtml $body -From "Johnson, Craig <craig_johnson@lcca.com>" -Subject "UP Process Verification - AD Accounts Missing Employee ID" -SmtpServer lccarelay.lcca.net `
     #   -To "UserProvisioningNotifications <_31f59f@lcca.com>", `
     #       "Johnson, Craig <Craig_Johnson@lcca.com>" `
     #   -attachment $fileName
     #-----------------------------------------------------------------------------------------

    #Testing
    Send-MailMessage -BodyAsHtml $body -From "Johnson, Craig <craig_johnson@lcca.com>" -Subject "TEST - UP Process Verification - AD Accounts Missing Employee ID - TEST" -SmtpServer lccarelay.lcca.net `
        -To "Arnold, Andy <Charles_Arnold@lcca.com>", `
            "Johnson, Craig <Craig_Johnson@lcca.com>", `
            "Parks, Brittany<Brittany_Parks@lcca.com>" `
        -attachment $fileName
     #-----------------------------------------------------------------------------------------
             
}


function CreatePersonObject()
{
    param ($facility, $SamAccountName, $name, $title, $whenCreated, $employeeId)
    
    $perObj = New-Object PSObject
    $perObj | add-member -type NoteProperty -Name EmployeeId -Value $employeeId
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name Title -Value $title
    $perObj | Add-Member -type NoteProperty -Name Facility -Value $facility
    $perObj | add-member -type NoteProperty -Name CreatedDate -Value $whenCreated

    return $perObj
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





# Script Begins Here - Execute Function Main


Main