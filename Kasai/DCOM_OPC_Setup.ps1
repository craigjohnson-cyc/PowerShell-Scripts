# DCOM_OPC_Setup
#---------------
#
# This script was created to perform the necessary setup for
# a new line comupter.
#
# This script REQUIRES that PowerShell be run in Administrator Mode
#------------------------------------------------------------------
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Import-Module -Name DCOMPermissions
Import-Module activedirectory
Add-PSSnapin Microsoft.Exchange.Management.Powershell.Admin -erroraction silentlyContinue
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
Clear-Host

# Include common Functions
#-------------------------
. c:\Development2\PowerShellScripts\KasaiFunctions.ps1

Function Main
{
    # Set Initial Values
    #-------------------
    $logFileLocation = "C:\Development\PowerShellScripts\Logs\"
    $logFileName = "DCOM_OPC_Setup_{0}"
    $ReportDate = Get-Date -Format "MMddyyyy"
    $logToFile = $true
    $SqlServerStatus = $()
    $AppServerStatus = $()
    $DatabaseStatus = $()
    $SqlJobStatus = $()
    $a = Get-ChildItem -Path Env:\ComputerName
    $computerName = $a.Value


    # Add computer name to log file name
    #-----------------------------------
    $logFileName = $logFileName -f $computerName

    $msg = "Starting set-up of DCOM OPC on {0}" -f $computerName
    logger -color "green" -string $msg

    # Users - {Page 4}
    #   After many hours of trial and error, it was determined that the simplest way to
    #   Add users to DCOM is to import a registry from a computer that has already been
    #   Set up, and that this should be done first
    #----------------------------------------------------------------------------------
    PerformRegistryImport

    #  Set DCOM - {Page 3}
    #---------------------
    #PerformSetMyComputerDCOM - Step is not needed as the values are set by the Registry Import - CAJ 8/25/23

       
    #3 OPC ENUM - {Page 6}
    #---------------------
    
    
    #\\tnnas01\mis\Software\Kepware\opc-expert\General OPC Files  on VM tn_opctest - need to register those DLL's
    PerformRegisterDlls


    #4 Done?  Send email?

}  #End of Function Main

Function PerformRegistryImport
{

    $targetPath = "C:\Development\PowerShellScripts\InputFiles\"
    $sourcePath = "\\tnnas01\mis\Software\Kepware\"

    mkdir $targetPath -Force

    $msg = "  Copying registry files from {0} to {1}" -f $sourcePath, $targetPath
    logger -color "green" -string $msg

    $source1 = $sourcePath + "OPC.reg"
    $target1 = $targetPath + "OPC.reg"
    Copy-Item -Path $source1 -Destination $target1
    $source2 = $sourcePath + "OPC-wow64.reg"
    $target2 = $targetPath + "OPC-wow64.reg"
    Copy-Item -Path $source2 -Destination $target2

    #Start-Process reg -ArgumentList "import C:\Development\PowerShellScripts\InputFiles\OPC.reg"
    #Start-Process reg -ArgumentList "import C:\Development\PowerShellScripts\InputFiles\OPC-wow64.reg"

    $msg = "  Importing registry file {0}" -f $target1
    logger -color "green" -string $msg
    Start-Process reg -ArgumentList "import $target1"

    $msg = "  Importing registry file {0}" -f $target2
    logger -color "green" -string $msg
    Start-Process reg -ArgumentList "import $target2"


}  #End of Function PerformRegistryImport

Function PerformSetMyComputerDCOM
{
    # •	The Enable Distributed COM on this computer MUST be checked.
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Ole' -Name 'EnableDCOM' -Value 'Y'
    try
        {
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Ole' -Name 'EnableDCOM' -Value 'Y'
        }
    catch
        {
            #No Action Taken as this registry Key may not exist
        }

    # •	The Default Authentication Level should be set to Connect. 
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Ole' -Name 'LegacyAuthenticationLevel' -Value '2'
    try
        {
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Ole' -Name 'LegacyAuthenticationLevel' -Value '2'
        }
    catch
        {
            #No Action Taken as this registry Key may not exist
        }

    # •	The Default Impersonation Level should be set to Identity.
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Ole' -Name 'LegacyImpersonationLevel' -Value '2'
    try
        {
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Ole' -Name 'LegacyImpersonationLevel' -Value '2'
        }
    catch
        {
            #No Action Taken as this registry Key may not exist
        }

}  #End of Function PerformSetMyComputerDCOM

