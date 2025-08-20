Import-Module SharePointPnPPowerShell2013
Import-Module ActiveDirectory

function CreateActionObject()
#----------------------------
{
    param ($SamAccountName, $fname, $lname, $title, $office, $action, $group)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name FirstName -Value $fname
    $perObj | Add-Member -type NoteProperty -Name LastName -Value $lname
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name JobTitle -Value $title
    $perObj | add-member -type NoteProperty -Name FacilityName -Value $office
    $perObj | add-member -type NoteProperty -Name Action -Value $action
    $perObj | add-member -type NoteProperty -Name ADgroup -Value $group

    return $perObj
}

function ProcessRoleChangesGoLive
#--------------------------------
{
    $updates = @()
    $roleChanges = @()

    $facIds = GetFacilities $CURRENTDATE
    $roles = @( ("SofCare_Admissions","SofCare_Read_Only"),
                ("SofCare_BO","SofCare_Read_Only"),
                ("SofCare_ED","SofCare_Read_Only"),
                ("SofCare_Field_Controller","SofCare_Read_Only"),
                ("SofCare_HIM","SofCare_Read_Only"),
                ("SofCare_Nursing","SofCare_Read_Only"),
                ("SofCare_TreatmentNurse","SofCare_Read_Only"),
                ("SofCare_CareDirectives",""),
                ("SofCare_Cert_Med_Aide","SofCare_Read_Only"),
                ("SofCare_DualCPLib",""),
                ("SofCare_Export_Admissions","SofCare_Read_Only"),
                ("SofCare_FaceSheet",""),
                ("SofCare_HH_FaceSheet_Export",""),
                ("SofCare_LCPS","SofCare_Read-Only"),
                ("SofCare_Physician_Orders",""),
                ("SofCare_Weight_Entry","") )
    foreach($role in $roles)
    {
        $change = CreateRoleChangeObject $role[0] $role[1]
        $roleChanges += $change
    }

    $updates = ProcessRoleChanges $facIds $roleChanges
    return $updates

}

function ProcessRoleChangesGoLive15
#----------------------------------
{
    $updates = @()
    $roleChanges = @()
    #$CURRENTDATE=[DateTime]::today.AddDays(-15)

    $facIds = GetFacilities $CURRENTDATE
    $roles = @( ("SofCare_RUS","SofCare_Read_Only"),
                ("SofCare_672_802",""),
                ("SofCare_Act","SofCare_Read_Only"),
                ("SofCare_Dietary","SofCare_Read_Only"),
                ("SofCare_DON","SofCare_Read_Only"),
                ("SofCare_MDS","SofCare_Read_Only"),
                ("SofCare_MDSCoord_RN","SofCare_Read_Only"),
                ("SofCare_Rehab","SofCare_Read_Only"),
                ("SofCare_RSM","SofCare_Read_Only"),
                ("SofCare_SS","SofCare_Read_Only"),
                ("SofCare_CL_Reg_Div","SofCare_Read_Only"),
                ("SofCare_Restorative","SofCare_Read_Only"),
                ("SofCare_RRD","SofCare_Read_Only") )
    foreach($role in $roles)
    {
        $change = CreateRoleChangeObject $role[0] $role[1]
        $roleChanges += $change
    }

    $updates = ProcessRoleChanges $facIds $roleChanges
    return $updates
}

function ProcessRoleChanges
#--------------------------
{
    param ($facIds, $roleChanges)

    $users = @()
    $changedRoles = @()
    $facs = @()
    foreach($fac in $facIds)
    {
        $f = ( (Get-ADObject -LDAPFilter "(&(entityid=$fac)(objectCategory=organizationalUnit))" -Properties url | Select-Object name, url) )
        $facs += $f
    }
    foreach($facility in $facs)
    {
        $n = $facility.name
        $u = get-aduser -Filter {(office -eq $n)} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
        $users += $u
    }
    foreach($user in $users)
    {
        #Check to see if user belongs to a facility with a future Go Live Date
        $processUser = $false
        $processUser = CheckFutureFacilities $user.memberof
        if($processUser -eq $true)
        {
            foreach($group in $user.memberof)
            {
                foreach($roleChange in $roleChanges)
                {
                    if ($group -like 'CN=' + $roleChange.RemoveGroup +'*')
                    {
                        #Remove user from group
                        $a = CreateActionObject $user.SamAccountName $user.GivenName $user.Surname $user.title $user.office "Removed from" $roleChange.RemoveGroup
                        $changedRoles += $a
                        Logger -string "Facility: $($user.office) User: $($user.Name) Removed from group: $($roleChange.RemoveGroup)"
                        #Remove-ADGroupMember -Identity $roleChange.RemoveGroup -Members $user.SamAccountName

                        #Add user to new group
                        if($roleChange.AddGroup -ne "")
                        {
                            $a = CreateActionObject $user.SamAccountName $user.GivenName $user.Surname $user.title $user.office "Added to" $roleChange.AddGroup
                            $changedRoles += $a
                            Logger -string "Facility: $($user.office) User: $($user.Name) Added to group: $($roleChange.AddGroup)"
                            #Add-ADGroupMember -Identity $roleChange.AddGroup -Members $user.SamAccountName
                        }
                        break
                    }
                }
            }
        }
        else
        {
            $a = CreateActionObject $user.SamAccountName $user.GivenName $user.Surname $user.title $user.office "Skipped, Member of facility with future Go Live Date" $otherFac
            $changedRoles += $a
            Logger -string "Facility: $($user.office) User: $($user.Name) Skipped, Member of facility with future Go Live Date"
        }   
    }
    return $changedRoles
}


