
##############################################################################################
#                                                                                            #
#   Must have sharepoint Managemnet Shell located at: (with all default settings on install) #
#   http://www.microsoft.com/en-us/download/details.aspx?id=35588                            #
#                                                                                            #
##############################################################################################

# Adapted from:
# http://blogs.technet.com/b/heyscriptingguy/archive/2011/02/15/using-powershell-to-get-data-from-a-sharepoint-2010-list.aspx

Add-PSSnapin Quest.ActiveRoles.ADManagement

#Version 11.20.15.17

# This script is for getting user information from a SharePoint list and
#  adding them to certain AD Groups, that are defined in the SharePoint list.


# The $ListName is the name of the list that is located at the URL $ListLocation
$ListName = "Optima Deployment"
$ListLocation = "http://lccavs/team/it/ProjMgmt/"

# Set date to today's date
$Date = [DateTime]::Today
#$Date = Get-Date "10/12/2017"

#emial server to send out post-run email
$emailServer = "129.1.16.2"

#Inline C# code to use
$cSharp = @" 
using System; 
using System.Collections.Generic; 
using Microsoft.SharePoint.Client; 
 
namespace SPClient
{ 
    public class SharePointList 
    { 
        public static ListItemCollection GetList() 
        { 
            ClientContext clientContext = new ClientContext(`"$ListLocation`"); 
            List list = clientContext.Web.Lists.GetByTitle(`"$ListName`"); 
            CamlQuery camlQuery = new CamlQuery(); 
            camlQuery.ViewXml = "<View/>"; 
            ListItemCollection listItems = list.GetItems(camlQuery); 
            clientContext.Load(list);  
            clientContext.Load(listItems); 
            clientContext.ExecuteQuery(); 
            return listItems; 
        } 
    } 
} 
"@ 
 
#Required Assemblies for the C# code
$assemblies = @( 
    "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.dll", 
    "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.Runtime.dll" 
    "System.Core" 
    )

#"Import" the library (the inline C#) and use the listed assemblies
Add-Type -TypeDefinition $cSharp -ReferencedAssemblies $assemblies 

#Call GetList() from the C# code : Gets all the items from the SharePoint list
$items = [SPClient.SharepointList]::GetList()

#Creates an empty array that will store the returned SharePoint items
$facilitylist = @()

#Access each item by their properties
foreach ($item in $items) { 
    $obj = new-object psobject 
    foreach ($i in $item.FieldValues) 
    { 
        $keys = @() 
        $values = @() 
             
        foreach ($key in $i.keys) {$keys += $key} 
        foreach ($value in $i.values) {$values += $value} 
             
        for ($i = 0; $i -lt $keys.count-1; $i++) 
            { 
                $obj | Add-Member -MemberType noteproperty -Name $keys[$i] -Value $values[$i] 
            } 
    }
    $facilitylist += $obj
}

#A boolean that is set if there was some problem when adding roles to any user
$hasErrors = $false

#A boolean that is set if and only if we have actually done any work
$doemail = $false

#Create empty string to log errors
$errorLog = ""

#Create empty string to log items 
$facilityLog = ""
$trainingLog = ""
$goLiveLog = ""

#Set the name of the error log file and remove existing log file with same date
$optimaerrorname = ('OptimaErrorLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')

if (Test-Path -Path ("C:\OptimaRollout\"+$optimaerrorname))
{
    Remove-Item -Path ("C:\OptimaRollout\"+$optimaerrorname)
}

#Set the name of the log files and remove existing log files with same date
$facilityRolloutLog   = ('FacilityRolloutLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')
$trainingUsersLog   = ('TrainingUsersLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')
$goLiveUsersLog   = ('GoLiveUsersLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')

if (Test-Path -Path ("C:\OptimaRollout\"+$facilityRolloutLog))
{
    Remove-Item -Path ("C:\OptimaRollout\"+$facilityRolloutLog)
}
if (Test-Path -Path ("C:\OptimaRollout\"+$trainingUsersLog))
{
    Remove-Item -Path ("C:\OptimaRollout\"+$trainingUsersLog)
}
if (Test-Path -Path ("C:\OptimaRollout\"+$goLiveUsersLog))
{
    Remove-Item -Path ("C:\OptimaRollout\"+$goLiveUsersLog)
}

#Select all the items in the list that do not have a null Pre-implementation date
$facilitylist = $facilitylist | where {$_.Pre_x002d_Implementation_x0020_T -ne $null -and $_.Go_x0020_Live -ne $null}

#Select only the items that have a matching pre-implementation date
$preimplementation = $facilitylist| Where {$_.Pre_x002d_Implementation_x0020_T.Date -eq $Date}

#Select only the items that have a matching Go-live date
$golive = $facilitylist | Where {$_.Go_x0020_Live.Date -eq $Date}

#Get AD facility groups matching entityID with CorpID from the list for pre-implementation
$trainingfacilities = $preimplementation | foreach {Get-QADGroup -LdapFilter "(entityID=$($_.CorpID))"}

#Get AD facility groups matching entityID with CorpID from the list for go-live
$golivefacilities = $golive | foreach {Get-QADGroup -LdapFilter "(entityID=$($_.CorpID))"}

#Get members of the AD facility groups that are also member of XenApp Sofcare Rehab group
#Use this for LCDEV domain 
#$trainingusers = $trainingfacilities | foreach {Get-QADGroupMember -Identity $_ -LdapFilter "(&(objectCategory=user)(memberof=cn=XenApp Sofcare Rehab,ou=test,ou=corporate,dc=lcdev,dc=net))"}
#Use this for LCCA domain
$trainingusers = $trainingfacilities | foreach {Get-QADGroupMember -Identity $_ -LdapFilter "(&(objectCategory=user)(memberof=CN=XenApp Sofcare Rehab,OU=CITRIX,OU=Role Groups,DC=lcca,DC=net))"}

#Get members of the AD facility groups that are also member of XenApp Sofcare Rehab group
#Use this for LCDEV domain
#$goliveusers = $golivefacilities | foreach {Get-QADGroupMember -Identity $_ -LdapFilter "(&(objectCategory=user)(memberof=cn=XenApp Sofcare Rehab,ou=test,ou=corporate,dc=lcdev,dc=net))"} 
#Use this for LCCA domain
$goliveusers = $golivefacilities | foreach {Get-QADGroupMember -Identity $_ -LdapFilter "(&(objectCategory=user)(memberof=CN=XenApp Sofcare Rehab,OU=CITRIX,OU=Role Groups,DC=lcca,DC=net))"} 

if ($trainingfacilities -ne $null)
{
    $doemail = $true
    #Add each facility to Optima_Implementation group and log the actions
    foreach ($facility in $trainingfacilities){

        try {
                Write-Host Adding: $facility.Name `t To: Optima_Implementation

                Add-QADMemberOf -Identity $facility -Group 'Optima_Implementation'
        }
        catch {
                $hasErrors = $true
                $errorLog += ("ERROR: " + $facility.Name + " could NOT be added To: " + "Optima_Implementation " + $_.Exception.Message + "`r`n")

                return
        }
        $facilityLog += ($facility.Name + " Added To: " + "Optima_Implementation Group" + "`r`n")
    }
    
}
Add-Content -value $facilityLog -Path ("C:\OptimaRollout\"+$facilityRolloutLog)

if ($trainingusers -ne $null)
{
    $doemail = $true
    #Add training users to the XenApp Optima POC Training group and log the actions
    foreach ($traininguser in $trainingusers){
     
         try{
    
                Write-Host Adding: $traininguser.Name `t To: XenApp Optima POC Training

                Add-QADMemberOf -Identity $traininguser -Group 'XenApp Optima POC Training'
        }
        catch {
                $hasErrors = $true
                $errorLog += ("ERROR: " + $traininguser.Name + " could NOT be added To: " + "XenApp Optima POC Training " + $_.Exception.Message + "`r`n")               

                return
        }
        $trainingLog += ($traininguser.Name + " Added To: " + "XenApp Optima POC Training Group" + "`r`n")
    }
    
}
Add-Content -value $trainingLog -Path ("C:\OptimaRollout\"+$trainingUsersLog)

if ($goliveusers -ne $null)
{
    $doemail = $true
    #Add go-live users to the XenApp Optima POC group and log the actions
    foreach ($goliveuser in $goliveusers){
    
        try{
               Write-Host Adding: $goliveuser.Name `t To: XenApp Optima POC

               Add-QADMemberOf -Identity $goliveuser -Group 'XenApp Optima POC'
        }
        catch {
                $hasErrors = $true
                $errorLog += ("ERROR: " + $goliveuser.Name + " could NOT be added To: " + "XenApp Optima POC " + $_.Exception.Message + "`r`n")
                               
                return
        }
        $goLiveLog += ($goliveuser.Name + " Added To: " + "XenApp Optima POC Group" + "`r`n")
    }
    
}
Add-Content -value $goLiveLog -Path ("C:\OptimaRollout\"+$goLiveUsersLog)

if ($hasErrors) {

    #Output the error log
    Add-Content -Value $errorLog -Path ("C:\OptimaRollout\"+$optimaerrorname)

	#Set the body of the email
    $body = ("The script ran with issues. The attached files has a list of the facility groups and/or users that have been added to their specified AD groups. There were some problems with the rollout. More information can be found in the attached file named $optimaerrorname")

	#Send the email
    Send-MailMessage -From "kevin_patel@lcca.com" -To "kevin_patel@lcca.com","amit_patel@lcca.com" -Attachments ("C:\OptimaRollout\facilityRolloutLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRollout\trainingUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRollout\goLiveUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRollout\optimaerrorname-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt") -Body $body -Subject "Optima Rollout" -SmtpServer $emailServer 

} elseif ($doemail) {
    
	#Set the body of the email
    $body = ("The script ran with no issues. The attached files has a list of the facility groups and/or users that have been added to their specified AD groups. If a log file is empty, that means there was no data to be processed. ")

	#Send the email
    Send-MailMessage -From "kevin_patel@lcca.com" -To "kevin_patel@lcca.com","amit_patel@lcca.com" -Attachments ("C:\OptimaRollout\facilityRolloutLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRollout\trainingUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRollout\goLiveUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt") -Body $body -Subject "Optima Rollout" -SmtpServer $emailServer
}