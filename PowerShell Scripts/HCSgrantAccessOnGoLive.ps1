#HCSgrantAccessOnGoLive

Function Main
{
# This Script will:
# •	Read the Go Live dates from the SharePoint site:
#   http://lccavs/team/it/projects/HealthcareSource/Lists/Deployment%20List/Deployment%20Status.aspx
# •	When a facility is X days prior to Go Live, Add that facility to the HCS_Implimentation group
    
    $CURRENTDATE=[DateTime]::today
    
    # Testing - the following line is for testing purposes, remove for production
    $CURRENTDATE = Get-Date "05/30/2019"
    #----------------------------------------------------------------------------
    
    
    #Get a list of CorpID's of LCCA facilities going live
    $corpIdsLCCA = GetFacilitiesLCCA

    #Get a list of CorpId's of CP facilities goign live
    $corpIdsCP = GetFacilitiesCP

    $updates = @()
    $updates += ProcessFacilities $corpIdsLCCA "HCS_Implementation"

    $updates += ProcessFacilities $corpIdsCP "HCS_CP_Implementation"

    $a = $CURRENTDATE
    $a = $a -replace "/", ""
    $a = $a -replace " ", ""
    $a = $a -replace ":", ""

    TODO:  Get with Andy for folder to save files
    $filePath = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Console\Output\Task\ActiveDirectory\PCCRoleMapping\"
    $filename = "PCC_OE_Implementation_" + $a + ".csv"

    # Testing = The following line is for testing purposes, remove for production
    $filePath = "c:\ps\output\"
    $filename = "HCS_Implementation_" + $a + ".csv"
    #----------------------------------------------------------------------------
     
    $outputFile = $filePath + $filename

    $updates | export-csv -Path $outputFile -NoTypeInformation

    # Send email
    if ((Get-Item $outputFile).length -gt 0kb) 
    {
        $body = "The attached file lists facilities that have been added to the HCS_Implementation or the HCS_CP_Implementation based their ATS User Load Date on the Healthcare Source Deployment List"
        $body += "<br><br>"

        #Production 
        #Send-MailMessage -BodyAsHtml $body -From "<HCS_UAPSupport@lcca.com>" -Subject "HCS Rollout - Facilities added to Implementation Group" -SmtpServer lccarelay.lcca.net `
        #   -To "Healthcare Source Support <HCS_UAPSupport@lcca.com>" `
        #   -attachment $outputFile
        #-----------------------------------------------------------------------------------------

        #Testing
        Send-MailMessage -BodyAsHtml $body -From "<HCS_UAPSupport@lcca.com>" -Subject "TEST - HCS Rollout - Facilities added to Implementation Group - TEST" -SmtpServer lccarelay.lcca.net `
           -To "Healthcare Source Support <HCS_UAPSupport@lcca.com>" `
           -attachment $outputFile
        #-----------------------------------------------------------------------------------------
    }





}

Function GetFacilitiesLCCA
#---------------------------
{
    $lccaFacs = @()
    Connect-PnPOnline -Url http://lccavs/team/it/projects/HealthcareSource -CurrentCredentials
    $filterField = "ATS_x0020_User_x0020_Load_x0020_"
    $filterField2 = "Division"

    $corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -eq $CURRENTDATE.Date -and $_[$filterField2] -ne 'Century Park' } | ForEach-Object { $_["CorpID"] }

    foreach($fac in $corpids)
    {
        $f = ( (Get-ADObject -LDAPFilter "(&(entityid=$fac)(objectCategory=organizationalUnit))" -Properties url | Select-Object name, url) )
        $lccaFacs += $f
    }
    return $lccaFacs
}

Function GetFacilitiesCP
#---------------------------
{
    $cpFacs = @()
    Connect-PnPOnline -Url http://lccavs/team/it/projects/HealthcareSource -CurrentCredentials
    $filterField = "ATS_x0020_User_x0020_Load_x0020_"
    $filterField2 = "Division"

    $corpids = Get-PnPListItem "Deployment List" | Select-Object -ExpandProperty fieldvalues | Where-Object { $_[$filterField] -ne $null -and [DateTime]$_[$filterField].date -eq $CURRENTDATE.Date -and $_[$filterField2] -eq 'Century Park' } | ForEach-Object { $_["CorpID"] }

    foreach($fac in $corpids)
    {
        $f = ( (Get-ADObject -LDAPFilter "(&(entityid=$fac)(objectCategory=organizationalUnit))" -Properties url | Select-Object name, url) )
        $cpFacs += $f
    }
    return $cpFacs
}


function ProcessFacilities()
#--------------------------------
{
    param ($facs, $addGroup)
    
    $updateList = @()
    foreach ($fac in $facs)
    {
        $a = CreateActionObject $fac.Name "Added to $addGroup"
        $updateList += $a
        Add-ADGroupMember -Identity $addGroup -Members $fac.name
    }
    return $updateList
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


# Script Begins Here - Execute Function Main
Main