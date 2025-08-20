Function LogWrite
{
    Param ([string]$logMsg)

    Add-Content $logFile -value $logMsg
}

# Script begins here
#-------------------

# Read CSV
$csv = Import-Csv "\\pes1\esss\Craig\HCS Role Changes\CP Descriptions and HCS Groups - updated.csv"
$runDate = (Get-Date).ToString("MM-dd-yyyy-hh-mm")
$logFile = "C:\ps\OutPut\HCS_CPUpdateRoles-" + $runDate + ".log"


# For each user if the AD Description = column C (ADDescription) 
# add to groups/roles in Col D (ADGroup) and Col F (ADRole)
foreach($item in $csv)
{
    $groupToAdd = $item.ADGroup.Trim()
    $roleToAdd = $item.ADRole.Trim()
    $description = $item.ADDescription.Trim()

    #Ignore record if Description is blank
    if($description.Trim() -eq "")
    {
        continue
    }
    LogWrite ""
    LogWrite "Processing users with AD Description: $description"


    # Get list of users with this AD Description
    $users = Get-ADUser  -Filter {(description -eq $description)} -Properties entityID, employeeid, description, title, physicalDeliveryOfficeName | Select surname, givenname, title, physicalDeliveryOfficeName,description,SamAccountName
    $kount = $users.Count
    LogWrite "   Users found: $kount"
    LogWrite ""

    foreach($user in $users)
    {
        $userId = $user.SamAccountName
        try
        {
            LogWrite "     Adding group $groupToAdd to user $userId"
            Add-ADGroupMember -Identity $groupToAdd -Members $userId
        }
        catch
        {
            LogWrite "        ** Unable to add group [ $groupToAdd ] to user [ $userId ] Exception: $_.Exception.Message"
        }
    
    
        try
        {
            LogWrite "     Adding group $roleToAdd to user $userId"
            Add-ADGroupMember -Identity $roleToAdd -Members $userId
        }
        catch
        {
            LogWrite "        ** Unable to add group [ $roleToAdd ] to user [ $userId ] Exception: $_.Exception.Message"
        }
    }

}
#send log file in email
$body = "The attached file lists accounts that were identified, based on AD Description, to have HCS Roles and/or Groups updated"
Send-MailMessage -BodyAsHtml $body -From "Johnson, Craig <craig_johnson@lcca.com>" -Subject "HCS Update Role/Group" -SmtpServer lccarelay.lcca.net `
        -To "Johnson, Craig <craig_johnson@lcca.com>", `
            "Parks, Brittany <Brittany_Parks@lcca.com>", `
            "Powell, Sarah <Sarah_Powell@lcca.com>", `
            "Pullen, DeeAnn <DeeAnn_Pullen@lcca.com>" `
    -attachment $logFile
#Send-MailMessage -BodyAsHtml $body -From "Johnson, Craig <craig_johnson@lcca.com>" -Subject "HCS Update Role/Group" -SmtpServer lccarelay.lcca.net `
#        -To "Johnson, Craig <craig_johnson@lcca.com>" `
#    -attachment $logFile
