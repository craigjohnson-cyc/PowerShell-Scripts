


function CreatePersonObject()
{
    param ($SamAccountName, $name, $title, $facName)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | add-member -type NoteProperty -Name UserId -Value $SamAccountName
    $perObj | add-member -type NoteProperty -Name JobTitle -Value $title
    $perObj | add-member -type NoteProperty -Name FacilityName -Value $facName

    return $perObj
}


$PCCgroupMembers = @()
$NonPCCgroupMembers = @()
#$users = Get-ADGroupMember -identity "Sofcare_Nursing" -Recursive | Get-ADUser -Property DisplayName | Select Name, SamAccountName, Enabled, mail, memberof
$users = get-aduser -LDAPFilter "(memberof=CN=SofCare_Nursing,OU=SofCare,OU=Applications,OU=Role Groups,DC=lcca,DC=net)" -Properties displayname, memberof, title, office
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
    $personObj = CreatePersonObject $user.SamAccountName $user.Name $user.Title $user.office
    if ($PccUser -eq $true)
    {
        $PCCgroupMembers += $personObj
    }
    else
    {
        $NonPCCgroupMembers += $personObj
    }

}
$NonPCCgroupMembers | export-csv -Path "C:\ps\SofcareNursingNonPccUsers.csv"