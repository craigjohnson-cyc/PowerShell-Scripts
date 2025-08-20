# ArchiveIDFLV1_POs
#------------------
#
# This script was created to move PDF files found in \\idflv1\SWP\PO
# to folders based on their creation date.  i.e.,  \\idflv1\SWP\PO\2022.
#
# This script really needs to be run locally on IDFLV1 due to performance
# reasons.
#
# TODO: Modify script to detect where it is being executed, if run on IDFLV1
#       Then use Drive reference i.e.,  d:\SWP\PO
#
#----------------------------------------------------------------------------



Function Main
{

    #Archive 2023
    #------------

    [datetime]$start = '2023-01-01 00:00:00'
    [datetime]$end = '2024-01-01 00:00:00'

    Get-ChildItem "\\idflv1\SWP\PO\*.pdf" | 
            Where-Object { $_.LastWriteTime -gt $start -and $_.LastWriteTime -lt $end } | 
            Move-Item -Destination "\\idflv1\SWP\PO\2023\" -Force

    #Archive 2022
    #------------

    #[datetime]$start = '2022-01-01 00:00:00'
    #[datetime]$end = '2023-01-01 00:00:00'

    #Get-ChildItem "\\idflv1\SWP\PO\*.pdf" | 
    #        Where-Object { $_.LastWriteTime -gt $start -and $_.LastWriteTime -lt $end } | 
    #        Move-Item -Destination "\\idflv1\SWP\PO\2022\" -Force

    #Archive 2021
    #------------

    #[datetime]$start = '2021-01-01 00:00:00'
    #[datetime]$end = '2022-01-01 00:00:00'

    #Get-ChildItem "\\idflv1\SWP\PO\*.pdf" | 
    #        Where-Object { $_.LastWriteTime -gt $start -and $_.LastWriteTime -lt $end } | 
    #        Move-Item -Destination "\\idflv1\SWP\PO\2021\" -Force

    #Archive 2020
    #------------

    #[datetime]$start = '2020-01-01 00:00:00'
    #[datetime]$end = '2021-01-01 00:00:00'

    #Get-ChildItem "\\idflv1\SWP\PO\*.pdf" | 
    #        Where-Object { $_.LastWriteTime -gt $start -and $_.LastWriteTime -lt $end } | 
    #        Move-Item -Destination "\\idflv1\SWP\PO\2020\" -Force

}


# Script Begins Here - Execute Function Main
Main 