 
 CLS
 
   [string]$Group = 'PCC_OE_Implementation'
  [string]$Child = '0'
  $WorkFile = "c:\script\PCC_OE_Implementation.csv"
 

  $members= Get-ADGroupMember -Server LCCA.NET -Identity $Group  


 $output = foreach ($member in $members)

  {


  get-adgroup $member.Name -Server LCCA.NET -Properties *|Select SamAccountName,entityID



   }
  $output | export-csv $WorkFile

 

Invoke-Item -Path $WorkFile 