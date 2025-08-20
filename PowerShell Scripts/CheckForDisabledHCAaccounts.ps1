Function Main
{
    # Read Input CSV
    $emplIDs = Import-Csv "\\pes1\esss\Craig\HCA Notes\820Users.csv"

    $logFileLocation = "\\pes1\esss\Craig\HCA Notes\DupSearchLogs\"

    foreach($emp in $emplIDs)
    {
        # Get AD info for Employee ID
        $lookup = $emp.EmployeeID
        $accounts = Get-ADUser -Filter {(employeeid -eq $lookup) }  -Properties employeeid | Select Name, UserPrincipalName, SamAccountName, Enabled, employeeid

        # Determine how many active accounts for this Employee ID
        $activeAcctKount = 0
        foreach($account in $accounts)
        {
            if($account.Enabled)
            {
                
                $activeAcctKount++
            }
        }

        # If Only 1 Active account, then we need to check HCA
        if($activeAcctKount -eq 1)
        {
            $msg = "Look at HCA account for Employee ID {0} " -f $account.employeeid
            Logger -color "yellow" -string "$msg"
        }
    }
}

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $ReportDate = Get-Date -Format "MMddyyyy"
    $logFile = $logFileLocation + "Check_HCA_Accounts" + $ReportDate + ".log"
    Add-Content -Path $logFile -value $string
}


# Script Begins Here - Execute Function Main
Main