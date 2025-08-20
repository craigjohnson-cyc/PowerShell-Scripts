Import-Module activedirectory

Function Main
{
    #Get-ADUser -Filter {(SamAccountName -eq 'AG0241')} -Properties employeeid,description, title, wwwHomePage, company,department |Select sAMAccountName,enabled,surname, givenname,description,department,company, title,wWWhomePage,employeeid
    $AllEmployees = Get-ADUser -Filter * -SearchBase "DC=lcca,DC=net" -Properties employeeid,description, title, wwwHomePage, company,department | Where { $_.Enabled -eq $True}  |Select sAMAccountName,enabled,surname, givenname,description,department,company, title,wWWhomePage,employeeid
    $EmployeeCount = 0
    $ContractorCount = 0
    $Employees = @()
    $Contractors = @()

    foreach($emp in $AllEmployees)
    {
        #Determine of Employee or Contractor
        if($emp.wWWHomePage -like "*Contract*" -or $emp.Description -like "*Consultant*")
        {
            #Contractor
            $msg = "Contractor found: {0} " -f $emp.SamAccountName
            Logger -color "Yellow" -string "$msg"
            $ContractorCount++
            $obj = CreateUserObj $emp.SamAccountName $emp.surname $emp.givenname $emp.description $emp.company $emp.department $emp.employeeID $emp.wWWHomePage
            $Contractors+=$obj
        }
        else
        {
            #Employee
            if($emp.employeeid -eq "" -or $emp.employeeid -eq $null)
            {
                #No Action Taken - Don't want employee's without EmployeeID
                $msg = "AD account missing Employee ID: {0} " -f $emp.SamAccountName
                Logger -color "red" -string "$msg"
            }
            else
            {
                #Employee found
                $msg = "Employee found: {0} " -f $emp.SamAccountName
                Logger -color "green" -string "$msg"
                $EmployeeCount++
                $obj = CreateUserObj $emp.SamAccountName $emp.surname $emp.givenname $emp.description $emp.company $emp.department $emp.employeeID $emp.wWWHomePage
                $Employees+=$obj
            }
        }
    }

    $logFileLocation = "c:\ps\output\"
    $ReportDate = $ReportDate = Get-Date -Format "MMddyyyy"
    $msg = "Number of active Employees: {0} " -f $EmployeeCount
    Logger -color "yellow" -string "$msg"
    $msg = "Number of Contractors: {0} " -f $ContractorCount
    Logger -color "yellow" -string "$msg"

    $outputFile = $logFileLocation + "Contractors_" + $ReortDate 
    $Contractors | export-csv $outputFile  -NoTypeInformation
    $outputFile = $logFileLocation + "Employees_" + $ReortDate 
    $Employees | export-csv $outputFile  -NoTypeInformation
}

Function CreateUserObj
{
    param ($userName, $lastName, $firstName, $title, $division, $region, $employeeID, $webPage)

    $userObj = New-Object PSObject
    $userObj | Add-Member -type NoteProperty -Name UserName -Value $userName
    $userObj | Add-Member -type NoteProperty -Name LastName -Value $lastName
    $userObj | Add-Member -type NoteProperty -Name FirstName -Value $firstName
    $userObj | Add-Member -type NoteProperty -Name Title -Value $title
    $userObj | Add-Member -type NoteProperty -Name Division -Value $division
    $userObj | Add-Member -type NoteProperty -Name Region -Value $region
    $userObj | Add-Member -type NoteProperty -Name EmployeeID -Value $employeeID
    $userObj | Add-Member -type NoteProperty -Name WebPage -Value $webPage

    return $userObj

}

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $logFile = $logFileLocation + "AssociateList_" + $ReportDate + ".log"
    Add-Content -Path $logFile -value $string
}


# Script Begins Here - Execute Function Main
Main
