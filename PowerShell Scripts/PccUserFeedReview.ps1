Add-Type -AssemblyName System.IO.Compression.FileSystem

Function Main
{
# This Script will:
# •	provide a means to help with the bulk approval of PCC user feed
# •	
# •	

# Get list of PCC User Feed Runs
$userFeedRuns = Get-Runs

$firstDisplayed = 0
$totalRuns = ($userFeedRuns | measure).Count
Set-AppColors


Do
{
    #Clear-Host
    #$title = "PCC User Feed Review"
    #Display-AppHeader $title

    #Determine the 10 User Feed Runs to be displayed
    $kounter = 0
    $list = @()
    For ($i=$firstDisplayed; $i -lt $totalRuns ;$i++)
    {
        $kounter ++
        if ($kounter -ge 11)
        {
            break
        }
        $txt = $kounter.ToString() + ". " + $userFeedRuns[$i].LastWriteTime.ToString()
        $list += $txt

    }

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Select a Batch Run"
    $objForm.Size = New-Object System.Drawing.Size(300,350) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {$x=$objListBox.SelectedItem;$objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$global:x=-9;$objForm.Close()}})

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,270)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    #$OKButton.Add_Click({$global:x=$objListBox.SelectedItem;$objForm.Close()})
    $OKButton.Add_Click({$global:x=$objListBox.SelectedIndex;$objForm.Close()})
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(150,270)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$global:x=-9;$objForm.Close()})
    $objForm.Controls.Add($CancelButton)

    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(280,20) 
    $objLabel.Text = "Please select a Batch Run:"
    $objForm.Controls.Add($objLabel) 

    $objListBox = New-Object System.Windows.Forms.ListBox 
    $objListBox.Location = New-Object System.Drawing.Size(10,40) 
    $objListBox.Size = New-Object System.Drawing.Size(260,20) 
    $objListBox.Height = 200

    foreach($item in $userFeedRuns)
    {
            [void] $objListBox.Items.Add($item.LastWriteTime.ToString())
    }

    $objForm.Controls.Add($objListBox) 

    $objForm.Topmost = $True

    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()

    #echo "$x"
    if($x -eq -9)
    {
        break
    }
    else
    {
        LookAtBatch $userFeedRuns[$x].PSPath $userFeedRuns[$x].LastWriteTime $userFeedRuns[$x].Name
    }


} while ($selection -ne "Q")


}

