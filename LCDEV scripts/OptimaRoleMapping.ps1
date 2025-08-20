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

#Record script start datetime
$ScriptStart = (Get-Date)

# Set date to today's date
#$Date = [DateTime]::Today
$Date = Get-Date "12/12/2017"


#emial server to send out post-run email
$emailServer = "129.1.16.2"

# The $ListName is the name of the list that is located at the URL $ListLocation
$ListName = "Optima Deployment"
$ListLocation = "http://lccavs/team/it/ProjMgmt/"

# Location of the excel file 
$ExcelFile = 'http://lccavs/team/it/ProjMgmt/Shared%20Documents/Optima%20Therapy/APIs%20and%20Interfaces/Optima%20Role%20mapping.xlsx'
#$ExcelFile = 'C:\Users\kevpatellcdev\Downloads\Optima Role mapping.xlsx'
$SheetName = 'Role Mapping'

try{

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

Write-Host "Facility list retrieved from the SharePoint..."

#A boolean that is set if there was some problem when adding roles to any user
$hasErrors = $false

#A boolean that is set if and only if we have actually done any work
$doemail = $false

#Create empty string to log errors and items
$errorLog = ""
$trainingLog = ""
$goLiveLog = ""

#Set name of the log files and remove existing log files with same date
$errorfile = ('OptimaErrorLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')
$trainingUsersLog  = ('TrainingUsersLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')
$goLiveUsersLog  = ('GoLiveUsersLog-' + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + '.txt')
if (Test-Path -Path ("C:\OptimaRoleMapping\"+$errorfile))
{
    Remove-Item -Path ("C:\OptimaRoleMapping\"+$errorfile)
}
if (Test-Path -Path ("C:\OptimaRoleMapping\"+$trainingUsersLog))
{
    Remove-Item -Path ("C:\OptimaRoleMapping\"+$trainingUsersLog)
}
if (Test-Path -Path ("C:\OptimaRoleMapping\"+$goLiveUsersLog))
{
    Remove-Item -Path ("C:\OptimaRoleMapping\"+$goLiveUsersLog)
}

#Select all the items in the list that do not have a null Pre-implementation date
$facilitylist = $facilitylist | where {$_.Training -ne $null -and $_.Go_x0020_Live -ne $null}

#Select only the items that have a matching training date
$training = $facilitylist| Where {$_.Training.Date -eq $Date}

#Select only the items that have a matching Go-live date
$golive = $facilitylist | Where {$_.Go_x0020_Live.Date -eq $Date}

#Get AD facility groups matching entityID with CorpID from the list for pre-implementation
$trainingfacilities = $training | foreach {Get-QADGroup -LdapFilter "(entityID=$($_.CorpID))"}

#Get AD facility groups matching entityID with CorpID from the list for go-live
$golivefacilities = $golive | foreach {Get-QADGroup -LdapFilter "(entityID=$($_.CorpID))"}

#Get training members of the AD facility groups excluding test, kiosk, and tablet users
$traininguserslist = $trainingfacilities | foreach {Get-QADGroupMember -Identity $_ -LdapFilter "(&(!cn=*test*)(!cn=*kiosk*)(!cn=*tablet*)(!cn=*abaqis*))"}

#Get go live members of the AD facility groups
$goliveuserslist = $golivefacilities | foreach {Get-QADGroupMember -Identity $_ -LdapFilter "(&(!cn=*test*)(!cn=*kiosk*)(!cn=*tablet*)(!cn=*abaqis*))"}

Write-Host "Facility users retrieved from AD..."

#Open excel file in read-only mode and pull in the 'Role Mapping' worksheet
$objExcel = New-Object -ComObject Excel.Application
$Workbook = $objExcel.Workbooks.Open($ExcelFile, $false, $true)
$Sheet = $Workbook.Worksheets.Item($SheetName)

#Count max row
$rowMax = ($Sheet.UsedRange.Rows).count

#Declare the starting positions
$rowADRole,$colADRole = 1,3
$rowTrainingADRole,$colTrainingADRole = 1,6
$rowGoLiveADRole,$colGoLiveADRole = 1,7

Write-Host "Rows retrieved from the excel file..."

Write-Host "Modifying users AD groups..."

}
Catch
{
    $hasErrors = $true
    $errorLog += ("ERROR: " + $_.Exception.Message + "`r`n")
    return
}
#loop through each AD group and modify users' groups
    
    if ($trainingfacilities -ne $null -or $golivefacilities -ne $null)
    {
            for($i=2; $i -le $rowMax-2; $i++)
            {
                $doemail = $true
                $ADRole = $Sheet.Cells.Item($rowADRole+$i,$colADRole).text
                $TrainingADRole = $Sheet.Cells.Item($rowTrainingADRole+$i,$colTrainingADRole).text
                $GoLiveADRole = $Sheet.Cells.Item($rowGoLiveADRole+$i,$colGoLiveADRole).text

                #Reads excel groups and then gets group identities from AD
                $ADRole = $ADRole | ForEach-Object {Get-QADGroup -Identity $_}
                $TrainingADRole = $TrainingADRole | ForEach-Object {Get-QADGroup -Identity $_} 
                $GoLiveADRole = $GoLiveADRole | ForEach-Object {Get-QADGroup -Identity $_}                     

                        if ($ADRole -ne $null -and $TrainingADRole -ne $null)
                        {
                            #Gets users identities from AD that are member of AD Role groups
                            $trainingusers = $traininguserslist | foreach {Get-QADUser -Identity $_ -LdapFilter "(&(objectCategory=user)(memberof=$($ADRole.DN)))"} | Sort -Unique

                            foreach ($traininguser in $trainingusers)
                            {
                            try {
                
                                    Write-Host $traininguser.Name `t Removing From: $ADRole.Name `t Adding To: $TrainingADRole.Name
                                    
                                    #Two lines below will add user to the training group and remove from AD role group

                                    ###Add-QADMemberOf -Identity $traininguser -Group $TrainingADRole.Name
                                    ###Remove-QADMemberOf -Identity $traininguser -Group $ADRole.Name
                                }
                                catch {
                                    $hasErrors = $true
                                    $errorLog += ("ERROR: " + $traininguser.Name + " could NOT be moved To: " + $TrainingADRole.Name + " " + $_.Exception.Message + "`r`n")

                                    return

                                }

                                $trainingLog += ($traininguser.Name + "`t Removed From: " + $ADRole.Name + "`t Added To: " + $TrainingADRole.Name + "`r`n")
                            }
                                                   
                        }
                        
                        if ($TrainingADRole -ne $null -and $GoLiveADRole -ne $null)
                        {
                            #Gets users identities from AD that are member of training AD Role groups
                            $goliveusers = $goliveuserslist | foreach {Get-QADUser -Identity $_ -LdapFilter "(&(objectCategory=user)(memberof=$($TrainingADRole.DN)))"}| Sort -Unique
                       
                            foreach ($goliveuser in $goliveusers)
                            {
                            try {
                
                                    Write-Host $goliveuser.Name `t Removing From: $TrainingADRole.Name `t Adding To: $GoLiveADRole.Name

                                    #Two lines below will add user to the golive group and remove from training AD role group

                                    ###Add-QADMemberOf -Identity $goliveuser -Group $GoLiveADRole.Name
                                    ###Remove-QADMemberOf -Identity $goliveuser -Group $TrainingADRole.Name
                                }
                                catch {
                                    $hasErrors = $true
                                    $errorLog += ("ERROR: " + $goliveuser.Name + " could NOT be moved To: " + $GoLiveADRole.Name + " " + $_.Exception.Message + "`r`n")

                                    return

                                }

                                $goLiveLog += ($goliveuser.Name + "`t Removed From: " + $TrainingADRole.Name + "`t Added To: " + $GoLiveADRole.Name + "`r`n")
                            }
                                                   
                        }       
            }

            #Adds values to the log files
            Add-Content -value $trainingLog -Path ("C:\OptimaRoleMapping\"+$trainingUsersLog)
            Add-Content -value $goLiveLog -Path ("C:\OptimaRoleMapping\"+$goLiveUsersLog)                       
     }

 
#close excel file
$Workbook.Close()
$objExcel.Quit()
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet)
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook)
[void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel)
[GC]::Collect()

#if there are errors, it will send error log file in the email
if ($hasErrors) {
        
    Add-Content -Value $errorLog -Path ("C:\OptimaRoleMapping\"+$errorfile)

	#Set the body of the email
    $body = ("The script ran with issues. The attached files has a list of the users that have been moved to their specified AD groups. There were some problems with the rollout. More information can be found in the attached file named $errorfile")

	#Send the email
    Send-MailMessage -From "kevin_patel@lcca.com" -To "Kevin_Patel@lcca.com","Charles_Arnold@lcca.com","DeeAnn_Pullen@lcca.com","Manoj_Rajuladevi@lcca.com","Ben_Johns@lcca.com"  -Attachments ("C:\OptimaRoleMapping\trainingUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRoleMapping\goLiveUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRoleMapping\errorfile-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt") -Body $body -Subject "Optima Role Mapping Script" -SmtpServer $emailServer 

} elseif ($doemail) {
   
	#Set the body of the email
    $body = ("The script ran with no issues. The attached files has a list of the users that have been moved to their specified AD groups. If a file is empty, it means there was no data to be processed.")

	#Send the email
    Send-MailMessage -From "kevin_patel@lcca.com" -To "Kevin_Patel@lcca.com","Charles_Arnold@lcca.com","DeeAnn_Pullen@lcca.com","Manoj_Rajuladevi@lcca.com","Ben_Johns@lcca.com" -Attachments ("C:\OptimaRoleMapping\trainingUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt"),("C:\OptimaRoleMapping\goLiveUsersLog-" + $Date.Month + "-" + $Date.Day + "-" + $Date.Year + ".txt") -Body $body -Subject "Optima Role Mapping Script" -SmtpServer $emailServer
}
 
$ScriptEnd = (Get-Date)
$RunTime = New-Timespan -Start $ScriptStart -End $ScriptEnd
“Elapsed Time: {0}:{1}:{2}” -f $RunTime.Hours,$Runtime.Minutes,$RunTime.Seconds