Function Main
{
    $path = "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Output\LCCA\LCCA_PCC_*_Batch_Approval_Required_Users.csv"
    $fileInfo = gci $path | sort LastWriteTime | select -last 1
    $file = $fileInfo.Name

    ViewCSV $fileInfo.FullName
}


Function ViewCSV
{
    param ($file)

    $csv = Import-Csv $file
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

Main