Function LookAtBatch
{
    param ($filePath, $batch, $fileName)

    #Check for existance of local work folder (Create if needed)
    if( -not(Test-Path 'C:\PS\Output'))
    {
        if( -not(Test-Path 'C:\PS'))
        {
            md -Path 'C:\PS'
        }
        md -Path 'C:\PS\Output'
    }
    $workPath = "C:\PS\Output\" + (Get-ChildItem $filePath).BaseName
    if( -not(Test-Path $workPath))
    {
        md -Path $workPath
    }
    
    #Copy the zip file from the network location to local
    Copy-Item -Path $filePath -Destination $workPath
    Push-Location $workPath

    #Unzip local copy
    [System.IO.Compression.ZipFile]::ExtractToDirectory($workPath + "\" + $fileName, $workPath)

    #Display memu of CSV files
    $csvList = Get-ChildItem *.csv -Recurse | select Name, LastWriteTime, PSPath
    
    Clear-Host
    $title = "CSV files from $batch PCC User Feed"

    Do
    {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

        $objForm = New-Object System.Windows.Forms.Form 
        $objForm.Text = "CSV files from $batch PCC User Feed"
        $objForm.Size = New-Object System.Drawing.Size(300,350) 
        $objForm.StartPosition = "CenterScreen"

        $objForm.KeyPreview = $True
        $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
            {$x=$objListBox.SelectedItem;$objForm.Close()}})     
        $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
            {$global:x=-9;$objForm.Close()}})

        $OKButton = New-Object System.Windows.Forms.Button
        $OKButton.Location = New-Object System.Drawing.Size(75,270)
        $OKButton.Size = New-Object System.Drawing.Size(75,23)
        $OKButton.Text = "OK"
        #$OKButton.Add_Click({$global:x=$objListBox.SelectedItem;$objForm.Close()})
        $OKButton.Add_Click({$global:x=$objListBox.SelectedIndex;$objForm.Close()})
        $objForm.Controls.Add($OKButton)

        $CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Location = New-Object System.Drawing.Size(150,270)
        $CancelButton.Size = New-Object System.Drawing.Size(75,23)
        $CancelButton.Text = "Cancel"
        $CancelButton.Add_Click({$global:x=-9;$objForm.Close()})
        $objForm.Controls.Add($CancelButton)

        $objLabel = New-Object System.Windows.Forms.Label
        $objLabel.Location = New-Object System.Drawing.Size(10,20) 
        $objLabel.Size = New-Object System.Drawing.Size(280,20) 
        $objLabel.Text = "CSV files from $batch PCC User Feed:"
        $objForm.Controls.Add($objLabel) 

        $objListBox = New-Object System.Windows.Forms.ListBox 
        $objListBox.Location = New-Object System.Drawing.Size(10,40) 
        $objListBox.Size = New-Object System.Drawing.Size(260,20) 
        $objListBox.Height = 200

        foreach($item in $csvList)
        {
                [void] $objListBox.Items.Add($item.Name.Substring(24,($item.Name.Length-4)-24))
        }

        $objForm.Controls.Add($objListBox) 

        $objForm.Topmost = $True

        $objForm.Add_Shown({$objForm.Activate()})
        [void] $objForm.ShowDialog()

        #echo "$x"
        if($x -eq -9)
        {
            Pop-Location
            Remove-Item $workPath -Force  -Recurse -ErrorAction SilentlyContinue
            break
        }
        else
        {
            #Read and display csv file
            ViewCSV $csvList[$x].PSPath $csvList[$x].LastWriteTime $csvList[$x].Name
        }
        $objForm.Dispose()
    } while ($selection -ne "Q")
}

Function ViewCSV
{
    param ($filePath, $batch, $fileName)

    $csv = Import-Csv $filePath
    if($fileName.ToLower() -like '*batch_all_user*')
    {
        $dataList = @()
        foreach($user in $csv)
        {
            $userToFind = $user.ADUsername
            $u = Get-ADUser -Filter {SamAccountName -eq $userToFind }  -Properties entityID, mail, employeeid, memberof | Select Name, SamAccountName, Enabled

            $dataItem = CreateBatchAllUserObject $user $u.Enabled
            $dataList += $dataItem

        }        
        $dataList | ogv
    }
    elseif($fileName.ToLower() -like '*batch_approval_required_users*')
    {
        $dataList = @()
        foreach($user in $csv)
        {
            $userToFind = $user.ADUsername
            $u = Get-ADUser -Filter {SamAccountName -eq $userToFind }  -Properties entityID, mail, employeeid, memberof | Select Name, SamAccountName, Enabled

            $dataItem = CreateBatchApprovalRequiredUserObject $user $u.Enabled
            $dataList += $dataItem

        }        
        $dataList | ogv
    }
    else
    {
        $csv | ogv
    }
}

