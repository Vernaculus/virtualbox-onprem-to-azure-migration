param($DomainName, $NetBiosName, $SafeModePassword)
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
$SecurePwd = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
Install-ADDSForest -DomainName $DomainName -DomainNetbiosName $NetBiosName `
  -SafeModeAdministratorPassword $SecurePwd -InstallDns -Force -NoRebootOnCompletion