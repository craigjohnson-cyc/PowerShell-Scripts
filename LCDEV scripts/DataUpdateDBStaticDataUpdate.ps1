#################################################################################################################################
#  Name        : DataUpdateDBStaticDataUpdate.ps1                                                                                            #
#                                                                                                                               #
#  Description : Populates static data                                                                        #
#                                                                                                                               #
#################################################################################################################################

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$True,Position=1)]
	[string] $ServerInstance,

	[Parameter(Mandatory=$True,Position=2)]
	[string] $Database,

	[Parameter(Mandatory=$True,Position=3)]
	[string] $StaticUpdateDir

)

function UpdateStaticData
{
    param
    (
        [string] $ServerInstance,
        [string] $Database,
        [string] $StaticUpdateDir
    )

    $filter = "^.*\.(sql)$"

    if($StaticUpdateDir -and (Test-Path $StaticUpdateDir))
    {
        Write-Verbose "Getting sorted list of Static Data Updates for $Database from '$StaticUpdateDir'." -Verbose
        $sqlFiles = Get-ChildItem -Path $StaticUpdateDir -Recurse | Where-Object { $_.Name -match $filter } | Sort-Object

        ForEach($sqlFile in $sqlFiles )
        {
            Write-Verbose "Executing SQLCMD script: $sqlFile.Name" -Verbose
            Invoke-SqlCmd -ServerInstance "$ServerInstance" -Database "$Database" -InputFile $sqlFile.FullName
        }

		Write-Verbose "Completed executing Static Data Updates for $Database." -Verbose
    }
	else
	{
		Write-Verbose "No Static Data Updates found for $Database." -Verbose
	}
	
 
}

Write-Verbose "==================================================================================================================" -Verbose
Write-Verbose "==                                      Used parameters                                                         ==" -Verbose
Write-Verbose "==================================================================================================================" -Verbose
Write-Verbose "Server Instance                   : $ServerInstance"  -Verbose
Write-Verbose "Database                          : $Database"  -Verbose
Write-Verbose "Static Data Update Folder Path    : $StaticUpdateDir"  -Verbose
Write-Verbose "==================================================================================================================" -Verbose
Write-Verbose "" -Verbose

UpdateStaticData -ServerInstance "$ServerInstance" -Database "$Database" -StaticUpdateDir "$StaticUpdateDir" 

#################################################################################################################################