Function CreateBatchApprovalRequiredUserObject
{
    param ($user, $ADstatus)

    $recObj = New-Object PSObject
    $recObj | add-member -type NoteProperty -Name BatchIdentifier -Value $user.BatchIdentifier
    $recObj | Add-Member -type NoteProperty -Name FirstName -Value $user.FirstName
    $recObj | add-member -type NoteProperty -Name MiddleInitial -Value $user.MiddleInitial
    $recObj | add-member -type NoteProperty -Name LastName -Value $user.LastName
    $recObj | add-member -type NoteProperty -Name ADUsername -Value $user.ADUsername
    $recObj | add-member -type NoteProperty -Name Action -Value $user.Action
    $recObj | add-member -type NoteProperty -Name Status -Value $user.Status
    $recObj | add-member -type NoteProperty -Name Success -Value $user.Success
    $recObj | add-member -type NoteProperty -Name LoginName -Value $user.LoginName
    $recObj | add-member -type NoteProperty -Name LongUsername -Value $user.LongUsername
    $recObj | add-member -type NoteProperty -Name POCLoginName -Value $user.POCLoginName
    $recObj | add-member -type NoteProperty -Name EmailAddress -Value $user.EmailAddress
    $recObj | add-member -type NoteProperty -Name Password -Value $user.Password
    $recObj | add-member -type NoteProperty -Name POCPassword -Value $user.POCPassword
    $recObj | add-member -type NoteProperty -Name ForcePasswordExpiry -Value $user.ForcePasswordExpiry
    $recObj | add-member -type NoteProperty -Name ForcePOCPasswordExpiry -Value $user.ForcePOCPasswordExpiry
    $recObj | add-member -type NoteProperty -Name Initials -Value $user.Initials
    $recObj | add-member -type NoteProperty -Name Designation -Value $user.Designation
    $recObj | add-member -type NoteProperty -Name Position -Value $user.Position
    $recObj | add-member -type NoteProperty -Name ADP_JobTitle -Value $user.ADP_JobTitle
    $recObj | add-member -type NoteProperty -Name AD_Title -Value $user.AD_Title
    $recObj | add-member -type NoteProperty -Name CorporateUser -Value $user.CorporateUser
    $recObj | add-member -type NoteProperty -Name DivisionUser -Value $user.DivisionUser
    $recObj | add-member -type NoteProperty -Name RegionUser -Value $user.RegionUser
    $recObj | add-member -type NoteProperty -Name DefaultFacility -Value $user.DefaultFacility
    $recObj | add-member -type NoteProperty -Name ExternalFacilityId -Value $user.ExternalFacilityId
    $recObj | add-member -type NoteProperty -Name ExternalUserId -Value $user.ExternalUserId
    $recObj | add-member -type NoteProperty -Name PhysicalIdCode -Value $user.PhysicalIdCode
    $recObj | add-member -type NoteProperty -Name HasAllFacilities -Value $user.HasAllFacilities
    $recObj | add-member -type NoteProperty -Name HasAutoPageSetup -Value $user.HasAutoPageSetup
    $recObj | add-member -type NoteProperty -Name IsLoginDisabled -Value $user.IsLoginDisabled
    $recObj | add-member -type NoteProperty -Name IsRemoteUser -Value $user.IsRemoteUser
    $recObj | add-member -type NoteProperty -Name IsEnterpriseUser -Value $user.IsEnterpriseUser
    $recObj | add-member -type NoteProperty -Name MedicalProfessionalId -Value $user.MedicalProfessionalId
    $recObj | add-member -type NoteProperty -Name DefaultAdminTab -Value $user.DefaultAdminTab
    $recObj | add-member -type NoteProperty -Name DefaultClinicalTab -Value $user.DefaultClinicalTab
    $recObj | add-member -type NoteProperty -Name CanLoginToEnterprise -Value $user.CanLoginToEnterprise
    $recObj | add-member -type NoteProperty -Name CanLoginToIRM -Value $user.CanLoginToIRM
    $recObj | add-member -type NoteProperty -Name MaxFailedLogins -Value $user.MaxFailedLogins
    $recObj | add-member -type NoteProperty -Name PCCValidUntilDate -Value $user.PCCValidUntilDate
    $recObj | add-member -type NoteProperty -Name Facilities -Value $user.Facilities
    $recObj | add-member -type NoteProperty -Name Roles -Value $user.Roles
    $recObj | add-member -type NoteProperty -Name CollectionGroups -Value $user.CollectionGroups
    $recObj | add-member -type NoteProperty -Name Warnings -Value $user.Warnings
    $recObj | add-member -type NoteProperty -Name FieldChanges -Value $user.FieldChanges
    $recObj | add-member -type NoteProperty -Name Changes -Value $user.Changes
    $recObj | add-member -type NoteProperty -Name Reasons -Value $user.Reasons
    $recObj | add-member -type NoteProperty -Name Exceptions -Value $user.Exceptions
    $recObj | add-member -type NoteProperty -Name ADAccountStatus -Value ""
    if($ADstatus)
    {
        $recobj.ADAccountStatus = "Enabled"
    }
    else
    {
        $recobj.ADAccountStatus = "Disabled"
    }

    return $recObj
}

