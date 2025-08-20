#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100
Import-Module "sqlps"
Function Main
{

    $users = @()

    $users = Get-ADGroupMember -identity "Executive Director" | Get-ADUser -Property DisplayName, office, mail,title | Select surname, givenname, mail, office,title
    $users += Get-ADGroupMember -identity "Interim Executive Director" | Get-ADUser -Property DisplayName, office, mail,title | Select surname, givenname, mail, office,title
    $users += Get-ADGroupMember -identity "Senior Executive Director" | Get-ADUser -Property DisplayName, office, mail,title | Select surname, givenname, mail, office,title
    $users += Get-ADGroupMember -identity "Regional Vice President" | Get-ADUser -Property DisplayName, office, mail,title | Select surname, givenname, mail, office,title

    #$users += Get-ADUser -Filter {(title -like '*regional vice*')} | Get-ADUser -Property DisplayName, office, mail | Select surname, givenname, mail, office

    $updateUsers = @()
    foreach($user in $users)
    {
        # query the OrganizationalHierarchy table in the Mirth_Repository for the FacID
        
        $ServerInstance = "psdb1xv\"  #Prod
        #$ServerInstance = "Qarcpsdb1x\"  #dev

        $Database = "Mirth_Repository"  #Prod
        #$Database = "Mirth_Repository_Dev"  #Dev
        $query = "SELECT OrganizationHierarchyID FROM [dbo].[OrganizationHierarchy] where longName like '%" + $user.office + "%'"

        $facId = Invoke-SqlCmd -Query $query -ServerInstance "$ServerInstance" -Database "$Database" 

        # create new object
        $updateUsers += CreateUserObject $user $facId
    }
    #$outputPath = "\\pes1\esss\Craig\PowerShell Scripts\Output\"
    $outputPath = "C:\ps\output\"
    set-location $outputPath
    $outputFile = $outputPath + "ED_RVP List.csv"
    $updateUsers | export-csv $outputFile  -NoTypeInformation
}

Function CreateUserObject
{
    param ($user, $facId)

    $userObj = New-Object PSObject
    $userObj | Add-Member -type NoteProperty -Name FacilityName -Value $user.office
    $userObj | add-member -type NoteProperty -Name FacilityId -Value $facid.OrganizationHierarchyID
    $userObj | Add-Member -type NoteProperty -Name FirstName -Value $user.givenName
    $userObj | add-member -type NoteProperty -Name LastName -Value $user.surName
    $userObj | add-member -type NoteProperty -Name EmailAddress -Value $user.mail
    $userObj | add-member -type NoteProperty -Name JobTitle -Value $user.title

    return $userObj
}

# Script Begins Here - Execute Function Main
Main