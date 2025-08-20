function CreateDupEmplIdObject()
{
    param ($employeeId, $samAccountName1, $name1, $title1, $department1, $company1, $office1,$samAccountName2, $name2, $title2, $department2, $company2, $office2, $samAccountName3, $name3, $title3, $department3, $company3, $office3)

    $dupObj = New-Object PSObject
    $dupObj | Add-Member -type NoteProperty -Name EmployeeId -value $employeeId
    $dupObj | Add-Member -type NoteProperty -Name SamAccountName1 -value $samAccountName1
    $dupObj | Add-Member -type NoteProperty -Name Name1 -value $name1
    $dupObj | Add-Member -type NoteProperty -Name Title1 -value $title1
    $dupObj | Add-Member -type NoteProperty -Name Department1 -value $department1
    $dupObj | Add-Member -type NoteProperty -Name Company1 -value $company1
    $dupObj | Add-Member -type NoteProperty -Name office1 -value $office1
    $dupObj | Add-Member -type NoteProperty -Name SamAccountName2 -value $samAccountName2
    $dupObj | Add-Member -type NoteProperty -Name Name2 -value $name2
    $dupObj | Add-Member -type NoteProperty -Name Title2 -value $title2
    $dupObj | Add-Member -type NoteProperty -Name Department2 -value $department2
    $dupObj | Add-Member -type NoteProperty -Name Company2 -value $company2
    $dupObj | Add-Member -type NoteProperty -Name office2 -value $office2
    $dupObj | Add-Member -type NoteProperty -Name SamAccountName3 -value $samAccountName3
    $dupObj | Add-Member -type NoteProperty -Name Name3 -value $name3
    $dupObj | Add-Member -type NoteProperty -Name Title3 -value $title3
    $dupObj | Add-Member -type NoteProperty -Name Department3 -value $department3
    $dupObj | Add-Member -type NoteProperty -Name Company3 -value $company3
    $dupObj | Add-Member -type NoteProperty -Name office3 -value $office3

    return $dupObj
}

function CreatePersonObject()
{
    param ($SamAccountName, $name, $title, $department, $company, $office)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name Title -Value $title
    $perObj | add-member -type NoteProperty -Name Department -Value $department
    $perObj | add-member -type NoteProperty -Name Company -Value $company
    $perObj | add-member -type NoteProperty -Name Office -Value $office

    return $perObj
}

$noEmplIdUsers = @()
$DupEmplIdUsers = @()
$u = Get-ADUser -Filter {(surname -like '*')  } -Properties entityID, mail, employeeid,  title, office, company, department | Select Name, UserPrincipalName, SamAccountName, Enabled, mail, employeeid, surname, givenname, title, office, company, department

foreach($user in $u)
{
    if ($user.Name -like '*kiosk*')
    {
        continue
    }
    if($user.surname -like '*SVC*')
    {
        continue
    }
    if($user.employeeid)
    {
        #check for Duplicate Employee ID
        $emplId = $user.employeeid
        $a = Get-ADUser -Filter {(employeeid -eq $emplId) }  -Properties entityID, mail, employeeid,  title, office, company, department | Select Name, UserPrincipalName, SamAccountName, Enabled, mail, employeeid, surname, givenname, title, office, company, department
        $kount = $a | measure
        if($kount.Count -gt 1)
        {
            if($kount.Count -eq 3)
            {
                $dupEmplIdObj = CreateDupEmplIdObject $a[0].employeeid $a[0].SamAccountName $a[0].Name $a[0].title $a[0].department $a[0].company $a[0].office $a[1].SamAccountName $a[1].Name $a[1].title $a[1].department $a[1].company $a[1].office $a[2].SamAccountName $a[2].Name $a[2].title $a[2].department $a[2].company $a[2].office
            }
            else
            {
                $dupEmplIdObj = CreateDupEmplIdObject $a[0].employeeid $a[0].SamAccountName $a[0].Name $a[0].title $a[0].department $a[0].company $a[0].office $a[1].SamAccountName $a[1].Name $a[1].title $a[1].department $a[1].company $a[1].office "" "" "" ""
            }
            $DupEmplIdUsers += $dupEmplIdObj
        }
    }
    else
    {
        #if([string]::isnullorempty($user.title))
        #{
        #    $title = ""
        #}
        #else
        #{
        #    $title = $user.title
        #}
        #if([string]::isnullorempty($user.department))
        #{
        #    $department = ""
        #}
        #else
        #{
        #    $department = $user.department
        #}
        #if([string]::isnullorempty($user.company))
        #{
        #    $company = ""
        #}
        #else
        #{
        #    $company = $user.company
        #}
        #if([string]::isnullorempty($user.office))
        #{
        #    $office = ""
        #}
        #else
        #{
        #    $office = $user.office
        #}
        #$personObj = CreatePersonObject $user.SamAccountName $user.Name $title $department $company $office
        if($user.Enabled)
        {
            $personObj = CreatePersonObject $user.SamAccountName $user.Name $user.title $user.department $user.company $user.office
            $noEmplIdUsers += $personObj
        }
    }
}
$noEmplIdUsers | export-csv -Path "C:\ps\Output\NoEmployeeIDusers.csv"
$DupEmplIdUsers | export-csv -Path "C:\ps\Output\DupEmployeeIDusers.csv"