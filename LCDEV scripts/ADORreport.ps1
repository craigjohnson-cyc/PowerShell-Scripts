#--------------------------------------------------
# This script is to creaet a report by Division
# of ADOR's who have rempte access.
#--------------------------------------------------

Import-Module activedirectory
Add-PSSnapin Microsoft.Exchange.Management.Powershell.Admin -erroraction silentlyContinue
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
Clear-Host

function CreateReportFile()
{
    param ($associateList, $file, $location, $extension)

    $DivList = $associateList | Sort-Object Name
    $filename = $location + $file + $extension
    $DivList | export-csv -Path $filename
    return $filename
}

function InJobCodeList()
{
    param ($intEmployeeId)
    
    foreach($EmployeeId in $adorList)
    {
        $MidEmployeeId = [int]$EmployeeId.emplid
        #if ($MidEmployeeId -eq $person.EmployeeId)
        #if ($MidEmployeeId = $person.EmployeeId)
        if ($MidEmployeeId -eq $intEmployeeId)
        {
            return $true
            break
        }
    }
    return $false
}

function CreatePersonObject()
{
    param ($SamAccountName, $employeeId, $name, $parent, $title)
    
    $test = $parent
    $test = $test.replace("LDAP://", "")
    $test = $test.Substring(0,$test.indexOf(",DC"))
    $test = $test.Replace("OU=","")

    $ous = $test.split(",",3)

    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name EmployeeId -Value $employeeId
    $perObj | add-member -type NoteProperty -Name Division -Value $ous[2]
    $perObj | add-member -type NoteProperty -Name Region -Value $ous[1]
    $perObj | Add-Member -type NoteProperty -Name Facility -Value $ous[0]
    $perObj | Add-Member -type NoteProperty -Name Title -Value $title

    return $perObj
}


function SendEmail
{
    param ($centralFile, $easternFile, $gulfStatesFile, $mountainStatesFile, $northEastFile, $northWestFile, $southEastFile, $southWestFile)


    $smtpServer = "lccarelay.lcca.net"
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    
    $msg.From = "Rehab_Reports_Distribution@lcca.com "
    
    $msg.To.Add("Rehab_Reports_Distribution@lcca.com ")
    $msg.Subject = "ADORs with Remote Access"
    $msg.Body = "Please see attached file of ADORs with remote access."


    $att = new-object Net.Mail.Attachment($centralFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($easternFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($gulfStatesFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($mountainStatesFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($northEastFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($northWestFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($southEastFile)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($southWestFile)
    $msg.Attachments.Add($att)


    $smtp.Send($msg)
    $att.Dispose()
}

#----------------
# START OF SCRIPT
#----------------

$reportLocation = "c:/ps/"
$reportExtension = ".csv"

# Get a list of ADOR associates from the MID databasee
#-----------------------------------------------------
#$ServerInstance = "tbddb1x\"  #Dev
$ServerInstance = "bddb1v\"  #Prod
$Database = "MID"
$query = "SELECT emplid from [ADP].[Employee_Demographics] where jobcode in ('62105', '62104', '62904', '62905', '62702') and AL_EMPL_STATUS = 'A'"

$adorList = Invoke-SqlCmd -Query $query -ServerInstance "$ServerInstance" -Database "$Database" 
$adorList  | export-csv -Path "C:\ps\MIdData.csv"

# Get members of the AD group CAG_LCCA
#-------------------------------------
#$groupMembersList = Get-ADGroupMember -identity "CAG LCCA" -Recursive | Get-ADUser -Property DisplayName, EmployeeId | Select Name,ObjectClass,DisplayName,EmployeeId,samAccountName
$groupMembersList = Get-ADGroupMember -identity "CAG LCCA" -Recursive | Get-ADUser -Property DisplayName, EmployeeId, Title | Select Name,ObjectClass,DisplayName,EmployeeId,samAccountName,GivenName, Surname, UserPrincipalName, Enabled, mail, Title, DistinguishedName, Description |
        select *,@{l='Parent';e={(New-Object 'System.DirectoryServices.directoryEntry' "LDAP://$($_.DistinguishedName)").Parent}}


# Remove unwanted AD records
#---------------------------
$groupMembers = @()
foreach($member in $groupMembersList)
{
    $found = $true
    if ($member.EmployeeId -like '*Kellett*')
    {
        $found = $false
    }
    If ($member.EmployeeId -like '')
    {
        $found = $false
    }
    if (!$member.Enabled)
    {
        $found = $false
    }
    
    
    if ($found)
    {
        $groupMembers += $member
    }
}

$groupMembers | export-csv -Path "C:\ps\ADdata.csv"

# Find the members of the ADOR list that exist in the CAG LCCA group
#-------------------------------------------------------------------
$adors = @()

# Create the adors collection.  This is a collection of associates
# that are included in both the adorList (Associates with job codes
# ('62105', '62104', '62904', '62905', '62702', '61102') ) and the 
# groupMembers collection, which are associates who are members
# of the AD group CAG LCCA.  Associates who are in both collections
# are those hourly associates with remote access.
#------------------------------------------------------------------
foreach($person in $groupMembers)
{
    $personEmployeeId = [int]$person.EmployeeId

    $recFound = InJobCodeList $personEmployeeId

    if($recFound)
    {
        $personObj = CreatePersonObject $person.SamAccountName $person.EmployeeId $person.Name $person.Parent $person.Title
        $adors += $personObj
    }
}
#$adors.count
#$adors  | export-csv -Path "C:\ps\Adors.csv"

# Sort array by Division then by Facility
$centralDiv = @()
$easternDiv = @()
$gulfStatesDiv = @()
$mountainStatesDiv = @()
$northEastDiv = @()
$northWestDiv = @()
$southEastDiv = @()
$southWestDiv = @()
$unknownDiv = @()

foreach ($ador in $adors)
{
    switch ($ador.Division)
    {
        "Central Division" {$centralDiv += $ador}
        "Eastern Division" {$easternDiv += $ador}
        "Gulf States Division" {$gulfStatesDiv += $ador}
        "Mountain States Division" {$mountainStatesDiv += $ador}
        "Northeast Division" {$northEastDiv += $ador}
        "Northwest Division" {$northWestDiv += $ador}
        "Southeast Division" {$southEastDiv += $ador}
        "Southwest Division" {$southWestDiv += $ador}
    }
}

$centralFile = CreateReportFile $centralDiv 'CentralDiv' $reportLocation $reportExtension
$easternFile = CreateReportFile $easternDiv "EasternDiv" $reportLocation $reportExtension
$gulfStatesFile = CreateReportFile $gulfStatesDiv "GulfStatesDiv" $reportLocation $reportExtension
$mountainStatesFile = CreateReportFile $mountainStatesDiv "MountainStatesDiv"  $reportLocation $reportExtension
$northEastFile = CreateReportFile $northEastDiv "NorthEastDiv" $reportLocation $reportExtension
$northWestFile = CreateReportFile $northWestDiv "NorthWestDiv" $reportLocation $reportExtension
$southEastFile = CreateReportFile $southEastDiv "SouthEastDiv" $reportLocation $reportExtension
$southWestFile = CreateReportFile $southWestDiv "SouthWestDiv" $reportLocation $reportExtension


# Produce and mail report
SendEmail $centralFile $easternFile $gulfStatesFile $mountainStatesFile $northEastFile $northWestFile $southEastFile $southWestFile