Function PerformRegisterDlls
{
    $dllPath = addbs('\\tnnas01\mis\Software\Kepware\opc-expert\General OPC Files')
    $dllsToRegister = Get-ChildItem -Path $dllPath
    $target = "C:\OPC_DLLs\"
    md -Force $target | Out-Null  #Ensure that the Target directory exists
    cd $target
    foreach ($dll in $dllsToRegister)
    {
        if([System.IO.Path]::GetExtension($dll.Name.ToLower()) -eq ".dll")
        {
            $file = $dllPath + $dll.Name
            $target = "C:\OPC_DLLs\{0}" -f $dll.Name
            #$dllFile = ADDBS($target) + $dll.Name.ToLower()
            Copy-Item -Path $file -Destination $target -Force
            #Copy-Item -Path $file -Destination $dllFile -Force
            $msg = "Registering file {0}" -f $dll.Name
            logger -color "green" -string $msg
            Regsvr32 $target #$file
            #%systemroot%\SysWoW64\regsvr32.exe $target /s
        }
    }

}  #End of Function PerformRegisterDlls

function Grant-ComPermission
{
    <#
    .SYNOPSIS
    Grants COM access permissions.
     
    .DESCRIPTION
    Calling this function is equivalent to opening Component Services (dcomcnfg), right-clicking `My Computer` under Component Services > Computers, 
    choosing `Properties`, going to the `COM Security` tab, and modifying the permission after clicking the `Edit Limits...` or `Edit Default...` 
    buttons under the `Access Permissions` section.
     
    You must set at least one of the `LocalAccess` or `RemoteAccess` switches.
     
    .OUTPUTS
    Carbon.Security.ComAccessRule.
 
    .LINK
    Get-ComPermission
 
    .LINK
    Revoke-ComPermission
     
    .EXAMPLE
    Grant-ComPermission -Access -Identity 'Users' -Allow -Default -Local
     
    Updates access permission default security to allow the local `Users` group local access permissions.
 
    .EXAMPLE
    Grant-ComPermission -LaunchAndActivation -Identity 'Users' -Limits -Deny -Local -Remote
     
    Updates access permission security limits to deny the local `Users` group local and remote access permissions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]        
        $Identity,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # Grants Access Permissions.
        $Access,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # Grants Launch and Activation Permissions.
        $LaunchAndActivation,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionDeny')]
        [Switch]
        # Grants default security permissions.
        $Default,
        
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # Grants security limits permissions.
        $Limits,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionAllow')]
        [Switch]
        # If set, allows the given permissions.
        $Allow,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, denies the given permissions.
        $Deny,
                
        [Parameter(ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # If set, grants local access permissions. Only valid if `Access` switch is set.
        $Local,
        
        [Parameter(ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # If set, grants remote access permissions. Only valid if `Access` switch is set.
        $Remote,

        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants local launch permissions. Only valid if `LaunchAndActivation` switch is set.
        $LocalLaunch,
        
        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants remote launch permissions. Only valid if `LaunchAndActivation` switch is set.
        $RemoteLaunch,

        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants local activation permissions. Only valid if `LaunchAndActivation` switch is set.
        $LocalActivation,
        
        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants remote activation permissions. Only valid if `LaunchAndActivation` switch is set.
        $RemoteActivation,

        [Switch]
        # Return a `Carbon.Security.ComAccessRights` object for the permissions granted.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $account = Resolve-Identity -Name $Identity -ErrorAction:$ErrorActionPreference
    if( -not $account )
    {
        return
    }

    $comArgs = @{ }
    if( $pscmdlet.ParameterSetName -like 'Default*' )
    {
        $typeDesc = 'default security permissions'
        $comArgs.Default = $true
    }
    else
    {
        $typeDesc = 'security limits'
        $comArgs.Limits = $true
    }
    
    if( $pscmdlet.ParameterSetName -like '*Access*' )
    {
        $permissionsDesc = 'Access'
        $comArgs.Access = $true
    }
    else
    {
        $permissionsDesc = 'Launch and Activation'
        $comArgs.LaunchAndActivation = $true
    }
    
    $currentSD = Get-ComSecurityDescriptor @comArgs -ErrorAction:$ErrorActionPreference

    $newSd = ([wmiclass]'win32_securitydescriptor').CreateInstance()
    $newSd.ControlFlags = $currentSD.ControlFlags
    $newSd.Group = $currentSD.Group
    $newSd.Owner = $currentSD.Owner

    $trustee = ([wmiclass]'win32_trustee').CreateInstance()
    $trustee.SIDString = $account.Sid.Value

    $ace = ([wmiclass]'win32_ace').CreateInstance()
    $accessMask = [Carbon.Security.ComAccessRights]::Execute
    if( $Local -or $LocalLaunch )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ExecuteLocal
    }
    if( $Remote -or $RemoteLaunch )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ExecuteRemote
    }
    if( $LocalActivation )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ActivateLocal
    }
    if( $RemoteActivation )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ActivateRemote
    }
    
    Write-Verbose ("Granting {0} {1} COM {2} {3}." -f $Identity,([Carbon.Security.ComAccessRights]$accessMask),$permissionsDesc,$typeDesc)

    $ace.AccessMask = $accessMask
    $ace.Trustee = $trustee

    # Remove DACL for this user, if it exists, so we can replace it.
    $newDacl = $currentSD.DACL | 
                    Where-Object { $_.Trustee.SIDString -ne $trustee.SIDString } | 
                    ForEach-Object { $_.PsObject.BaseObject }
    $newDacl += $ace.PsObject.BaseObject
    $newSd.DACL = $newDacl

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'
    $sdBytes = $converter.Win32SDToBinarySD( $newSd )

    $regValueName = $pscmdlet.ParameterSetName -replace '(Allow|Deny)$',''
    Set-RegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -Binary $sdBytes.BinarySD -Quiet -ErrorAction:$ErrorActionPreference
    
    if( $PassThru )
    {
        Get-ComPermission -Identity $Identity @comArgs -ErrorAction:$ErrorActionPreference
    }
}  #End of Function Grant-ComPermission