Function CreateBatchAllUserObject
{
    param ($user, $ADstatus)

    $recObj = New-Object PSObject
    $recObj | add-member -type NoteProperty -Name BatchIdentifier -Value $user.BatchIdentifier
    $recObj | Add-Member -type NoteProperty -Name FirstName -Value $user.FirstName
    $recObj | add-member -type NoteProperty -Name MiddleInitial -Value $user.MiddleInitial
    $recObj | add-member -type NoteProperty -Name LastName -Value $user.LastName
    $recObj | add-member -type NoteProperty -Name Action -Value $user.Action
    $recObj | add-member -type NoteProperty -Name Status -Value $user.Status
    $recObj | add-member -type NoteProperty -Name Success -Value $user.Success
    $recObj | add-member -type NoteProperty -Name LoginName -Value $user.LoginName
    $recObj | add-member -type NoteProperty -Name LongUsername -Value $user.LongUsername
    $recObj | add-member -type NoteProperty -Name POCLoginName -Value $user.POCLoginName
    $recObj | add-member -type NoteProperty -Name EmailAddress -Value $user.EmailAddress
    $recObj | add-member -type NoteProperty -Name Password -Value $user.Password
    $recObj | add-member -type NoteProperty -Name POCPassword -Value $user.POCPassword
    $recObj | add-member -type NoteProperty -Name ForcePasswordExpiry -Value $user.ForcePasswordExpiry
    $recObj | add-member -type NoteProperty -Name ForcePOCPasswordExpiry -Value $user.ForcePOCPasswordExpiry
    $recObj | add-member -type NoteProperty -Name Initials -Value $user.Initials
    $recObj | add-member -type NoteProperty -Name Designation -Value $user.Designation
    $recObj | add-member -type NoteProperty -Name Position -Value $user.Position
    $recObj | add-member -type NoteProperty -Name ADP_JobTitle -Value $user.ADP_JobTitle
    $recObj | add-member -type NoteProperty -Name AD_Title -Value $user.AD_Title
    $recObj | add-member -type NoteProperty -Name CorporateUser -Value $user.CorporateUser
    $recObj | add-member -type NoteProperty -Name DivisionUser -Value $user.DivisionUser
    $recObj | add-member -type NoteProperty -Name RegionUser -Value $user.RegionUser
    $recObj | add-member -type NoteProperty -Name DefaultFacility -Value $user.DefaultFacility
    $recObj | add-member -type NoteProperty -Name ExternalFacilityId -Value $user.ExternalFacilityId
    $recObj | add-member -type NoteProperty -Name ExternalUserId -Value $user.ExternalUserId
    $recObj | add-member -type NoteProperty -Name PhysicalIdCode -Value $user.PhysicalIdCode
    $recObj | add-member -type NoteProperty -Name HasAllFacilities -Value $user.HasAllFacilities
    $recObj | add-member -type NoteProperty -Name HasAutoPageSetup -Value $user.HasAutoPageSetup
    $recObj | add-member -type NoteProperty -Name IsLoginDisabled -Value $user.IsLoginDisabled
    $recObj | add-member -type NoteProperty -Name IsRemoteUser -Value $user.IsRemoteUser
    $recObj | add-member -type NoteProperty -Name IsEnterpriseUser -Value $user.IsEnterpriseUser
    $recObj | add-member -type NoteProperty -Name MedicalProfessionalId -Value $user.MedicalProfessionalId
    $recObj | add-member -type NoteProperty -Name DefaultAdminTab -Value $user.DefaultAdminTab
    $recObj | add-member -type NoteProperty -Name DefaultClinicalTab -Value $user.DefaultClinicalTab
    $recObj | add-member -type NoteProperty -Name CanLoginToEnterprise -Value $user.CanLoginToEnterprise
    $recObj | add-member -type NoteProperty -Name CanLoginToIRM -Value $user.CanLoginToIRM
    $recObj | add-member -type NoteProperty -Name MaxFailedLogins -Value $user.MaxFailedLogins
    $recObj | add-member -type NoteProperty -Name PCCValidUntilDate -Value $user.PCCValidUntilDate
    $recObj | add-member -type NoteProperty -Name Facilities -Value $user.Facilities
    $recObj | add-member -type NoteProperty -Name Roles -Value $user.Roles
    $recObj | add-member -type NoteProperty -Name CollectionGroups -Value $user.CollectionGroups
    $recObj | add-member -type NoteProperty -Name Warnings -Value $user.Warnings
    $recObj | add-member -type NoteProperty -Name FieldChanges -Value $user.FieldChanges
    $recObj | add-member -type NoteProperty -Name ChangesAdded -Value $user.ChangesAdded
    $recObj | add-member -type NoteProperty -Name ChangesRemoved -Value $user.ChangesRemoved
    $recObj | add-member -type NoteProperty -Name Reasons -Value $user.Reasons
    $recObj | add-member -type NoteProperty -Name Exceptions -Value $user.Exceptions
    $recObj | add-member -type NoteProperty -Name ADAccountStatus -Value ""
    if($ADstatus)
    {
        $recobj.ADAccountStatus = "Enabled"
    }
    else
    {
        $recobj.ADAccountStatus = "Disabled"
    }

    return $recObj
}


