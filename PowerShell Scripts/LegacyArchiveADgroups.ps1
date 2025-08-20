# This Script will:
# •	Open and read an Excel spreadsheet from Teams
# •	For each row in the spreadsheet, 1) Add all users in the AD group named in Column A to the group named in Column B
# •                                  2) Remove all users from the AD group named in column A


# STEPS FOR EXECUTION
# 1) Create new CSV from Excel file kept in Teams
# 2) Place CSV in Input Location
# 3) Modify Line 26 with input path for CSV file
# 4) Modify Line 21 with output path for output CSV file
# 5) Modify Line 41 with path for log file

Function Main
{
    #Open and read the Excel spreadsheet
    #$operations = GetExcelData
    $operations = GetCSVdata

    $actions = ProcessOperations $operations
    $actions | export-csv -Path "C:\ps\Output\LegacyArchiveADgroups.csv" -NoTypeInformation
}

Function GetCSVdata
{
    $path = "c:\ps\input\"
    $file = $path + "SC2 Rehab AD Groups.csv"

    $csv = Import-Csv $file

    return $csv
}

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    Add-Content -Path C:\temp\LegacyArchiveADgroups.txt -value $string
}


Function ProcessOperations
{
    param ($operations)

    $actions = @()

    foreach($operation in $operations)
    {
        #Check the status column to see if this operation has already been done
        if($operation.Completed.ToString().Trim().Length -gt 0)
        {
            if($operation.Completed -like "*HIM*")
            {
                 $userActions = MoveHIMDusers $operation."changes needed (Add to)" $operation."sc2 Rehab AD groups (remove from)" "HIMD"
                 $actions += $userActions
            }
        }
        else
        {
            #Process Row
            $userActions = MoveUsers $operation."changes needed (Add to)" $operation."sc2 Rehab AD groups (remove from)" ""
            $actions += $userActions
        }
    }
    return $actions
}

Function MoveHIMDusers
{
    param ($addGroup, $removeGroup, $himd)

    Logger -color "green" -string "Processing users in $removeGroup $addGroup"
    #Get all users in the remove group
    #$users = Get-ADGroupMember -identity $removeGroup -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title | Select surname, givenname, title, SamAccountName
    $users = (Get-ADGroup -Identity Rehab_Facility_Read_Only -Properties members).members
    #Get all users in the HIMD group
    $HIMDusers = Get-ADGroupMember -identity $himd -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title | Select surname, givenname, title, SamAccountName
    $addGroup = "SC2_Rehab2_Archive"

    #foreach user in the HIMD group, add to SC2_Rehab2_Archive
    foreach($user in $HIMDusers)
    {
         $fname = $user.givenname 
         $lname = $user.surname 
         $userName = $user.samAccountName
         $userAction = CreateActionObj $fname $lname $userName $addGroup ""
         $userActions += $userAction
         Logger -color "green" -string "     Adding user $fname $lname - $userName to group $addGroup"
         Add-ADGroupMember -Identity $addGroup -Members $user.samAccountName

    }
    #foreach user in the $removeGroup, remove from group
    foreach($user in $users)
    {
        $userInfo = Get-ADUser $user
        $fname = $userInfo.givenname 
        $lname = $userInfo.surname 
        $userName = $userInfo.samAccountName
        $userAction = CreateActionObj $fname $lname $userName "" $removeGroup
        $userActions += $userAction

        Logger -color "green" -string "     Removing user $fullname - $userName from group $removeGroup"
        Remove-ADGroupMember -Identity $removeGroup -Members $userName  -Confirm:$false
    }
    return $userActions
}


Function MoveUsers
{
    param ($addGroup, $removeGroup, $himd)

    Logger -color "green" -string "Processing users in $removeGroup $addGroup"


    #Get all users in the remove group
    if($himd.trim().length -gt 0)
    {
         $users = Get-ADGroupMember -identity $himd -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title | Select surname, givenname, title, SamAccountName
         $addGroup = "SC2_Rehab2_Archive"
    }
    else
    {
         $users = Get-ADGroupMember -identity $removeGroup -Recursive | Get-ADUser  -Properties entityID, employeeid, description, title | Select surname, givenname, title, SamAccountName
    }
    $userActions = @()

    #foreach user, add to add group
    foreach($user in $users)
    {
         $fname = $user.givenname 
         $lname = $user.surname 
         $userName = $user.samAccountName
         $userAction = CreateActionObj $fname $lname $userName $addGroup $removeGroup
         $userActions += $userAction

         #Determine if users are to be added to a group
         if($addGroup -liKE "*remove*")
         {
              continue
         }
         else
         {
              Logger -color "green" -string "     Adding user $fname $lname - $userName to group $addGroup"
              Add-ADGroupMember -Identity $addGroup -Members $user.samAccountName
         }
    }
    #foreach user, remove from group
    foreach($user in $users)
    {
        $fname = $user.givenname 
        $lname = $user.surname 
        $userName = $user.samAccountName

        Logger -color "green" -string "     Removing user $fname $lname - $userName from group $removeGroup"
        Remove-ADGroupMember -Identity $removeGroup -Members $userName  -Confirm:$false
    }
    return $userActions
}

