# UpdatePortal4SourceControl
#---------------------------
#
# This script was created to copy the production copy of the Kasai NA Portal
# to the developer's local location prior to Source Control Check In.
# This is necessary because as of 10/10/23 I am not able to map to the 
# network location where the portal lives
#
#----------------------------------------------------------------------------



Function Main
{


    #  Per Steve Feb 21, 2024 Backup everything under \\corpweb01\web
    #----------------------------------------------------------------
    #Copy-Item -Path "\\corpweb01\web\*" -Destination "C:\Development2\Kasai_Intranet_Portal\web" -Recurse -Force

    $excludes = "Archived","history","logs","temp","wwwroot"
    Get-ChildItem "\\corpweb01\web" -Directory | 
        Where-Object{$_.Name -notin $excludes} | 
            Copy-Item -Destination "C:\Development2\Kasai_Intranet_Portal\web" -Recurse -Force


}
Function Old_Code
{
    #Copy dir App_Code
    #-----------------
    Copy-Item -Path "\\corpweb01\web\AddItUp\*" -Destination "C:\Development2\Kasai_Intranet_Portal\AddItUp" -Recurse -Force

    #Copy dir Bin
    #------------
    Copy-Item -Path "\\corpweb01\web\MTEK\Bin\*" -Destination "C:\Development2\Kasai_Intranet_Portal\Bin" -Recurse -Force

    #Copy dir Calendars
    #------------------
    Copy-Item -Path "\\corpweb01\web\MTEK\Calendars\*" -Destination "C:\Development2\Kasai_Intranet_Portal\Calendars" -Recurse -Force

    #Copy dir fonts
    #--------------
    Copy-Item -Path "\\corpweb01\web\MTEK\fonts\*" -Destination "C:\Development2\Kasai_Intranet_Portal\fonts" -Recurse -Force

    #copy dir HeadlineNews
    #---------------------
    Copy-Item -Path "\\corpweb01\web\MTEK\HeadlineNews\*" -Destination "C:\Development2\Kasai_Intranet_Portal\HeadlineNews" -Recurse -Force

    #copy dir help
    #-------------
    Copy-Item -Path "\\corpweb01\web\MTEK\help\*" -Destination "C:\Development2\Kasai_Intranet_Portal\help" -Recurse -Force

    #copy dir media
    #--------------
    Copy-Item -Path "\\corpweb01\web\MTEK\media\*" -Destination "C:\Development2\Kasai_Intranet_Portal\media" -Recurse -Force

    #Copy dir OEE
    #------------
    Copy-Item -Path "\\corpweb01\web\MTEK\OEE\*" -Destination "C:\Development2\Kasai_Intranet_Portal\OEE" -Recurse -Force

    #copy dir Scripts
    #----------------
    Copy-Item -Path "\\corpweb01\web\MTEK\scripts\*" -Destination "C:\Development2\Kasai_Intranet_Portal\scripts" -Recurse -Force

    #copy dir Sites
    #--------------
    Copy-Item -Path "\\corpweb01\web\MTEK\Sites\*" -Destination "C:\Development2\Kasai_Intranet_Portal\Sites" -Recurse -Force

    #copy dir styles
    #---------------
    Copy-Item -Path "\\corpweb01\web\MTEK\styles\*" -Destination "C:\Development2\Kasai_Intranet_Portal\Styles" -Recurse -Force

    #copy all files
    #--------------
    Copy-Item -Path "\\corpweb01\web\MTEK\*.html" -Destination "C:\Development2\Kasai_Intranet_Portal" -Recurse -Force
    Copy-Item -Path "\\corpweb01\web\MTEK\*.aspx" -Destination "C:\Development2\Kasai_Intranet_Portal" -Recurse -Force
    Copy-Item -Path "\\corpweb01\web\MTEK\*.ascx" -Destination "C:\Development2\Kasai_Intranet_Portal" -Recurse -Force
    Copy-Item -Path "\\corpweb01\web\MTEK\*.master" -Destination "C:\Development2\Kasai_Intranet_Portal" -Recurse -Force
    Copy-Item -Path "\\corpweb01\web\MTEK\*.htm" -Destination "C:\Development2\Kasai_Intranet_Portal" -Recurse -Force
    Copy-Item -Path "\\corpweb01\web\MTEK\*.config" -Destination "C:\Development2\Kasai_Intranet_Portal" -Recurse -Force
}

# Script Begins Here - Execute Function Main
Main 