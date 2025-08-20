# This Script will:
# •	Read a list of SC2 AD groups from CSV Input file
# •	For each AD group, get all group members and report count
# • 


Function Main
{
    $outputPath = "C:\ps\Output\"
    $inputFile = "C:\ps\Input\SofCare Groups.csv"

    $groupNameList = @()
    $groupCountList = @()

    $groupNameList = getGroupNameList $inputFile

    Foreach($group in $groupNameList)
    {
        $groupCountList += GetUsersCountByGroup  $group.ADgroup
    }

    #Produce CSV file
    $outfile = $outputPath + "Sofcare AD Group Membership Count.csv"
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

    $members = $false
    $members =  Get-ADGroupMember -Identity $groupName -Recursive -ErrorAction SilentlyContinue

    if($members -eq $false)
    {
        $groupKount = "Group no longer exists"
    }
    else
    {
        $kount = $members | Measure-Object

        $groupKount = $kount.Count
    } 

    $kountObj = makeOutputObj $groupName $groupKount

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