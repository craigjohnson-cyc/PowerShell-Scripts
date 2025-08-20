function CreatePersonObject()
{
    param ($SamAccountName, $fname, $lname, $title, $office)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name FirstName -Value $fname
    $perObj | Add-Member -type NoteProperty -Name LastName -Value $lname
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name JobTitle -Value $title
    $perObj | add-member -type NoteProperty -Name FacilityName -Value $office

    return $perObj
}

$pccTherapist = @()
$nonPccTherapist = @()
$users = @()
#$users = Get-ADUser -Filter {Title -like '*Therapist*'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof

$u = Get-ADUser -Filter {Title -eq 'Certified Occupational Therapy Assistant'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Certified Occupational Therapy Assistant – Student'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Licensed Physical Therapist Assistant'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Licensed Physical Therapist Assistant – Student'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Occupational Therapist'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Occupational Therapist - Student'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Physical Therapist'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Physical Therapist – Student'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Speech Therapist'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Speech Therapist – Student'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u


foreach($user in $users)
{
    $PccUser = $false
    foreach($group in $user.MemberOf)
    {
        if ($group -like 'CN=PCC_*')
        {
            $PccUser = $true
            break
        }
    } 
    $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
    if ($PccUser -eq $true)
    {
        $pccTherapist += $personObj
    }
    else
    {
        $nonPccTherapist += $personObj
    }

}

$nonPccTherapist | export-csv -Path "C:\ps\Output\TherapistWithoutPccAccess.csv"