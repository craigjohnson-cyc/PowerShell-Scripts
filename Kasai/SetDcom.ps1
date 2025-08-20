Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Ole' -Name 'LegacyImpersonationLevel' -Value '2'

Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Ole'
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Ole'

Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Ole'

Get-WMIObject -Class Win32_DCOMApplicationSetting -Filter 'Description="%EnableDCOM%"'


Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Ole' -Name 'LegacyImpersonationLevel' -Value '2'