Function Main
{
    $ReportDate = Get-Date -Format "MMddyyyy"
    $logFileLocation = "c:\ps\output\"

    $usersDisabledCount = 0
    $usersUpdatedCount = 0

    $OUpath = 'ou=DisabledUsers,DC=lcca,DC=net'
    $users = Get-ADUser -Filter * -SearchBase $OUpath | Select-object DistinguishedName,Name,UserPrincipalName
    foreach($user in $users)
    {
        $userToCheck = (Get-ADUser -identity $user.DistinguishedName -Property DisplayName, wwwHomepage,whenChanged | Select Name, SamAccountName, Enabled,wwwHomepage,whenChanged)
    
        #Check date in Web Page field
        if (![string]::IsNullOrWhiteSpace($userToCheck.wwwHomepage)) 
        {
            try {
                $d = Get-Date -date $userToCheck.wwwHomepage.Substring(9,$userToCheck.wwwHomepage.Length-9)
                $dow=[int]($d).dayofweek
                if($dow -eq 5){
                    #Found Friday in date in Web Page
                    $msg = "User disabled on a Friday: {0} - Web Page value: {1}" -f $UserToCheck.SamAccountName,$userToCheck.wwwHomepage
                    Logger -color "yellow" -string "$msg"
                    $usersDisabledCount += 1
                }
            }
            catch{
                # No Action taken - No date in Web Page field
                $a=4
            }
        }
        else #Check last modified date if web page is empty
        {

            #Check if last changed was a Friday
            $checkdate = Get-Date -date $userToCheck.whenChanged
            $dow=[int]($checkdate).dayofweek
            if($dow -eq 5)
            {
                #found account last modified on a Friday
                $msg = "User last updted on a Friday: {0} " -f $UserToCheck.SamAccountName
                Logger -color "green" -string "$msg"
                $usersUpdatedCount += 1
            }
        }
    }
    $msg = "Number Disabled on Fridays: {0}" -f $usersDisabledCount
    Logger -color "green" -string "$msg"
    $msg = "Number Updated on Fridays (with blank web page): {0}" -f $usersUpdatedCount
    Logger -color "green" -string "$msg"
}

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $logFile = $logFileLocation + "AccountsDisabledOnFridays_" + $ReportDate + ".log"
    Add-Content -Path $logFile -value $string
}

# Script Begins Here - Execute Function Main
Main