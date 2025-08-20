    #Creating AES key with random data and export
$KeyFile = "C:\Development2\Powershell Scripts\Keys\MURadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development2\Powershell Scripts\Keys\MURadmin.txt"
$KeyFile = "C:\Development2\Powershell Scripts\Keys\MURadmin.key"
$Key = Get-Content $KeyFile  
$Password = "MUR@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#------------------------------------

    #Creating AES key with random data and export
$KeyFile = "C:\Development\PowerShellScripts\Keys\PRAadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development\PowerShellScripts\Keys\PRAadmin.txt"
$KeyFile = "C:\Development\PowerShellScripts\Keys\PRAadmin.key"
$Key = Get-Content $KeyFile  
$Password = "PRA@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#------------------------------------

    #Creating AES key with random data and export
$KeyFile = "C:\Development\PowerShellScripts\Keys\MANadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development\PowerShellScripts\Keys\MANadmin.txt"
$KeyFile = "C:\Development\PowerShellScripts\Keys\MANadmin.key"
$Key = Get-Content $KeyFile  
$Password = "MAN@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#------------------------------------

    #Creating AES key with random data and export
$KeyFile = "C:\Development\PowerShellScripts\Keys\MADadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development\PowerShellScripts\Keys\MADadmin.txt"
$KeyFile = "C:\Development\PowerShellScripts\Keys\MADadmin.key"
$Key = Get-Content $KeyFile  
$Password = "MAD@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#------------------------------------

    #Creating AES key with random data and export
$KeyFile = "C:\Development\PowerShellScripts\Keys\UPPadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development\PowerShellScripts\Keys\UPPadmin.txt"
$KeyFile = "C:\Development\PowerShellScripts\Keys\UPPadmin.key"
$Key = Get-Content $KeyFile  
$Password = "UPP@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#------------------------------------

    #Creating AES key with random data and export
<#
$KeyFile = "C:\Development\PowerShellScripts\Keys\SMYadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development\PowerShellScripts\Keys\SMYadmin.txt"
$KeyFile = "C:\Development\PowerShellScripts\Keys\SMYadmin.key"
$Key = Get-Content $KeyFile  
$Password = "SMY@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#------------------------------------
#>

    #Creating AES key with random data and export
$KeyFile = "C:\Development\PowerShellScripts\Keys\TALadmin.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

   #Creating SecureString Object
$PasswordFile = "C:\Development\PowerShellScripts\Keys\TALadmin.txt"
$KeyFile = "C:\Development\PowerShellScripts\Keys\TALadmin.key"
$Key = Get-Content $KeyFile  
$Password = "TAL@dm1n" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile

