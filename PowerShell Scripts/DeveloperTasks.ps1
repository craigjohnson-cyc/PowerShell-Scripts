
#Clear-Host
$userName = $env:UserName
#"The current user name is: $userName"
$configFileLocation = "C:\Users\$userName\"
$configFile = "C:\Users\$userName\DeveloperTaskConfig.csv"

if (Test-Path $configFile)
{
    # Read Config Settings from file
    Push-Location $configFileLocation
    $ConfigValues = Import-Csv $configFile #| Out-Null
    $PSLib = $ConfigValues.PSLib
    $LDSlocation = $ConfigValues.LDSlocation
    $devLocation = $ConfigValues.devLocation
    $lccaUser = $ConfigValues.lccaUser

    #"Config Values: "
    #"PSLib: $PSLib "
    #"LDSlocation: $LDSlocation "
    #"devLocation:  $devLocation "
}
else
{
    # Get Config settings from user and save in file
    $msg = "It appears that this is the first time you have run this application.  Please enter some configuration data:"
    $msg
    $PSLib = Read-Host -Prompt "Enter the drive location where your PowerShell scripts reside: "
    $LDSlocation = Read-Host -Prompt "Enter the drive location where you save/work with LDS scripts: "
    $devLocation = Read-Host -Prompt "Enter the drive location where your Visual Studio projects reside: "
    $lccaUser = Read-Host -Prompt "Enter your LCCA user name: "

    $settings = New-Object PSObject
    $settings | add-member -type NoteProperty -Name PSLib -Value $PSLib
    $settings | add-member -type NoteProperty -Name LDSlocation -Value $LDSlocation
    $settings | Add-Member -type NoteProperty -Name devLocation -Value $devLocation
    $settings | Add-Member -type NoteProperty -Name lccaUser -Value $lccaUser

    $settings | export-csv -Path $configFile

}


if (Test-Path $PSLib\FuncLib.ps1)
{
    Import-Module $PSLib\FuncLib.ps1
}

$choice = "a"

$menu = @"
     1. Pawadan
     2. MS Word
     3. MS Excel
     4. Visual Studio Projects
     5. Text Crawler
     6. NotePad++
     7. User Feed Files
     8. SQL Management Studio
     9. Active Directory Users and Computers
    10. Assist Support Portal
    11. Bugzilla
    12. Sofcare LDS Enviroment 
    13. eMids Upload Site
    14. File Logs
    15. Emum Document
    16. Database Access Request Form
    17. My Network Share Folder
    18. Status Reports drop folder
    19. eMids Partner Site

     Q. Quit
    
"@

if (Test-Path $PSLib\FuncLib.ps1)
{
    Set-AppColors
}
else
{
    "File Not Found: $PSLib\FuncLib.ps1"
}

