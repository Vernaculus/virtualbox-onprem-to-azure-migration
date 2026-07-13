# On-Prem to Azure Migration Lab

Simulated on-premises Active Directory + RHEL environment (built in Oracle VirtualBox) migrated to Microsoft Azure using Azure Migrate, following a lift-and-shift methodology with Terraform-defined landing zone infrastructure.

## Overview

This project demonstrates an end-to-end on-premises to Azure migration on a small, controlled scale, covering:

- Building a two-tier on-prem environment (AD DS/DNS + RHEL app server) in VirtualBox
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

- Oracle VirtualBox
- Windows Server (AD DS, DNS)
- RHEL / Apache
- Azure Migrate
- Terraform
- Ansible
- Azure Monitor / Log Analytics (Phase 2 extension)

## Project Phases

| Phase | Description                          | Status         |
|-------|---------------------------------------|-----------------|
| 1     | Build on-prem lab (AD + RHEL)         | In Progress     |
| 2     | Azure Migrate discovery and assessment| In Progress     |
| 3     | Terraform landing zone deployment     | In Progress     |
| 4     | Test migration and validation         | In Progress     |
| 5     | Cutover and decommission              | In Progress     |

## Repository Structure

/terraform    - IaC for target Azure landing zone
/ansible      - On-prem VM baseline configuration
/docs         - Architecture diagrams, assessment reports, lessons learned
/screenshots  - Migration process evidence
README.md

## Key Decisions and Trade-offs

- Why agent-based migration was used instead of appliance-based (VirtualBox limitation)
- Sizing rationale from Azure Migrate assessment
- Network design decisions (subnetting, NSG rules)

## Lessons Learned

[Short write-up: what went well, what you would do differently at enterprise scale]

## Author

Joshua Hall
LinkedIn: https://www.linkedin.com/in/josh-e-hall/
GitHub: https://github.com/Vernaculus

## License

See LICENSE file (MIT License)
