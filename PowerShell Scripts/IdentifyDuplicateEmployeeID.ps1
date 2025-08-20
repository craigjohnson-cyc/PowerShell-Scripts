#This script will read the latest 2 files in the HCA\OutGoingProcess folder
# and will produce a list of Employee ID's that occur more than once

Function Main
{
    $logFileLocation = "\\pes1\esss\Craig\HCA Notes\DupSearchLogs\"
    $fileLocation = "\\fs3\edrive\MIRTH\conf\Files\HCA\OutgoingProcessed\"
    $fileNames = gci -Path $fileLocation | sort LastWriteTime | select -last 2
    foreach ($file in $fileNames)
    {
        $msg = "Processing File {0}" -f $file.Name
        Logger -color "yellow" -string "$msg"
        $fileToProcess = $fileLocation + $file.Name

        #Read the CSV file
        $userFeedData = Import-Csv $fileToProcess -Delimiter '|'
        $kount = $userFeedData | measure
        $recordKount = $kount.Count
        $currentEmployeeID = ''
        $currentRec = 0


        for($i = 0; $i -lt $recordKount - 1; $i++)
        {
            $initialEmployeeID = $userFeedData[$i].employeeid
            $initialRecord = $userFeedData[$i]

            for($x= $i + 1; $x -lt $recordKount - 1; $x++)
            {
                #if($initialEmployeeID = $userFeedData[$x].employeeid
                if($userFeedData[$i].employeeid -eq $userFeedData[$x].employeeid)
                {
                    #Duplicate Employee ID found!!
                    $msg = "Duplicate Employee ID found {0}" -f $userFeedData[$i].employeeid
                    Logger -color "yellow" -string "$msg"
                    $msg = "    Line {0}: {1}" -f $i, $userFeedData[$i]
                    Logger -color "yellow" -string "$msg"
                    $msg = "    Line {0}: {1}" -f $x, $userFeedData[$x]
                    Logger -color "yellow" -string "$msg"
                    $msg = " "
                    Logger -color "yellow" -string "$msg"
                }
            }

            $a = 'stop here'
        }
        $msg = " "
        Logger -color "yellow" -string "$msg"

    }
}

# Function to log and output information
Function Logger {
    param(
        [string] $string = "",
        [string] $color = "White"
    )
    Write-Host -ForegroundColor $color $string
    $ReportDate = Get-Date -Format "MMddyyyy"
    $logFile = $logFileLocation + "DuplicateEmployeeIDsSentToHCA_" + $ReportDate + ".log"
    Add-Content -Path $logFile -value $string
}


Main