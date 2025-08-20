function Get-UserGroupMembershipRecursive {
 [CmdletBinding()]
     param(
         [Parameter(Mandatory = $true)]
         [String[]]$UserName
     )
     begin {
         # introduce two lookup hashtables. First will contain cached AD groups,
         # second will contain user groups. We will reuse it for each user.
         # format: Key = group distinguished name, Value = ADGroup object
         $ADGroupCache = @{}
         $UserGroups = @{}
         $OutObject = @()
         # define recursive function to recursively process groups.
         function __findPath ([string]$currentGroup, [string]$comment) {
             Write-Verbose "Processing group: $currentGroup"
             # we must do processing only if the group is not already processed.
             # otherwise we will get an infinity loop
             if (!$UserGroups.ContainsKey($currentGroup)) {
                 # retrieve group object, either, from cache (if is already cached)
                 # or from Active Directory
                 $groupObject = if ($ADGroupCache.ContainsKey($currentGroup)) {
                     Write-Verbose "Found group in cache: $currentGroup"
                     $ADGroupCache[$currentGroup].Psobject.Copy()
                 } else {
                     Write-Verbose "Group: $currentGroup is not presented in cache. Retrieve and cache."
                     $g = Get-ADGroup -Server LCCA.Net -Identity $currentGroup -Property objectclass,sid,whenchanged,whencreated,samaccountname,displayname,enabled,distinguishedname,memberof,groupscope,groupcategory
                     # immediately add group to local cache:
                     $ADGroupCache.Add($g.DistinguishedName, $g)
                     $g
                 }
                 
                 $c = $comment + "->" + $groupObject.SamAccountName
                 
                 $UserGroups.Add($c, $groupObject)
                                 
                 Write-Verbose "Membership Path:  $c"
                 foreach ($p in $groupObject.MemberOf) {
                        __findPath $p $c
                 }
             } else { Write-Verbose "Closed walk or duplicate on '$currentGroup'. Skipping." }
         }
     }
     process {
         $enus = 'en-US' -as [Globalization.CultureInfo]
         foreach ($user in $UserName) {
             Write-Verbose "========== $user =========="
             # clear group membership prior to each user processing
             $UserObject = Get-ADUser -Server LCCA.NET -Identity $user -Property objectclass,sid,whenchanged,whencreated,samaccountname,displayname,enabled,distinguishedname,memberof,PrimaryGroup
             $UserObject.MemberOf | ForEach-Object {__findPath $_ $UserObject.SamAccountName}
             $UserObject.PrimaryGroup | ForEach-Object {__findPath $_ $UserObject.SamAccountName}
         }
             foreach($g in $UserGroups.GetEnumerator())
             {
                 $OutObject += [pscustomobject]@{
                     ObjectClass = $g.value.ObjectClass;
                     UserName = $UserObject.SamAccountName;
                     InheritancePath = $g.key;
                     MemberOf = $g.value.SamAccountName;
                     GroupScope = $g.value.GroupScope;
                     GroupCategory = $g.value.GroupCategory;
                     WhenCreated2 = $g.value.WhenCreated.ToString("MM/dd/yyyy hh:mm tt", $enus);
                     WhenChanged = $g.value.WhenChanged.ToString("MM/dd/yyyy hh:mm tt", $enus);
                 }
             }
            
            $Date = Get-Date -Format "yyyy-MM-dd"
            $Time = Get-Date -Format HH.mm.ss
            $Timestamp = "$Date-$Time"
            $Timestamp = $Timestamp -replace(":",".")
          #  $Timestamp = $Timestamp -replace("\","-")
            $OutObject | Sort-Object -Property UserName,InheritancePath,MemberOf | convertto-csv -notypeinformation |  out-file -encoding ascii -append  "C:\ps\output\LCCA_GroupMemberships-$User-$Timestamp.csv"
            $data = Import-Csv "C:\ps\output\LCCA_GroupMemberships-$User-$Timestamp.csv"
            $data | ogv
             $UserGroups.Clear()
  
     }
}