Do
{
    Clear-Host
    $title = "Developer Dashboard"
    if (Test-Path $PSLib\FuncLib.ps1)
    {
        Display-AppHeader $title
    }
    $menu

    $choice = Read-Host -Prompt "Select a Menu Option: "

    switch ($choice)
    {
        "1"       # Padawan
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("http://lccavs/team/it/TechOps/Lists/SQL%20Script%20%20ESS/AllItems.aspx#InplviewHashc24b9e1b-4dba-42cf-aa1e-91461c70bbae=SortField%3DRequest_x0020_Date-SortDir%3DDesc-WebPartID%3D%7BC24B9E1B--4DBA--42CF--AA1E--91461C70BBAE%7D")
                #$IE.visible=$true
                invoke-item $LDSlocation 
                Invoke-Item "C:\Users\$userName\AppData\Local\Apps\2.0\0Z69WX74.RB9\6Y0NMOD8.ACC\pada..tion_589417efcdffa630_0001.0000_2bd5f3747ba84057\Padawan.exe"
                break
            }
        "2"       # Word
            {
                $Word = New-Object -ComObject Word.Application
                $Document = $Word.Documents.Add()
                $Word.Visible = $True
                $Word.Activate()
                break
            }
        "3"       # Excel
            {
                $excel = New-Object -ComObject Excel.Application
                $WorkBook = $excel.Workbooks.Add()
                $excel.Visible = $True
                $excel.WindowActivate
                break
            }
        "4"       # Visual Studio Projects
            {
                #$mojo = VSProjectMenu
                $Projects = Get-VSProjects($devLocation)
                $t = $Projects.Count
                $title = "$t Work Tasks"

                $kounter = 0

                $list = @()
                foreach($item in $Projects) 
                {
                    $txt = $kounter.ToString() + ".  " +   $item.Project
                    $list += $txt
                    $kounter ++
                }
                
                $kounter = 5 + (($t % 5)-1)
                for($i = 1; $i -le $kounter; $i++) {$list += ""}
                $list += "Q. Quit (Return to previous menu)"

                #Set-AppColors
                Clear-Host
                Display-AppHeader $title

                $list | Format-Wide {$_} -AutoSize -Force
                #$list

                $selection = Read-Host -Prompt "Select a Menu Option: "

                if($selection -eq "q" -or $selection -eq "" -or $selection -eq $null)
                {
                    break
                }
                else
                {
                    $ItemToOpen = $Projects[$choice].Folder + $Projects[$choice].Project
                    Push-Location $Projects[$choice].Folder
                    Invoke-Item $ItemToOpen
                    Pop-Location
                    return truecc
                }
                break
            }
        "5"       # Text Crawler
            {
                Invoke-Item "C:\Program Files (x86)\TextCrawler Free\TextCrawler.exe"
                break
            }
        "6"       # Notepad++
            {
                Invoke-Item "C:\Program Files (x86)\Notepad++\notepad++.exe"
                break
            }
        "7"       # User Feed files
            {
                invoke-item "\\fs3\edrive\MIRTH\conf\Files" 
                $computer = $env:computername
                $s = New-PSSession -ComputerName $computer -Credential lcca\$lccaUser
                $s = New-PSSession -ComputerName web14x -Credential lcca\$lccaUser
                invoke-item "\\web14x\SSO ExceptionsLogs\" -Credential $s
                invoke-item "\\web14x\SSO ExceptionsLogs\"
                break
            }
        "8"       # SQL Management Studio
            {
                invoke-item "C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Ssms.exe"
                break
            }
        "9"       # Active Directory Users and Computers
            {
                invoke-item "$env:SystemRoot\system32\dsa.msc"
                break
            }
        
        "10"       # Support Portal   
            {
                $IE=new-object -com internetexplorer.application
                #$IE.navigate2("https://support.lcca.com/assystweb/application.do#welcome%2FWelcomeDispatchAction.do%3Fdispatch%3Drefresh")
                $IE.navigate2("http://lccavs/Applications/SitePages/SupportPortalSplash.aspx")
                $IE.Visible = $True
                break
            }
        "11"       # Bugzilla
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("https://bugzilla.lcca.net")
                $IE.Visible = $True
                break
            }
        "12"       # SofCare LDS Environment
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("https://xen.lcdev.net/Citrix/LCDEVWeb/")
                $IE.Visible = $True
                break
            }
        "13"       # eMids Upload Site
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("http://lccapartner/sites/eMids/Lists/Live%20Data%20Scripts/AllItems.aspx")
                $IE.Visible = $True
                break
            }
        "14"       # File Logs
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("http://lccavs/team/it/ES/Lists/File%20Logs/AllItems.aspx#InplviewHash84809e17-9886-4ef3-af25-2860acdbdff6=Paged%3DTRUE-p_ID%3D60-PageFirstRow%3D61")
                $IE.Visible = $True
                break
            }
        "15"       # Emums document
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("http://lccavs/team/it/ES/Shared%20Documents/Projects/SofCare2-Clinical%20Suite%20Documentation/Sofcare2%20EMR%20Enum%20List.xlsx")
                $IE.Visible = $True
                break
            }
        "16"       # Database Access Request Form
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("http://lccavs/team/it/TechOps/Lists/Database%20Security%20Request/AllItems.aspx")
                $IE.Visible = $True
                break
            }
        "17"       # My Network Share Location
            {
                Invoke-Item "\\pes1\esss\Craig"
            }
        "18"       # Status Reports drop folder
            {
                Invoke-Item "\\pes1\esss\Status Reports\Craig Johnson"
            }
        "19"       # eMids Partner Site
            {
                $IE=new-object -com internetexplorer.application
                $IE.navigate2("http://lccapartner/sites/eMids/Lists/Live%20Data%20Scripts/AllItems.aspx")
                $IE.Visible = $True
                break
            }

            
    }


} while ($choice -ne "Q")



