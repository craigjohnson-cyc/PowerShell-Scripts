    \\Creating AES key with random data and export
$KeyFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\AES.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile




   \\Creating SecureString Object
$PasswordFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\DataRelayAuth.txt"
$KeyFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\AES.key"
$Key = Get-Content $KeyFile
$Password = "d35%FJ923ls78/*333##()#" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile


  \\Creating SecureString Object
$PasswordFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\SharePointAuth.txt"
$KeyFile = "\\pes1\esss\Craig\PowerShell Scripts\PCCWoundReport\AES.key"
$Key = Get-Content $KeyFile
$Password = "Mojo^007" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
