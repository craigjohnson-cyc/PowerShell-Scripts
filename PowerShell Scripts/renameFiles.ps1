$files = Get-ChildItem -Filter “*Omnicare_COVID_19_MPR_Temlate_20210103*” -Recurse 
foreach($f in $files)
{
    $newName = "01032021_" + $f.Name.Substring(0,4) + "_Omnicare_COVID_19_MPR_Temlate.xlsx"
    $oldFile = "\\pes1\esss\Powershell Scripts\Output\WoundReports\" + $f.name
    Rename-Item -Path $oldFile -NewName $newName
}

#| Rename-Item -NewName {$_.name -replace ‘current’,’old’ } 

Get-ChildItem -Filter “*Temlate*” -Recurse | Rename-Item -NewName {$_.name -replace ‘Temlate’,’Template’ }