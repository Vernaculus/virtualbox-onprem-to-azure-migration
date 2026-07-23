# On-Prem to Azure Migration Lab

Simulated on-premises Active Directory + RHEL environment (built in Oracle VirtualBox) migrated to Microsoft Azure using Azure Migrate, following a lift-and-shift methodology with Terraform-defined landing zone infrastructure.

## Overview

This project demonstrates an end-to-end on-premises to Azure migration on a small, controlled scale, covering:

- Building a two-tier on-prem environment (AD DS/DNS + RHEL app server) in VirtualBox
- Baseline configuration management and domain join of the RHEL app server with Ansible
- Discovery and assessment via the Azure Migrate appliance
- Terraform-defined target landing zone (VNet, subnets, NSGs, resource groups)
- Test migration and validation in an isolated Azure VNet
- Full cutover, DNS reconfiguration, and on-prem decommission
- Architecture diagrams and lessons learned documentation

## Architecture

Before (On-Prem, VirtualBox):
[Insert before-diagram]

After (Azure):
![On-prem infrastructure pre-migration](docs/onprem-architecture.svg)

On-prem lab topology:

- **dc01** (Windows Server 2022) — AD DS + DNS, domain `lab.local` (NetBIOS `LAB`), static IP `192.168.56.10` on a VirtualBox host-only network
- **app01** (RHEL/CentOS Stream 9) — domain-joined app server via realmd/sssd/adcli, static IP `192.168.56.11`
- Both VMs dual-homed: NAT (internet access for packages) + host-only network (AD/DNS/Kerberos traffic)

## Tools and Technologies

- Oracle VirtualBox + Vagrant
- Windows Server (AD DS, DNS)
- RHEL / Apache
- Ansible
- Azure Migrate
- Terraform
- Azure Monitor / Log Analytics (Phase 2 extension)

## Project Phases

| Phase | Description                                                 | Status        |
|-------|-------------------------------------------------------------|---------------|
| 1     | Build on-prem lab (AD + RHEL), baseline config, domain join | Done          |
| 2     | Azure Migrate discovery and assessment                      | Not Started   |
| 3     | Terraform landing zone deployment                           | Not Started   |
| 4     | Test migration and validation                               | Not Started   |
| 5     | Cutover and decommission                                    | Not Started   |

## Repository Structure

    .
    ├── vagrant/       # Vagrantfile, config.example.yml, and provisioning scripts for on-prem VM lab
    ├── terraform/     # IaC for target Azure landing zone
    ├── ansible/       # On-prem VM baseline configuration and domain-join playbooks
    ├── docs/          # Architecture diagrams, assessment reports, lessons learned
    ├── screenshots/   # Migration process evidence
    └── README.md

## Prerequisites

