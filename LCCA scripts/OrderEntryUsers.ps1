#The first of the month after the PCC go-live date, Add AD group PCC_OrderEntry to any users currently in
#either PCC_DOR_ADOR or PCC_Lic_Therapist. 

##Functionality Change!!  This is now a one time script.  It will add users to the AD Group PCC_OrderEntry that are currently in the groups
## PCC_DOR_ACOR or PCC_Lic_Therapist regardless of facility. 

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

$orderEntryUsers = @()
$users = @()

#Get all users for facilities that went live the previous Month
#$u = Get-ADGroupMember -identity "Hixson" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
#$u = get-aduser -Filter {(office -eq 'Hixson')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
#$users += $u
#$u = get-aduser -Filter {(office -eq 'facility2')} -Properties displayname, memberof, title, office | Select Name, surname, givenname, SamAccountName, title, office, memberof
#$users += $u


#change script to process all AD users, will be run just one time.  Not each month for facilities that went live last month as originally planned.
#  

#$u = Get-ADGroupMember -identity "PCC_DOR_ADOR" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
#$users += $u
#$u = Get-ADGroupMember -identity "PCC_Lic_Therapist" -Recursive | Get-ADUser -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
#$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Speech Therapist'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Physical Therapist'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Registered Occupational Therapist'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Interim Director of Rehab (Licensed OT)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Interim Director of Rehab (Licensed PT)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Interim Director of Rehab (Licensed ST)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Director of Rehab (Licensed ST)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Director of Rehab (Licensed PT)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Director of Rehab (Licensed OT)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Assistant Director of Rehab (Licensed ST)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Assistant Director of Rehab (Licensed PT)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Assistant Director of Rehab (Licensed OT)'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Regional Rehab Director'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u
$u = Get-ADUser -Filter {Title -eq 'Division Rehab Director'} -Property displayname, memberof, title, office | Select  Name, surname, givenname, SamAccountName, title, office, memberof
$users += $u



#Determine if user is currently in PCC_DOR_ADOR or PCC_Lic_Therapist
foreach($user in $users)
{
    #$PccUser = $false
    #foreach($group in $user.memberof)
    #{
    #    if ($group -like 'CN=PCC_DOR_ADOR*')
    #    {
    #        $PccUser = $true
    #        break
    #    }
    #    if ($group -like 'CN=PCC_Lic_Therapist*')
    #    {
    #        $PccUser = $true
    #        break
    #    }
    #}
    #if ($PccUser -eq $true)
    #{
        $personObj = CreatePersonObject $user.SamAccountName $user.givenname $user.surname $user.Title $user.office
        $orderEntryUsers += $personObj
    #}
}

$orderEntryUsers | export-csv -Path "C:\ps\Output\OrderEntryUsers.csv" -NoTypeInformation

Add-ADGroupMember -Identity PCC_OrderEntry -Members $orderEntryUsers.UserId

