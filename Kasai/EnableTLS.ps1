Regsvr32 "c:\program files (x86)\common files\microsoft shared\DAO\Dao350.dll"
Regsvr32 "C:\Program Files (x86)\Common Files\Microsoft Shared\VBA\MRT7ENU.dll"
Regsvr32 "C:\Program Files (x86)\Common Files\Microsoft Shared\VBA\MSO97RT.dll"

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'


    New-Item ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server’ -Force
    New-Item ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client’ -Force
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server’ -Name ‘Enabled’ -Value ‘0xffffffff’ –PropertyType DWORD
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server’ -Name ‘DisabledByDefault’ -Value 0 –PropertyType DWORD
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client’ -Name ‘Enabled’ -Value 1 –PropertyType DWORD
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client’ -Name ‘DisabledByDefault’ -Value 0 –PropertyType DWORD
    

        New-Item ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server’ -Force
    New-Item ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client’ -Force
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server’ -Name ‘Enabled’ -Value ‘0xffffffff’ –PropertyType DWORD
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server’ -Name ‘DisabledByDefault’ -Value 0 –PropertyType DWORD
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client’ -Name ‘Enabled’ -Value 1 –PropertyType DWORD
    New-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client’ -Name ‘DisabledByDefault’ -Value 0 –PropertyType DWORD
   

   [Net.ServicePointManager]::SecurityProtocol
   [enum]::GetNames([System.Net.SecurityProtocolType])


   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'

   Get-TlsCipherSuite