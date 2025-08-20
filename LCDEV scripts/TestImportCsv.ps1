$userName = $env:UserName
#"The current user name is: $userName"
$dataFileLocation = "C:\Users\$userName\Documents\"
$dataFile = "C:\Users\$userName\Documents\LCCA_Users_20170831090600.csv"

if (Test-Path $dataFile)
{
    # Read data Settings from file
    #Push-Location $dataFileLocation
    $dataValues = Import-Csv $dataFile -Delimiter "|" 
    foreach ($record in $dataValues)
    {
        $facilityId = $record.facilityId
        $lastName = $record.lastname
        $PSLib = $dataValues.PSLib
    }
}
else
{
    # Get data settings from user and save in file
    $msg = "It appears that the file was not found!"
    $msg

}
