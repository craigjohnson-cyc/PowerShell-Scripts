# This Script will:
# •	Read a list of SC2 AD groups from CSV Input file
# •	For each AD group, get all group members and report count
# • 


Function Main
{
    $outputPath = "C:\ps\Output\"
    $inputFile = "C:\ps\Input\SC2 Rehab AD Groups.csv"

    $groupNameList = @()
    $groupCountList = @()

    #$groupNameList = getGroupNameList $inputFile
    $groupNameList = Get-ADGroup  -Filter 'Name -like "*"'

    Foreach($group in $groupNameList)
    {
        $groupCountList += GetUsersCountByGroup  $group.DistinguishedName
    }

    #Produce CSV file
    $outfile = $outputPath + "AD Group Membership Count.csv"
    $groupCountList | export-csv -Path $outfile -NoTypeInformation

}

Function getGroupNameList
{
    param ($inputFile)

    $groupNameList = Import-Csv $inputFile

    return $groupNameList
}

Function GetUsersCountByGroup
{
    param ($groupName)

    $members =  Get-ADGroupMember -Identity $groupName -Recursive

    $kount = $members | measure

    $kountObj = makeOutputObj $groupName $kount.Count

    return $kountObj

}

Function makeOutputObj
{
    param($groupName, $kount)

    $obj = New-Object PSObject
    $obj | Add-Member -type NoteProperty -Name GroupName -Value $groupName
    $obj | add-member -type NoteProperty -Name Count -Value $kount
    
    return $obj
}






# Script begins here:  Execute Function Main
Main