- [Vagrant](https://www.vagrantup.com/) installed
- [Oracle VirtualBox](https://www.virtualbox.org/) installed
- [Ansible](https://docs.ansible.com/) installed (control machine only; Linux/macOS or WSL recommended)
- Ansible collections listed in `ansible/requirements.yml`: `ansible-galaxy collection install -r ansible/requirements.yml`
- SSH client available on the control machine (used by both Vagrant and Ansible against `rhel-app`)
- No Red Hat subscription required — the RHEL app server uses CentOS Stream 9 mirror repos in place of `subscription-manager register` (documented lab-scope trade-off)
- An `ansible-vault` password file (not committed) for decrypting domain-join secrets

## Getting Started

### 1. Provision the on-prem lab (Vagrant + VirtualBox)

    cd vagrant
    cp config.example.yml config.yml   # edit values as needed; config.yml is gitignored
    vagrant up ad-dc                   # installs AD DS feature, starts forest promotion (triggers a reboot)
    sleep 120                          # allow promotion + reboot to complete
    vagrant reload ad-dc               # re-establish a clean WinRM session post-reboot
    vagrant provision ad-dc --provision-with wait-for-adws,set-domain-admin-password,allow-icmp
    vagrant up rhel-app                # bring up the RHEL app server

**Why the split sequence?** `Install-ADDSForest` triggers an automatic guest reboot mid-promotion. Running dependent provisioners (`wait-for-adws`, password setup, firewall rules) in the same `vagrant up` pass causes the WinRM elevated session to die mid-reboot, which Vagrant treats as a fatal error and tears down the VM. Splitting into `up` → `reload` → `provision` guarantees those steps only run against a fresh, validated WinRM session established after the reboot completes.

Use `vagrant ssh rhel-app` to reach the Linux box, or `vagrant rdp ad-dc` (with the rdp plugin) for the Windows box.

### 2. Configure the RHEL app server and join it to the domain

    cd ansible
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook playbooks/site.yml --vault-password-file .vault_pass

`site.yml` orchestrates two plays in sequence:

1. **baseline.yml** — installs and enables `firewalld`/`httpd`, opens HTTP through the firewall, and deploys a templated landing page.
2. **domain_join.yml** — provisions a dedicated OU and service account on `dc01`, installs `realmd`/`sssd`/`adcli` on `app01`, points DNS at the domain controller, and joins `app01` to `lab.local`.

Each playbook can also be run independently (`ansible-playbook playbooks/baseline.yml` or `playbooks/domain_join.yml`) for troubleshooting.

Verify with:

    curl http://192.168.56.11
    vagrant winrm ad-dc -c 'Get-ADComputer -Identity app01 | Select-Object Name, DistinguishedName'

## Configuration

| Variable file                                               | Purpose                                                     |
|-------------------------------------------------------------|-------------------------------------------------------------|
| `vagrant/config.yml` (from `config.example.yml`)            | VM box versions, IPs, memory/CPU, AD domain/NetBIOS names   |
| `ansible/inventory/group_vars/all/vars.yml`                 | Shared lab domain name, NTP/time sync settings              |
| `ansible/inventory/group_vars/linux/vars.yml`               | RHEL package/repo/service and web page content settings     |
| `ansible/inventory/group_vars/windows.yml`                  | Domain-join OU/service account settings for dc01            |
| `ansible/inventory/group_vars/*/vault.yml` (ansible-vault)  | Encrypted secrets (domain-join credentials)                 |
| `terraform/terraform.tfvars` (from `.example`)              | Azure subscription, region, network sizing (Phase 3)        |
  
Assumes an Azure subscription with Contributor role for the Terraform phases (Phase 3+).

## Key Decisions and Trade-offs

- Agent-based Azure Migrate was used instead of appliance-based discovery, since VirtualBox isn't natively supported by VMware/Hyper-V appliance tooling
- CentOS Stream 9 mirror repos substitute for a registered RHEL subscription on the app server, avoiding real Red Hat credentials in a public repo
- Vagrant VM configuration (IPs, memory, box versions) is fully externalized to `config.yml`/`config.example.yml`, mirroring the `variables.tf`/`terraform.tfvars` split used later in Terraform
- AD DS promotion runs via a local SYSTEM-context scheduled task rather than a direct remote WinRM call, avoiding a known Vagrant/WinRM negotiation issue with `Install-ADDSForest`
- The DSRM/admin password is passed as a scheduled task argument rather than round-tripped through `Export-Clixml`, since DPAPI-encrypted SecureString objects are bound to the originating user context and cannot be decrypted by a SYSTEM-context task
- AD DS promotion's automatic reboot is handled as an explicit two-phase Vagrant sequence (`up` → `reload` → `provision`) rather than a single continuous provisioner chain, since a WinRM elevated session cannot reliably survive an in-flight guest reboot
- Ansible group_vars are split into `all/` and `linux/` directories to separate plaintext variables from `ansible-vault`-encrypted secrets per host group
- `site.yml` provides a single orchestration entry point via `import_playbook`, while `baseline.yml` and `domain_join.yml` remain independently runnable for troubleshooting
- Ansible secrets (the domain-join service account credential) use `ansible-vault`-encrypted variable files rather than plaintext

## Lessons Learned

[Short write-up: what went well, what you would do differently at enterprise scale]

## Author

Joshua Hall
LinkedIn: [https://www.linkedin.com/in/josh-e-hall/](https://www.linkedin.com/in/josh-e-hall/)
GitHub: [https://github.com/Vernaculus](https://github.com/Vernaculus)

## License

See LICENSE file (MIT License)
