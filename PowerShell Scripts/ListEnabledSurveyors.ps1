# This Script will:
# •	Generate a list from AD of users with account names beginning with SVY_
# •	For each user in the list, output those that are enabled (Expiration Date >= Today)
# • 


Function Main
{
    $enabledSurveyors = @()
    $users = Get-ADUser -Filter {(SamAccountName -like 'SVY_*') }  -Properties entityID, AccountExpirationDate | Select Name, UserPrincipalName, SamAccountName, Enabled, AccountExpirationDate
    $testDate = Get-Date
    foreach($user in $users)
    {
        if($user.AccountExpirationDate -ge $testDate)
        {
            $enabledSurveyors += CreateSurveyorObj $user.Name $user.SamAccountName $user.AccountExpirationDate
        }
    }

    #Produce CSV file
    $outfile = "C:\ps\output\EnabledSurveyors.csv"
    $enabledSurveyors | export-csv -Path $outfile -NoTypeInformation

}


Function CreateSurveyorObj
{
    param($name, $samAccount, $expireDate)

    $obj = New-Object PSObject
    $obj | Add-Member -type NoteProperty -Name Name -Value $name
    $obj | add-member -type NoteProperty -Name SamAccountName -Value $samAccount
    $obj | add-member -type NoteProperty -Name ExpireDate -Value $expireDate
    
    return $obj
}


# Script begins here:  Execute Function Main
Main