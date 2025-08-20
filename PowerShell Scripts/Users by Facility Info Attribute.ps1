#$list = 
Get-ADGroupMember -identity "Hixson" -Recursive | Get-ADUser -Property Info,DisplayName,title | Select Name, SamAccountName, title,Info | Export-csv "C:\Users\cjohnson\HixsonUsers.csv"