Function Get-EmployeeInfo {
 
    <#
 .Synopsis
  Returns a customized list of Active Directory account information for a single user
 
 .Description
  Returns a customized list of Active Directory account information for a single user. The customized list is a combination of the fields that
  are most commonly needed to review when an employee calls the helpdesk for assistance.
 
 .Example
  Get-EmployeeInfo Joe_Smith
  Returns a customized list of AD account information fro Michael_Kanakos
 
  PS C:\Scripts> Get-EmployeeInfo Joe_Smith
 
    FirstName    : Joe
    LastName     : Smith
    Title        : Marketing Analysyt
    Department   : Marketing
    Manager      : Tom_Jones
    City         : New York
    EmployeeID   : 123456789
    UserName     : Joe_Smith
    DisplayNme   : Smith, Joe
    EmailAddress : Joe_smith@bigfrom.biz
    OfficePhone  : +1 631-555-1212
    MobilePhone  : +1 631-333-4444
 
    PasswordExpired       : False
    AccountLockedOut      : False
    LockOutTime           : 0
    AccountEnabled        : True
    AccountExpirationDate :
    PasswordLastSet       : 3/26/2018 9:29:02 AM
    PasswordExpireDate    : 9/28/2018 9:29:02 AM
 
 .Parameter UserName
  The employee account to lookup in Active Directory
 
  .Notes
  NAME: Get-EmployeeInfo
  AUTHOR: Mike Kanakos
  LASTEDIT: 2018-04-14
  .Link
    www.networkadmin.com
 
#>
 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$UserName
    )
 
 
    #Import AD Module
    Import-Module ActiveDirectory
 
    $Employee = Get-ADuser -Server LCCA.NET -Identity $UserName -Properties *, 'msDS-UserPasswordExpiryTimeComputed'
    $Manager = if (-not ([string]::IsNullOrEmpty($Employee.manager))) 
                    { {((Get-ADUser -Server LCCA.NET -Identity $Employee.manager).samaccountname)}}
    $PasswordExpiry = [datetime]::FromFileTime($Employee.'msDS-UserPasswordExpiryTimeComputed')
 
      $AccountInfo = [PSCustomObject]@{
        UserName     = $Employee.SamAccountName
        FirstName    = $Employee.GivenName
        LastName     = $Employee.Surname
        Name         = $Employee.Name
        cn           = $Employee.cn
        Title        = $Employee.Title
        info         = $Employee.info
        Description  = $Employee.Description
        Department   = $Employee.department
        Manager      = $Manager
        City         = $Employee.city
        EmployeeID   = $Employee.EmployeeID
        DistinguishedName = $Employee.DistinguishedName
        DisplayNme   = $Employee.displayname
        EmailAddress = $Employee.emailaddress
        OfficePhone  = $Employee.officephone
        MobilePhone  = $Employee.mobilephone
        PasswordExpired       = $Employee.PasswordExpired
        AccountLockedOut      = $Employee.LockedOut
        LockOutTime           = $Employee.AccountLockoutTime
        AccountEnabled        = $Employee.Enabled
        AccountExpirationDate = $Employee.AccountExpirationDate
        PasswordLastSet       = $Employee.PasswordLastSet
        PasswordExpireDate    = $PasswordExpiry
        whenCreated           = $Employee.whenCreated
        whenChanged           = $Employee.whenChanged
        LastLogonDate         = $Employee.LastLogonDate
    }
 
 
    return $AccountInfo
 
 
} #END OF FUNCTION

Function Get-ADUserNameFromName {
     [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$LastName,
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$FirstName
    )

##$LastName = Read-Host "Enter user's Last Name" 
##$FirstName = Read-Host "Enter users's First Name" 
$GroupMembershipList = (Get-ADUser -Server LCCA.NET -Filter "GivenName -like '$FirstName*' -and Surname -like '$LastName*'").SamAccountName

    Foreach ($Name in $GroupMembershipList) {

    $GroupMemberShip = Get-ADPrincipalGroupMembership -Server LCCA.NET -Identity "$Name" | Sort Name |ForEach-Object {$_.name -replace ".*:"} 

    Write-Host " "
    Write-Host $FirstName, $LastName -ForegroundColor Yellow
    Write-Host IMC UserName = $Name 
 }

 }

 function Get-UserInfo{
     [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$LastName,
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$FirstName
    )

    $GroupMembershipList = (Get-ADUser -Server LCCA.NET -Filter "GivenName -like '$FirstName*' -and Surname -like '$LastName*'").SamAccountName
    return $GroupMembershipList
 }

 function Get-User{
     [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$LastName,
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$FirstName
    )
    $users = Get-UserInfo $LastName $FirstName
    #$users | ogv

    #Clear-Host
    #$kount = $users | measure
    #$msg = $FirstName + " " + $LastName + " has " + $kount.Count + " accounts:"
    #Write-Host $msg -ForegroundColor Yellow

    #$nbr = 1
    $accountInfo = @()
    Foreach ($user in $users) 
    {
        #if ($nbr -gt 1)
        #{
        #    Write-Host ""
        #    $msg = "Account #" + $nbr
        #    Write-Host $msg -ForegroundColor Yellow
        #    
        #}
        $accountInfo += Get-EmployeeInfo $user
        #$nbr += 1
    }
    $accountInfo | ogv
 }

 function Get-NestedGroupMember 

  { [CmdletBinding()] 

  param (
  [Parameter(Mandatory)] [string]$Group,
  [Parameter(Mandatory)] [string]$Child

  )
  If ($Child -eq '1') {
  $warning = Read-Host "Warning this can take a long time to execute. Do you still want to run? (Y/N)"

  If ($warning -eq 'N'){  break }
 
  }
 If ($warning -eq 'Y'){ 


  ## Find all members  in the group specified 

  $members = Get-ADGroupMember -Server LCCA.NET -Identity $Group 

  foreach ($member in $members)

  {


  ## If any member in  that group is another group just call this function again 

  if ($member.objectClass -eq 'group')

  {
    $Child = '0'

  Get-NestedGroupMember -Group $member.Name -Child '0'

  }

  else ## otherwise, just  output the non-group object (probably a user account) 

  {

  $member.Name  

  }

  }
  }
  }
  
 Write-Host "LCCA Tools"
 Write-Host "Get-UserGroupMembershipRecursive - Get a users groups and nested groups. Ex. Get-UserGroupMembershipRecursive caarnoldlcdev"
 Write-Host "Get-EmployeeInfo - Get AD Information about a user. EX. Get-EmployeeInfo caarnoldlcdev"
 Write-Host "Get-ADUserNameFromName - Get ADUserId from Last and First Name ex.  Get-ADUserNameFromName 'Arnold' 'Charles'"
 Write-Host "Get-NestedGroupMember - Get all users of a Group including nested group members ex. Get-NestedGroupMember 'Developers' '1'"
 Write-Host "Get-User - Get AD Information for all accounts by Last Name, First Name Ex. Get-User Johnson Craig"
 
 #cd C:\Users\dspullen\OneDrive - lcca.onmicrosoft.com\Documents\WindowsPowerShell