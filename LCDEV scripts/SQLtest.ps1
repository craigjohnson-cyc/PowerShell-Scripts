# Get a list of ADOR associates from the MID databasee
$ServerInstance = "tbddb1x\"
$Database = "MID"
$query = "SELECT emplid from [ADP].[PS_JOB] where jobcode in ('62105', '62104', '62904', '62905', '62702', '61102')"

$adorList = Invoke-SqlCmd -Query $query -ServerInstance "$ServerInstance" -Database "$Database" 


# Get members of the AD group CAG_LCCA
$groupMembers = Get-ADGroupMember -identity "CAG LCCA" -Recursive | Get-ADUser -Property DisplayName | Select Name,ObjectClass,DisplayName
$groupMembers.Count