Function CreateActionObj
{
     param ($fname, $lname, $userName, $addGroup, $removeGroup)

     $userObj = New-Object PSObject
     $fullName = $fname + " " + $lname
     $userObj | Add-Member -type NoteProperty -Name Name -Value $fullName
     $userObj | add-member -type NoteProperty -Name UserId -Value $userName
     $userObj | add-member -type NoteProperty -Name RemovedFrom -Value $removeGroup
     $userObj | add-member -type NoteProperty -Name AddedTo -Value $addGroup

     if($addGroup -like "*remove*")
     {
         $userObj.AddedTo = ""
     }

     return $userObj
}

Function GetExcelData
{
    # This address received when clicking Open in SharePoint - seems to need the file name appended
    $sharePoint = "https://lcca.sharepoint.com/sites/Project-LegacyArchive/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FProject%2DLegacyArchive%2FShared%20Documents%2FRehab2&FolderCTID=0x012000900A929D341E974193CCA4EC7D05577D\"

    # This address received when clicking Get Link and choosing the SharePoint URL option - Seems to be a direct link to the file, no need to append filename
    $sharePoint = "https://lcca.sharepoint.com/sites/Project-LegacyArchive/_layouts/15/Doc.aspx?OR=teams&action=edit&sourcedoc={025589EB-8B11-438E-8EFF-7AC281FFE646}"

    # This address received when clicking Get Link and choosing the Microsoft Teams URL
    $path = "https://teams.microsoft.com/l/file/025589EB-8B11-438E-8EFF-7AC281FFE646?tenantId=64e6d96e-50d7-4a22-ba04-f47cd801b006&fileType=xlsx&objectUrl=https%3A%2F%2Flcca.sharepoint.com%2Fsites%2FProject-LegacyArchive%2FShared%20Documents%2FRehab2%2FSC2%20Rehab%20AD%20Groups.xlsx&baseUrl=https%3A%2F%2Flcca.sharepoint.com%2Fsites%2FProject-LegacyArchive&serviceName=teams&threadId=19:187c0b25e603465ea8579c7ae6be58a3@thread.skype&groupId=1c7663fd-ef6a-4e26-b481-69590eaf6aa7\"
    #$path = "C:\Temp\"
    
    $fileName = "SC2 Rehab AD Groups.xlsx"

    $outPath = "C:\Temp\_"
    $sharePointFile = $sharePoint + $fileName
    $outFile = $outPath + $fileName

    $user = "craig_johnson@lcca.com"
    $pw = Read-Host "Enter Password" -AsSecureString
    $domain = "LCCA"

    #Download Files
    $WebClient = New-Object System.Net.WebClient
    $WebClient.Credentials = New-Object System.Net.Networkcredential($User, $pw, $domain)
    #$WebClient.DownloadFile($sharePointFile, $outFile)
    $WebClient.DownloadFile($sharePoint, $outFile)

    $excel = new-object -com excel.application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false


    #$wb = $excel.workbooks.open("https://teams.microsoft.com/l/file/025589EB-8B11-438E-8EFF-7AC281FFE646?tenantId=64e6d96e-50d7-4a22-ba04-f47cd801b006&fileType=xlsx&objectUrl=https%3A%2F%2Flcca.sharepoint.com%2Fsites%2FProject-LegacyArchive%2FShared%20Documents%2FRehab2%2FSC2%20Rehab%20AD%20Groups.xlsx&baseUrl=https%3A%2F%2Flcca.sharepoint.com%2Fsites%2FProject-LegacyArchive&serviceName=teams&threadId=19:187c0b25e603465ea8579c7ae6be58a3@thread.skype&groupId=1c7663fd-ef6a-4e26-b481-69590eaf6aa7")
    $wb = $excel.workbooks.open($path + $fileName)

    $sh = $wb.Sheets.Item(1)
    #$endRow = $sh.UsedRange.SpecialCells($xlCellTypeLastCell).Row
    $endRow = 33
    $col = $col + $i - 1

    #Get groups to remove users from
    $rangeAddress = $sh.Cells.Item(2, 1).Address() + ":" + $sh.Cells.Item($endRow, 1).Address()
    $oldGroups = $sh.Range($rangeAddress).Value2 | foreach{
            New-Object PSObject -Property @{OldGroup=$_}
        }

    #Get groups to add users to
    $rangeAddress = $sh.Cells.Item(2, 2).Address() + ":" + $sh.Cells.Item($endRow, 2).Address()
    $newGroups = $sh.Range($rangeAddress).Value2 | foreach{
            New-Object PSObject -Property @{newGroup=$_}
        }

    #Get current action status
    $rangeAddress = $sh.Cells.Item(2, 4).Address() + ":" + $sh.Cells.Item($endRow, 4).Address()
    $status = $sh.Range($rangeAddress).Value2 | foreach{
            New-Object PSObject -Property @{status=$_}
        }

    $actions = BuildActionObject $oldGroups $newGroups $status

    return $actions
}


Function BuildActionObject
{
    param ($oldGroups, $newGroups, $status)

    $actions = @()
    for($i=0; $i -lt $oldGroups.Length; $i++)
    {
        $actionObj = New-Object PSObject

        $actionObj | Add-Member -type NoteProperty -Name oldGroup -Value $oldGroups[$i].oldGroup
        $actionObj | Add-Member -type NoteProperty -Name newGroup -Value $newGroups[$i].newGroup
        $actionObj | Add-Member -type NoteProperty -Name status -Value $status[$i].status

        $actions += $actionObj
    }

    return $actions
}



# Script begins here:  Execute Function Main
Main