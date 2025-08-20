function CreateObject()
{
    param ($name, $entityId)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name Name -Value $name
    $perObj | Add-Member -type NoteProperty -Name EntityId -Value $entityId

    return $perObj
}

function CreateDuplicateEntityIdObject()
{
    param ($ouname, $groupname, $entityId)
    
    $perObj = New-Object PSObject
    $perObj | Add-Member -type NoteProperty -Name OuName -Value $name
    $perObj | Add-Member -type NoteProperty -Name GroupName -Value $name
    $perObj | Add-Member -type NoteProperty -Name EntityId -Value $entityId

    return $perObj
}

$list = @()
$dupList = @()
$ou = Get-ADOrganizationalUnit -Filter 'Name -like "*"' -Property EntityId | Select Name, EntityId
foreach($unit in $ou)
{
    $obj = CreateObject $unit.Name $unit.EntityId
    $list += $obj
}

$groups = Get-ADGroup -Filter 'Name -like "*"' -Property EntityId | Select Name, EntityId
foreach($group in $groups)
{
    if($group.EntityId -gt 0)
    {
        $match = $false
        foreach($unit in $list)
        {
            if ($group.EntityId -eq $unit.EntityId)
            {
                $match = $true
                $dup = CreateDuplicateEntityIdObject $unit.Name $group.Name $group.EntityId
                $dupList += $dup
                break
            }
        }
    }
}

$dupList