# This Script will:
# •	Create a listing of users in groups with names containing "IDA"

Function Main
{
    #Get list of groups with IDA in the group name
    $groups = get-adgroup -Filter {name -like "*IDA*"} -Properties * | select name 

    $userList = @()
    foreach($group in $groups)
    {
         #Skip groups that contain IDA but are not IDA groups
         if($group.name.ToLower() -like '*florida*') {continue}
         if($group.name.ToLower() -like '*idaho*') {continue}
         if($group.name.ToLower() -like '*SofCare2_DataValidationRpt*') {continue}
         if($group.name.ToLower() -like '*TASRAIDAlerts*') {continue}

         $gname = $group.name
         $userActions = ProcessGroup $gname
         $userList += $userActions
    }
    $userList | export-csv -Path "C:\ps\Output\IDA_LegacyArchiveADgroups.csv" -NoTypeInformation

}

Function ProcessGroup
{
     param ($groupName)

     $actions = @()
     $users = Get-ADGroupMember -identity $groupName -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title,physicalDeliveryOfficeName,DisplayName | Select surname, givenname, title, SamAccountName,physicalDeliveryOfficeName,DisplayName

     foreach($user in $users)
     {
          $userObj = CreateActionObj $groupName $user.physicalDeliveryOfficeName $user.DisplayName $user.SamAccountName $user.title
          $actions += $userObj
     }
     return $actions
}

Function CreateActionObj
{
     param ($groupName, $location, $name, $userName, $title)

     $userObj = New-Object PSObject
     $userObj | Add-Member -type NoteProperty -Name ADgroup -Value $groupName
     $userObj | Add-Member -type NoteProperty -Name Name -Value $name
     $userObj | add-member -type NoteProperty -Name UserId -Value $userName
     $userObj | add-member -type NoteProperty -Name Location -Value $location
     $userObj | add-member -type NoteProperty -Name Title -Value $title

     return $userObj
}

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    Add-Content -Path C:\temp\IDA_LegacyArchiveADgroups.log -value $string
}




# Script begins here:  Execute Function Main
Main