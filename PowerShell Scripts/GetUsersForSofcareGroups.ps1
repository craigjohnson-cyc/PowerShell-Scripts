function CreatePersonObject()
{
    param ($SamAccountName, $fname, $lname, $mname, $title, $office, $groupName)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name ADgroup -Value $groupName
    $perObj | Add-Member -type NoteProperty -Name FirstName -Value $fname
    $perObj | Add-Member -type NoteProperty -Name MiddleName -Value $mname
    $perObj | Add-Member -type NoteProperty -Name LastName -Value $lname
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name JobTitle -Value $title
    $perObj | add-member -type NoteProperty -Name FacilityName -Value $office

    return $perObj
}

$SCgroup = @()
$missingGroups = @()
$groupMembers = @()

$SCgroup += "Clinical Administrator"
$SCgroup += "Clinical Debugger"
$SCgroup += "EMR Admin"
$SCgroup += "EMR Billing"
$SCgroup += "EMR Billing Admin"
$SCgroup += "EMR Labs"
$SCgroup += "EMR Physician"
$SCgroup += "EMR Read Only"
$SCgroup += "EMR_Billing_Coder"
$SCgroup += "EMR_CPOE"
$SCgroup += "EMR_Emergency_Access"
$SCgroup += "EMR_Pilot"
$SCgroup += "EMR_Visit_Notes"
$SCgroup += "RN Review"
$SCgroup += "SofCare_3rd_LevelSupport"
$SCgroup += "SofCare_672_802"
$SCgroup += "SofCare_Act"
$SCgroup += "SofCare_Admissions"
$SCgroup += "SofCare_BO"
$SCgroup += "SofCare_CareDirectives"
$SCgroup += "SofCare_Cert_Med_Aide"
$SCgroup += "SofCare_CL_Reg_Div"
$SCgroup += "SofCare_ClinicalSupport"
$SCgroup += "SofCare_Dashboard_read_only"
$SCgroup += "SofCare_Dashboard_read_print_only"
$SCgroup += "SofCare_Dietary"
$SCgroup += "SofCare_DON"
$SCgroup += "SofCare_DualCPLib"
$SCgroup += "SofCare_ED"
$SCgroup += "SofCare_Export_Admissions"
$SCgroup += "SofCare_FaceSheet"
$SCgroup += "SofCare_Field_Controller"
$SCgroup += "SofCare_HIM"
$SCgroup += "SofCare_Lab"
$SCgroup += "SofCare_Lab_Read_Only"
$SCgroup += "SofCare_Lab_Read_Print_only"
$SCgroup += "SofCare_LCPS"
$SCgroup += "SofCare_MDS"
$SCgroup += "SofCare_MDSCoord_RN"
$SCgroup += "SofCare_MedicareClaims"
$SCgroup += "SofCare_Nursing"
$SCgroup += "SofCare_Physician_Orders"
$SCgroup += "SofCare_Read_Only"
$SCgroup += "SofCare_Read_Only_Prog_Notes"
$SCgroup += "SofCare_ReadPrint_Only"
$SCgroup += "SofCare_Rehab"
$SCgroup += "SofCare_Reports_Only"
$SCgroup += "SofCare_Restorative"
$SCgroup += "SofCare_RRD"
$SCgroup += "SofCare_RSM"
$SCgroup += "SofCare_RUS"
$SCgroup += "SofCare_SS"
$SCgroup += "SofCare_Surveyor"
$SCgroup += "SofCare_TreatmentNurse"
$SCgroup += "SofCare_Weight_Entry"


foreach($group in $SCgroup)
{
    try
    {
        $u = Get-ADGroupMember -identity $group -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, middleName, givenname, SamAccountName, title, office, memberof
        foreach($user in $u)
        {
            $gName = $group
            $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.middlename $user.Title $user.office $gName
            $groupMembers += $personObj
        }
    }
    catch
    {
        $missingGroups += "$group not found in Active Directory"
    }
}


$groupMembers | export-csv -Path "C:\ps\Output\SofcareUsers.csv" -NoTypeInformation
#$missingGroups | export-csv -Path "C:\ps\Output\MissingADGroups.csv" -NoTypeInformation

$logFile = "C:\ps\Output\MissingADGroups.txt"
foreach($adGroup in $missingGroups)
{
    Add-Content $logFile -value $adGroup
}
