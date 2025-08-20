Add-Type -AssemblyName System.IO.Compression.FileSystem

Function Main
{
# This Script will:
# •	provide a means to help with the bulk approval of PCC user feed
# •	
# •	

# Get list of PCC User Feed Runs
$userFeedRuns = Get-Runs

$firstDisplayed = 0
$totalRuns = ($userFeedRuns | measure).Count
Set-AppColors


Do
{
    Clear-Host
    $title = "PCC User Feed Review"
    Display-AppHeader $title

    #Determine the 10 User Feed Runs to be displayed
    $kounter = 0
    $list = @()
    For ($i=$firstDisplayed; $i -lt $totalRuns ;$i++)
    {
        $kounter ++
        if ($kounter -ge 11)
        {
            break
        }
        $txt = $kounter.ToString() + ". " + $userFeedRuns[$i].LastWriteTime.ToString()
        $list += $txt

    }


    $list += ""
    $list += "P. Previous Page"
    $list += "N. Next Page"
    $list += "Q. Quit application"
    $list += ""

    $list

    $selection = Read-Host -Prompt "Select which User Feed run to Review"

    switch ($selection)
    {
        "P"
        {
            if($firstDisplayed -le 10)
            {
                $firstDisplayed = 0
            }
            else
            {
                $firstDisplayed -= 10
            }
        }
        "N"
        {
            if($firstDisplayed -ge ($totalRuns - 9))
            {
                $firstDisplayed = $totalRuns - 10
            }
            else
            {
                $firstDisplayed += 10
            }
        }
        "Q"
        {
            Clear-Host
            Pop-Location
            break
        }
        default
        {
        if([int]$selection -lt 0 -or [int]$selection -gt 10) 
        {
            continue
        }
        $item = ($selection - 1) + $firstDisplayed
        $runDay = $userFeedRuns[$item].LastWriteTime.ToString()
        LookAtBatch $userFeedRuns[$item].PSPath $userFeedRuns[$item].LastWriteTime $userFeedRuns[$item].Name

        }
    }

} while ($selection -ne "Q")


}

Function LookAtBatch
{
    param ($filePath, $batch, $fileName)

    #Check for existance of local work folder (Create if needed)
    if( -not(Test-Path 'C:\PS\Output'))
    {
        if( -not(Test-Path 'C:\PS'))
        {
            md -Path 'C:\PS'
        }
        md -Path 'C:\PS\Output'
    }
    $workPath = "C:\PS\Output\" + (Get-ChildItem $filePath).BaseName
    if( -not(Test-Path $workPath))
    {
        md -Path $workPath
    }
    
    #Copy the zip file from the network location to local
    Copy-Item -Path $filePath -Destination $workPath
    Push-Location $workPath

    #Unzip local copy
    [System.IO.Compression.ZipFile]::ExtractToDirectory($workPath + "\" + $fileName, $workPath)

    #Display memu of CSV files
    $csvList = Get-ChildItem *.csv -Recurse | select Name, LastWriteTime, PSPath
    
    Clear-Host
    $title = "CSV files from $batch PCC User Feed"
    Display-AppHeader $title

    $kounter = 0
    $list = @()
    foreach($csvFile in $csvList)
    {
        $txt = $kounter.ToString() + ". " + $csvFile.Name
        $list += $txt
        $kounter ++
    }
    $kounter = 5 + ((($csvList | measure).Count % 5)-1)
    for($i = 1; $i -le $kounter; $i++) {$list += ""}
    $list += "Q. Quit (Return to previous menu)"

    $list | Format-Wide {$_} -AutoSize -Force
}


Function Get-Runs
{
    Push-Location "\\fs3.lcca.net\edrive\MIRTH\conf\Files\PCC\Output\LCCA"
    $RunList = Get-ChildItem *.zip -Recurse | Sort-Object -Property LastWriteTime -Descending| select Name, LastWriteTime, PSPath

    return $RunList
}

function Display-AppHeader ($title)
{
<#
    .SYNOPSIS
    Displays a title surrounded by *'s
    
    .DESCRIPTION
    Displays the passed in title, centered on the screen and
    surrounded by a nice frame.
    
    .PARAMETER title
    The title you want displayed
    
    .NOTES
    Required the Get-WindowWidth function.
#>

    # make sure a title was passed in and has a minimum length
    if ($title.Length -lt 2) {$title = $title + " "}
    
    $ww = (Get-WindowWidth) - 4 #2 for the *'s and 2 for a gap
    if (($title.Length % 2) -ne 0)
        {$title = $title + " "}
        
    $pad = " " * (($ww - $title.Length) / 2)
    
    "*" + "-" * $ww + "*"
    
    Write-Host -NoNewline "*"
    Write-Host -NoNewline $pad
    Write-Host -NoNewline -ForegroundColor "White" $title
    Write-Host -NoNewline $pad
    Write-Host "*"
    
    "*" + "-" * $ww + "*"
}


function Get-WindowWidth
{
<#
    .SYNOPSIS
    Returns the width of the current window.
    
    .DESCRIPTION
    If running in the ISE, the max windoes size will be null.  If so,
    retrun a default of 80.  Otherwise return the true window width.
#>
    If ($host.UI.RawUI.MaxWindowSize -eq $null)
    {
        $windowWidth = 80
    }
    else
    {
        $windowWidth = $host.UI.RawUI.MaxWindowSize.Width
    }
    return $windowWidth
}


function Set-AppColors
{
<#
    .SYNOPSIS
    Sets the application colors.
    
    .DESCRIPTION
    The function determines whether it's running in the ISE or a Window,
    Then sets the colors and window title appropriately.
#>
    if ($psise -eq $null)
    {
        $host.UI.RawUI.BackgroundColor = "Black"
        $host.UI.RawUI.ForegroundColor = "Green"
        $host.UI.RawUI.WindowTitle = "PCC User Feed Review Tool"
    }
    else
    {
        $psISE.Options.ConsolePaneBackgroundColor = "Black"
        #$psise.Options.OutputPaneBackgroundColor = "Black"
        $psISE.Options.ConsolePaneTextBackgroundColor = "Black"
        #$psise.Options.OutputPaneTextBackgroundColor = "Black"
        $psISE.Options.ConsolePaneTextBackgroundColor = "Black"
        #$psise.Options.OutputPaneForegroundColor = "#FF00e000"  # Lightish Green
        #$psISE.Options.OutputPaneTextForegroundColor = "#FF00e000"  # Lightish Green
        $psISE.Options.ConsolePaneForegroundColor  = "#FF00e000"  # Lightish Green
        $host.UI.RawUI.WindowTitle = "Putting it all together"
    }
}


# Script Begins Here - Execute Function Main


Main