Function Main
{
    $checks = import-csv “C:\Powershell Scripts\PaidChecks_Summary.csv”
    foreach($check in $checks)
    {
        $check
        $a = $check.ImagePath -replace '/', '\'
        $a
    }
}

Main