function CreateRoleChangeObject()
#--------------------------------
{
    param ($removeGroup, $addGroup)
    
    $rObj = New-Object PSObject
    $rObj | Add-Member -type NoteProperty -Name RemoveGroup -Value $removeGroup
    $rObj | Add-Member -type NoteProperty -Name AddGroup -Value $addGroup

    return $rObj
}

function GetFacilities
#---------------------
{
    param ($goLiveDate)

    $dayBefore = $goLiveDate.AddDays(-1)
    $dayAfter =  $goLiveDate.AddDays(1)
    Connect-PnPOnline -Url http://lccavs/team/it/projects/ClinicalBillingSoftware -CurrentCredentials
    $filterField = "Clinical_x0020_Go_x0020_Live"
    $filterField2 = "Division"

    #$corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -eq $goLiveDate -and $_[$filterField2] -ne 'Century Park' } | ForEach-Object { $_["CorpID"] }
    $corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -gt $dayBefore -and [DateTime]$_[$filterField].date -lt $dayAfter -and $_[$filterField2] -ne 'Century Park' } | ForEach-Object { $_["CorpID"] }

    return $corpids
}

Function GetFutureFacilities
#---------------------------
{
    $futFacs = @()
    Connect-PnPOnline -Url http://lccavs/team/it/projects/ClinicalBillingSoftware -CurrentCredentials
    $filterField = "Clinical_x0020_Go_x0020_Live"
    $filterField2 = "Division"

    $corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -gt $CURRENTDATE -and $_[$filterField2] -ne 'Century Park' } | ForEach-Object { $_["CorpID"] }

    foreach($fac in $corpids)
    {
        $f = ( (Get-ADObject -LDAPFilter "(&(entityid=$fac)(objectCategory=organizationalUnit))" -Properties url | Select-Object name, url) )
        $futFacs += $f
    }
    return $futFacs
}

Function CheckFutureFacilities 
{
    param ($memberof)
    
    $ok = $true
    foreach($group in $memberof)
    {
        $searchGroup = $group.Substring(3,$group.IndexOf(',')-3)
        if($futureFacilities.name -contains $searchGroup)
        {
            $otherFac = $searchGroup
            $ok = $false
            break
        }
    }

    return $ok
}

Function Logger 
#--------------
# Function to log and output information
{
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $a = $CURRENTDATE
    $a = $a -replace "/", ""
    $a = $a -replace " ", ""
    $a = $a -replace ":", ""

    $filename = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Console\Logs\PCCgoLiveRoleChanges_" + $a + ".log"
    Add-Content -Path $filename -value $string
}

Function Invoke-SQL
#------------------
{
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

Function GetRunDate
#------------------
{
    $sqlcommand = "
	    SELECT	ValuePlainText 
	    FROM	[PCC].[ConfigurationSetting]
	    WHERE Application = 'PCCConsole' and Name = 'CustomDateTimeValue' and Environment = 'LCCA'"
        $dbitems = Invoke-SQL -dataSource "PSDB1XV" -database Mirth_Repository -sqlCommand $sqlcommand

    if($dbitems.ValuePlainText -eq [DBNull]::Value)
    {
        #Run date is current date
        $theDate=[DateTime]::today
    }
    else
    {
        #Run date is value from database (manual run)
        $theDate = [DateTime]$dbitems.ValuePlainText
    }

    return $theDate

}

#Start of Script
#---------------

#Get rundate from SQL
$CURRENTDATE = GetRunDate

$startDate =  (Get-Date).ToShortDateString()
$startTime = (Get-Date).ToLongTimeString()
$startMsg = "PCC Go Live Role Changes process started on " + $startDate + " at " + $startTime
Logger -string $startMsg

$otherFac = ""

$futureFacilities = @()
$futureFacilities = GetFutureFacilities

$updateList = @()
#Process role changes for Go-Live date
$u = ProcessRoleChangesGoLive
$updateList += $u

#Process role changes for 15 days after Go-Live date
$u = ProcessRoleChangesGoLive15
$updateList += $u

$a = $CURRENTDATE
$a = $a -replace "/", ""
$a = $a -replace " ", ""
$a = $a -replace ":", ""

$filename = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Console\Output\Task\ActiveDirectory\PCCRoleMapping\PCCgoLiveRoleChanges_" + $a + ".csv"

$updateList | export-csv -Path $filename

$endDate =  (Get-Date).ToShortDateString()
$endTime = (Get-Date).ToLongTimeString()
$endMsg = "PCC Go Live Role Changes process Ended on " + $endDate + " at " + $endTime
Logger -string $endMsg
