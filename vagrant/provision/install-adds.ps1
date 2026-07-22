param($DomainName, $NetBiosName, $SafeModePassword)

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Install-ADDSForest is unreliable when run directly inside a remote
# WinRM session (known issue: misleading "argument not recognized"
# errors). Running it via a local scheduled task as SYSTEM avoids this.
#
# NOTE: SecureString objects created via Export-Clixml/ConvertTo-SecureString
# are encrypted with DPAPI keys tied to the specific user + machine context
# that created them. A scheduled task running as SYSTEM cannot decrypt a
# SecureString exported under the 'vagrant' user context, so the password
# is passed directly as a task argument instead.
$scriptBlock = @'
param($DomainName, $NetBiosName, $SafeModePassword)
try {
    $SecurePwd = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
    Install-ADDSForest -DomainName $DomainName -DomainNetbiosName $NetBiosName `
      -SafeModeAdministratorPassword $SecurePwd -InstallDns -Force `
      -ErrorAction Stop *>> C:\tmp\addsforest-result.log
}
catch {
    $_ | Out-File -FilePath C:\tmp\addsforest-result.log -Append
    $_ | Out-File -FilePath C:\tmp\addsforest-error.txt
}
'@
$scriptBlock | Out-File -FilePath C:\tmp\run-addsforest.ps1 -Encoding UTF8

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-ExecutionPolicy Bypass -File C:\tmp\run-addsforest.ps1 -DomainName $DomainName -NetBiosName $NetBiosName -SafeModePassword '$SafeModePassword'"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)

Register-ScheduledTask -TaskName "PromoteADForest" -Action $action -Principal $principal -Trigger $trigger -Force
Start-ScheduledTask -TaskName "PromoteADForest"

Write-Host "Forest promotion task started. Server will reboot automatically on success."
Write-Host "Run 'vagrant reload ad-dc' after a short wait, then verify with Get-ADDomain."