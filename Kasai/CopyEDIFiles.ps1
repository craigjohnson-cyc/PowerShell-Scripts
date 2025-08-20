# CopyEDIFiles
#-------------
#
# This script was created to copy EDI files from one server to another.
#
#----------------------------------------------------------------------


Function Main
{
\\mtek-ms\apps\RECEIVEEDI\
\\mtek-ms\apps\LexFolder\INBOX

#  \\alapps\RECEIVEEDI\MSFILES

    #Copy files found in 
    #-------------------
    Copy-Item -Path "\\alapps\RECEIVEEDI\MSFILES\*" -Destination "C:\Development2\Kasai_Intranet_Portal\AddItUp" -Recurse -Force

    #Remove copied files
    #-------------------
    Remove-Item "\\alapps\RECEIVEEDI\MSFILES\"
}


# Script Begins Here - Execute Function Main
Main 