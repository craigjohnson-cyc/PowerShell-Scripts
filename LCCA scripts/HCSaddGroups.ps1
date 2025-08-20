Function LogWrite
{
    Param ([string]$logMsg)

    Add-Content $logFile -value $logMsg
}

# Read CSV
$csv = Import-Csv "\\pes1\esss\Craig\Josh\HCS Users.csv"
$logFile = "C:\ps\OutPut\HCSaddGroups.log"


# For each user (column C) add to groups in Col A and Col B
foreach($item in $csv)
{
    $groupToAdd = $item.Group.Trim()
    $roleToAdd = $item.Role.Trim()
    $userId = $item.ExternalID

    try
    {
        LogWrite "Adding group $groupToAdd to user $userId"
        Add-ADGroupMember -Identity $groupToAdd -Members $userId
    }
    catch
    {
        LogWrite "   ** Unable to add group [ $groupToAdd ] to user [ $userId ] Exception: $_.Exception.Message"
    }
    
    
    try
    {
        LogWrite "Adding group $roleToAdd to user $userId"
        Add-ADGroupMember -Identity $roleToAdd -Members $userId
    }
    catch
    {
        LogWrite "   ** Unable to add group [ $roleToAdd ] to user [ $userId ] Exception: $_.Exception.Message"
    }
}