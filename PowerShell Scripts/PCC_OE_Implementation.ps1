Import-Module SharePointPnPPowerShell2013
Import-Module ActiveDirectory


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

    $filename = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Console\Logs\PCC_OE_Implementation_" + $a + ".log"
    Add-Content -Path $filename -value $string
}

function CreateActionObject()
#----------------------------
{
    param ($office, $action)
    
    $perObj = New-Object PSObject
    $perObj | add-member -type NoteProperty -Name FacilityName -Value $office
    $perObj | add-member -type NoteProperty -Name Action -Value $action

    return $perObj
}


#Start of Script
#---------------
$startDate =  (Get-Date).ToShortDateString()
$startTime = (Get-Date).ToLongTimeString()
$startMsg = "PCC Order Entry Implementation process started on " + $startDate + " at " + $startTime
Logger -string $startMsg


$updateList = @()
#Get the first and last dates for the previous month
$CURRENTDATE=[DateTime]::today.AddMonths(-1)
$FIRSTDAYOFMONTH=GET-DATE $CURRENTDATE -Day 1

$LASTDAYOFMONTH=GET-DATE $FIRSTDAYOFMONTH.AddMonths(1).AddSeconds(-1)

#Connect to SharePoint site, the account that runs this task will need permission to access the Sharepoint site
Connect-PnPOnline -Url http://lccavs/team/it/projects/ClinicalBillingSoftware -CurrentCredentials
$filterField = "Clinical_x0020_Go_x0020_Live"
$filterField2 = "Division"

$corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -ge $FIRSTDAYOFMONTH -and [DateTime]$_[$filterField].date -le $LASTDAYOFMONTH -and $_[$filterField2] -ne 'Century Park' } | ForEach-Object { $_["CorpID"] }


#For every faciltiy returned from the sharepoint list search AD using the corpid and return the name and url (aka: facility subnet)
$facs = New-Object System.Collections.ArrayList 
foreach ($corp in $corpids) 
{
    [void]$facs.Add( (Get-ADObject -LDAPFilter "(&(entityid=$corp)(objectCategory=organizationalUnit))" -Properties url | Select-Object name, url) )
    Logger -string "Facility Found: $($facs[-1].name)"
}
$facs
foreach ($fac in $facs)
{
    $a = CreateActionObject $fac.Name "Added to PCC_OE_Implementation group"
    $updateList += $a
    Add-ADGroupMember -Identity PCC_OE_Implementation -Members $fac.name
}

$a = $CURRENTDATE
$a = $a -replace "/", ""
$a = $a -replace " ", ""
$a = $a -replace ":", ""

$filename = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Console\Output\Task\ActiveDirectory\PCCRoleMapping\PCC_OE_Implementation_" + $a + ".csv"

$updateList | export-csv -Path $filename

$endDate =  (Get-Date).ToShortDateString()
$endTime = (Get-Date).ToLongTimeString()
$endMsg = "PCC Order Entry Implementation process Ended on " + $endDate + " at " + $endTime
Logger -string $endMsg
