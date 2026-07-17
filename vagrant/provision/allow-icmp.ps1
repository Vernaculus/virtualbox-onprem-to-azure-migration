# =============================================================================
# allow-icmp.ps1
# =============================================================================
# Purpose: Persist the ICMP allow rule (previously applied manually via
#   `vagrant winrm` during KAN-3) as a proper Vagrant provisioner, scoped to
#   a single remote IP rather than hardcoded or opened broadly.
#
# WHY SCOPED, NOT A BLANKET ALLOW-ALL:
#   Windows Firewall blocks ICMP by default. Rather than disabling that
#   protection entirely, this rule permits ping only from rhel-app's IP -
#   enough for cross-VM connectivity validation without weakening the
#   DC's overall firewall posture.
# =============================================================================
param($RemoteIP)

New-NetFirewallRule -DisplayName "Allow ICMP from rhel-app" `
  -Direction Inbound -Protocol ICMPv4 -IcmpType 8 `
  -RemoteAddress $RemoteIP -Action Allow