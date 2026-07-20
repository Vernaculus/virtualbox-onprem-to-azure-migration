# On-Prem to Azure Migration Lab

Simulated on-premises Active Directory + RHEL environment (built in Oracle VirtualBox) migrated to Microsoft Azure using Azure Migrate, following a lift-and-shift methodology with Terraform-defined landing zone infrastructure.

## Overview

This project demonstrates an end-to-end on-premises to Azure migration on a small, controlled scale, covering:

- Building a two-tier on-prem environment (AD DS/DNS + RHEL app server) in VirtualBox
- Baseline configuration management of the RHEL app server with Ansible
- Discovery and assessment via the Azure Migrate appliance
- Terraform-defined target landing zone (VNet, subnets, NSGs, resource groups)
- Test migration and validation in an isolated Azure VNet
- Full cutover, DNS reconfiguration, and on-prem decommission
- Architecture diagrams and lessons learned documentation

## Architecture

Before (On-Prem, VirtualBox):
[Insert before-diagram]

After (Azure):
[Insert after-diagram]

## Tools and Technologies

- Oracle VirtualBox + Vagrant
- Windows Server (AD DS, DNS)
- RHEL / Apache
- Ansible
- Azure Migrate
- Terraform
- Azure Monitor / Log Analytics (Phase 2 extension)

## Project Phases

| Phase | Description                                       | Status        |
|-------|---------------------------------------------------|---------------|
| 1     | Build on-prem lab (AD + RHEL) and baseline config | In Progress   |
| 2     | Azure Migrate discovery and assessment            | Not Started   |
| 3     | Terraform landing zone deployment                 | Not Started   |
| 4     | Test migration and validation                     | Not Started   |
| 5     | Cutover and decommission                          | Not Started   |

## Repository Structure

    .
    ├── vagrant/       # Vagrantfile, config.example.yml, and provisioning scripts for on-prem VM lab
    ├── terraform/     # IaC for target Azure landing zone
    ├── ansible/       # On-prem VM baseline configuration
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

## Getting Started

### 1. Provision the on-prem lab (Vagrant + VirtualBox)

    cd vagrant
    cp config.example.yml config.yml   # edit values as needed; config.yml is gitignored
    vagrant up ad-dc                   # bring up the Windows DC first
    vagrant up rhel-app                # bring up the RHEL app server

Use `vagrant ssh rhel-app` to reach the Linux box, or `vagrant rdp ad-dc` (with the rdp plugin) for the Windows box.

### 2. Apply the Ansible baseline to the RHEL app server

    cd ansible
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook playbooks/baseline.yml

This installs and enables `firewalld`/`httpd`, opens HTTP through the firewall, and deploys a templated landing page. Inventory and defaults live in `inventory/lab.yml` and `inventory/group_vars/`; no flags are required beyond the default `ansible.cfg` in this directory.

Verify with:

    curl http://192.168.56.11

## Configuration

| Variable file                                    | Purpose                                                   |
|--------------------------------------------------|-----------------------------------------------------------|
| `vagrant/config.yml` (from `config.example.yml`) | VM box versions, IPs, memory/CPU, AD domain/NetBIOS names |
| `ansible/inventory/group_vars/all.yml`           | Shared lab domain name, NTP/time sync settings            |
| `ansible/inventory/group_vars/linux.yml`         | RHEL package/repo/service and web page content settings   |
| `terraform/terraform.tfvars` (from `.example`)   | Azure subscription, region, network sizing (Phase 3)      |

Assumes an Azure subscription with Contributor role for the Terraform phases (Phase 3+).

## Key Decisions and Trade-offs

- Agent-based Azure Migrate was used instead of appliance-based discovery, since VirtualBox isn't natively supported by VMware/Hyper-V appliance tooling
- CentOS Stream 9 mirror repos substitute for a registered RHEL subscription on the app server, avoiding real Red Hat credentials in a public repo
- Vagrant VM configuration (IPs, memory, box versions) is fully externalized to `config.yml`/`config.example.yml`, mirroring the `variables.tf`/`terraform.tfvars` split used later in Terraform
- Ansible secrets (e.g., the AD admin credential needed for the upcoming RHEL domain-join step) will use `ansible-vault`-encrypted variable files rather than plaintext, once introduced

## Lessons Learned

[Short write-up: what went well, what you would do differently at enterprise scale]

## Author

Joshua Hall
LinkedIn: https://www.linkedin.com/in/josh-e-hall/
GitHub: https://github.com/Vernaculus

## License

See LICENSE file (MIT License)