Function Get-Runs
{
    Try 
    {   
        Push-Location "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Output\LCCA"
    } 
    Catch 
    {
        Push-Location "\\fs3\edrive\MIRTH\conf\Files\PCC\Output\LCCA"
    }
    $RunList = Get-ChildItem *.zip -Recurse | Sort-Object -Property LastWriteTime -Descending| select Name, LastWriteTime, PSPath

    return $RunList
}

function Display-AppHeader ($title)
{
<#
    .SYNOPSIS
    Displays a title surrounded by *'s
    
    .DESCRIPTION
    Displays the passed in title, centered on the screen and
    surrounded by a nice frame.
    
    .PARAMETER title
    The title you want displayed
    
    .NOTES
    Required the Get-WindowWidth function.
#>

    # make sure a title was passed in and has a minimum length
    if ($title.Length -lt 2) {$title = $title + " "}
    
    $ww = (Get-WindowWidth) - 4 #2 for the *'s and 2 for a gap
    if (($title.Length % 2) -ne 0)
        {$title = $title + " "}
        
    $pad = " " * (($ww - $title.Length) / 2)
    
    "*" + "-" * $ww + "*"
    
    Write-Host -NoNewline "*"
    Write-Host -NoNewline $pad
    Write-Host -NoNewline -ForegroundColor "White" $title
    Write-Host -NoNewline $pad
    Write-Host "*"
    
    "*" + "-" * $ww + "*"
}


function Get-WindowWidth
{
<#
    .SYNOPSIS
    Returns the width of the current window.
    
    .DESCRIPTION
    If running in the ISE, the max windoes size will be null.  If so,
    retrun a default of 80.  Otherwise return the true window width.
#>
    If ($host.UI.RawUI.MaxWindowSize -eq $null)
    {
        $windowWidth = 80
    }
    else
    {
        $windowWidth = $host.UI.RawUI.MaxWindowSize.Width
    }
    return $windowWidth
}


function Set-AppColors
{
<#
    .SYNOPSIS
    Sets the application colors.
    
    .DESCRIPTION
    The function determines whether it's running in the ISE or a Window,
    Then sets the colors and window title appropriately.
#>
    if ($psise -eq $null)
    {
        $host.UI.RawUI.BackgroundColor = "Black"
        $host.UI.RawUI.ForegroundColor = "Green"
        $host.UI.RawUI.WindowTitle = "PCC User Feed Review Tool"
    }
    else
    {
        $psISE.Options.ConsolePaneBackgroundColor = "Black"
        #$psise.Options.OutputPaneBackgroundColor = "Black"
        $psISE.Options.ConsolePaneTextBackgroundColor = "Black"
        #$psise.Options.OutputPaneTextBackgroundColor = "Black"
        $psISE.Options.ConsolePaneTextBackgroundColor = "Black"
        #$psise.Options.OutputPaneForegroundColor = "#FF00e000"  # Lightish Green
        #$psISE.Options.OutputPaneTextForegroundColor = "#FF00e000"  # Lightish Green
        $psISE.Options.ConsolePaneForegroundColor  = "#FF00e000"  # Lightish Green
        $host.UI.RawUI.WindowTitle = "Putting it all together"
    }
}


# Script Begins Here - Execute Function Main


Main