function PerformAddUser
{
    param 
    (
        [string]$user = $(throw "A User Name must be supplied")
    )
    $domainName = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Name, Domain
    $userObj = "{0}\{1}" -f $domainName.Domain, $user

    $msg = "Setting Default COM Security Default Access Permissions for {0}" -f $user
    logger -color "green" -string $msg

    C:\Development\DCOMpermEX\DComPermEx.exe -ml set $userObj permit level:l,r

}  #End of Function PerformAddUser


function New-DComAccessControlEntry {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] 
        $Domain,
 
        [Parameter(Mandatory=$true, Position=1)]
        [string]
        $Name,
 
        [string] 
        $ComputerName = ".",

        [switch] 
        $Group
    )
 
    #Create the Trusteee Object
    $Trustee = ([WMIClass] "\\$ComputerName\root\cimv2:Win32_Trustee").CreateInstance()
    #Search for the user or group, depending on the -Group switch
    if (!$group) { 
        $account = [WMI] "\\$ComputerName\root\cimv2:Win32_Account.Name='$Name',Domain='$Domain'" }
    else { 
        $account = [WMI] "\\$ComputerName\root\cimv2:Win32_Group.Name='$Name',Domain='$Domain'" 
    }
 
    #Get the SID for the found account.
    $accountSID = [WMI] "\\$ComputerName\root\cimv2:Win32_SID.SID='$($account.sid)'"
 
    #Setup Trusteee object
    $Trustee.Domain = $Domain
    $Trustee.Name = $Name
    $Trustee.SID = $accountSID.BinaryRepresentation
 
    #Create ACE (Access Control List) object.
    $ACE = ([WMIClass] "\\$ComputerName\root\cimv2:Win32_ACE").CreateInstance()
 
    # COM Access Mask
    #   Execute         =  1,
    #   Execute_Local   =  2,
    #   Execute_Remote  =  4,
    #   Activate_Local  =  8,
    #   Activate_Remote = 16 
 
    #Setup the rest of the ACE.
    $ACE.AccessMask = 11 # Execute | Execute_Local | Activate_Local
    $ACE.AceFlags = 0
    $ACE.AceType = 0 # Access allowed
    $ACE.Trustee = $Trustee
    $ACE
}

# Script Begins Here - Execute Function Main
Main 