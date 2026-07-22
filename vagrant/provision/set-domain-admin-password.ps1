param(
  [Parameter(Mandatory=$true)][string]$NewPassword
)

# Only act if this server is actually a domain controller. Running
# Set-ADAccountPassword on a non-promoted server would fail since the
# ActiveDirectory module/AD DS role is not present yet.
$isDomainController = Get-Service -Name NTDS -ErrorAction SilentlyContinue

if (-not $isDomainController) {
    Write-Host "NTDS service not found. Server is not yet a domain controller. Skipping domain password set."
    exit 0
}

Import-Module ActiveDirectory

$SecurePwd = ConvertTo-SecureString $NewPassword -AsPlainText -Force

try {
    Set-ADAccountPassword -Identity "Administrator" -NewPassword $SecurePwd -Reset -ErrorAction Stop
    Write-Host "Domain Administrator password set successfully."
}
catch {
    Write-Host "Failed to set domain Administrator password:"
    Write-Host $_.Exception.Message
    exit 1
}