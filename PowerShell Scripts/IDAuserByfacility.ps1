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

$IDAusers = @()
$users = @()
$u = get-aduser -Filter {(office -eq 'Alameda Oaks')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Bridgeton')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Charleston')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Collegedale')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Federal Way')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Greeneville')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Jacksonville')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Ka Punawai Ola')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Paradise Valley (AZ)')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'pensacola')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Plymouth')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Post Falls')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Pueblo')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = get-aduser -Filter {(office -eq 'Vista')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u

foreach($user in $users)
{
    $PccUser = $false
    foreach($group in $user.memberof)
    {
        if ($group -like 'CN=IDA_Nurse_UnitManager*')
        {
            $PccUser = $true
            break
        }
    #    if ($group -like 'CN=PCC_Lic_Therapist*')
    #    {
    #        $PccUser = $true
    #        break
    #    }
    }
    if ($PccUser -eq $true)
    {
        $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
        $IDAusers += $personObj
    }
}

#$IDAusers
$IDAusers | export-csv -Path "C:\ps\Output\IDAusers6thRun.csv"