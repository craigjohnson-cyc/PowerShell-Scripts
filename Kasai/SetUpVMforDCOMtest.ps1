# Include common Functions
#-------------------------
. c:\Development\PowerShellScripts\KasaiFunctions.ps1

Function Main
{
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

    # connect to tn_opctest
    #----------------------
    $computer = "tn-opctest"
    $creds = GetCredentials "MADadmin"
    if($creds -eq $null)
    {
        #No Action to be taken, Credential file not found
    }
    else
    {
        $session = New-PSSession -ComputerName $computer -Credential $creds
    
        # Create folders
        $sb = {
                mkdir C:\Development\PowerShellScripts
                mkdir C:\Development\PowerShellScripts\Logs
                mkdir C:\Development\PowerShellScripts\InputFiles
              }
        Invoke-Command –Session $session –ScriptBlock $sb
    
        # Copy DCOM_OPC_Setup.ps1 & KasaiFunctions.ps1
        #---------------------------------------------
        Copy-Item –Path C:\Development\PowerShellScripts\DCOM_OPC_Setup.ps1 –Destination 'C:\Development\PowerShellScripts\' –ToSession $session
        Copy-Item –Path C:\Development\PowerShellScripts\KasaiFunctions.ps1 –Destination 'C:\Development\PowerShellScripts\' –ToSession $session


        # copy registry files
        #--------------------
        $sb = {
            Copy-Item -Path \\tnnas01\mis\Software\Kepware\OPC.reg -Destination C:\Development\PowerShellScripts\InputFiles\opc.reg
            Copy-Item -Path \\tnnas01\mis\Software\Kepware\OPC-wow64.reg -Destination C:\Development\PowerShellScripts\InputFiles\OPC-wow64.reg
              }
        Invoke-Command –Session $session –ScriptBlock $sb



        #Execute DCOM_OPC_Setup.ps1
        #--------------------------
        $sb = {
                cd C:\Development\PowerShellScripts
                .\DCOM_OPC_Setup.ps1
              }
        Invoke-Command –Session $session –ScriptBlock $sb
    }

}

# Script Begins Here - Execute Function Main
Main