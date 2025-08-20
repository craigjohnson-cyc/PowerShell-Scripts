param ([Parameter(Mandatory=$true)][String] $jobTitle)
Import-module activedirectory

# This Script will:
# •	Accept at runtime an input paramter for Job Title, Quotes are not needed
# •	Scan Active Directory and generate a list of users with a job title that contains the 
#     input value
# •	Save list of users to a CSV file titled input value dot csv
# •	Present list of users in an Excel like grid


Function Main
{
    #$JobTitle = 'Dietary Aide'
    Write-Host $JobTitle

    $userList = @()
    $userList = Get-ADUser -Filter "(enabled -eq 'True') -and (Title -like '*$JobTitle*')" -properties Office,GivenName,Initials,Surname,Title,mail,Company,Department| 
        Select @{name="Facility ID";Expression={(Get-ADOrganizationalUnit -Filter 'name -eq $_.office' -properties entityid).entityid}},
        @{Name="Facility Name";Expression={$_.Office}},
        @{Name="First Name";Expression={$_.GivenName}},
        @{Name="Middle Initials";Expression={$_.Initials}}, 
        @{Name="Last Name";Expression={$_.Surname}}, 
        @{Name="Job Title";Expression={$_.Title}},
        @{Name="Email";Expression={$_.mail}},
        @{Name="Division";Expression={$_.Company}},
        @{Name="Region";Expression={$_.Department}},
        @{name="State";Expression={(Get-ADOrganizationalUnit -Filter 'name -eq $_.office' -properties State).state}}
        
    $userList | export-csv c:\ps\output\$JobTitle.csv  -NoTypeInformation

    $userList | ogv

  }

# Script Begins Here - Execute Function Main
Main