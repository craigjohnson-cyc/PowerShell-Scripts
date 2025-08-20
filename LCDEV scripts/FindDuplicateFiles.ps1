#clr
# DEV
#$newFiles = Get-ChildItem -Path \\dfs3\xfer\ReportSafe\sofcare\prTemp -Name
#$archiveFiles = Get-ChildItem -Path \\dfs3\xfer\ReportSafe\sofcare\prTemp\Archive -Name
#--------------------------------------------------------------------------------------

#Production
$newFiles = Get-ChildItem -Path \\fs3\xfer\ReportSafe\keane -Name
$archiveFiles = Get-ChildItem -Path \\fs3\xfer\ReportSafe\keane\Archive -Name
#--------------------------------------------------------------------------------------



$duplicateFiles = @()
ForEach($nFile in $newFiles)
{
    ForEach($afile in $archiveFiles)
    
    {
        #if ($nFile + ".PRS" -eq $afile)
        if ($nFile -eq $afile)
        {
            $duplicateFiles+=$nFile
            break
        }
    }
}
$duplicateFiles