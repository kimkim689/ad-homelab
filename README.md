# Active Directory Home Lab

**Windows Server 2022 | Active Directory | GPO | DNS | DHCP | PowerShell**

---

## Why I Built This

I wanted hands-on experience with the kind of environment I'd actually work in, not just theory. So instead of following a step-by-step guide, I designed this from scratch by using multiple online resources as reference, made decisions myself, and troubleshot everything independently.

The lab started simple and grew into a small enterprise setup with a domain controller, file server, two workstations, department-based access control, GPO deployment, and PowerShell automation.

For full documentation and screenshots, visit: https://www.notion.so/katiengproject/2026-Home-Lab-Project-322341c8960f80d98200e4bc26cef724?source=copy_link 
---

## Goals

- Build and manage a functional AD domain from scratch
- Implement and test GPOs across users and workstations
- Simulate real helpdesk tickets and document how I resolved them
- Get comfortable with PowerShell for admin tasks and automation

---

## Environment

| Machine | Role | IP |
|---|---|---|
| KTN-DC | Domain Controller | 10.0.0.10 (static) |
| KTN-FS01 | File Server | 10.0.0.11 (static) |
| WS-001 / WS-002 | Workstations | 10.0.0.100–200 (DHCP) |

**Hypervisor:** VirtualBox
**Domain:** KatieNg.local
**Network:** Internal network (L_intnet) for all VMs. DC has a second NAT adapter and routes internet traffic to clients via RRAS.

---

## Tools and Technologies

- Windows Server 2022 - DNS, DHCP, RRAS/NAT
- Windows 11 Pro - Client machine
- Active Directory Domain Services (AD DS) - Identity and access management 
- Group Policy Management - Centralised policy configuration and enforcement 
- PowerShell - Automation 
- BGInfo, Chrome MSI deployment - additional software

---

## AD Architecture

```
KatieNg.local
└── Katie
    ├── Admin              # Tier 0/1 — Domain Admin and IT Support accounts only
    ├── Users              # Standard users across HR, Finance, IT
    ├── Workstations       # Domain-joined client machines
    ├── Servers            # File Server
    ├── Disabled_Users     # Offboarded accounts kept for 30-day retention
    └── Security Groups
        ├── G_IT_Admins        # Global — privileged admin access
        ├── G_Helpdesk         # Global — IT support accounts
        ├── G_Standard_Users   # Global — baseline policy, all staff
        ├── G_HR_Users
        ├── G_Finance_Users
        ├── G_IT_Users
        ├── DL_HR_Share        # Domain Local — controls HR folder access
        ├── DL_Finance_Share
        └── DL_IT_Share
```

Access follows the AGDLP model: users go into Global groups, Global groups go into Domain Local groups, and permissions are applied to the Domain Local groups. This keeps things clean and scalable.

---

## Drive Mapping

| Drive | Purpose | Access |
|---|---|---|
| S: | Department shared folders | Via DL security groups |
| H: | Personal home drive | Per user |
| Z: | Admin only share (scripts, logs) | Domain Admins and G_IT_Admins |

All drives are mapped via GPO. The Z: drive uses item-level targeting so it only appears for admin accounts.

Access-based enumeration is enabled on the shared drive → users only see the folders they have permission to access, not the full department structure.

---

## Group Policies

| GPO | Scope | What it does |
|---|---|---|
| Default Domain Policy | Domain | Password complexity, account lockout |
| Admin_Strong_Policy (FGPP) | Domain Admins | Stricter lockout - 3 attempts, 24 password history |
| Drive_Mapping_Departments | Workstations OU | Maps S: and H: per user |
| User_Folder_Redirection | Users OU | Redirects Documents and Desktop to File Server |
| BGInfo | Workstations OU | Deploys system info overlay on every login |
| Chrome | Workstations OU | Silent MSI install of Google Chrome |
| Chrome_Browser_Policies | Workstations OU | Sets Chrome as default browser |
| WS_Audit_Policy | Workstations OU | Audits logon events, lockouts, account changes |
| Remote Management | Workstations OU | Enables WinRM so I can manage workstations remotely from DC |

---

## Tickets

Real issues I worked through during the build and simulated helpdesk scenarios. Each one is documented with what happened, how I diagnosed it, and what I learned.

| Ticket | Category | Summary |
|---|---|---|
| [TICKET-001](tickets/TICKET-001-icmp-connectivity.md) | Network | Client couldn't ping DC - firewall blocking ICMP |
| [TICKET-002](tickets/TICKET-002-dns-mismatch-domain-join.md) | DNS | File server couldn't join domain after DC rename left stale DNS records |
| [TICKET-003](tickets/TICKET-003-ntfs-permission-local-account.md) | Permissions | Couldn't add domain group to NTFS - was logged in as local account |
| [TICKET-004](tickets/TICKET-004-bginfo-gpo-conflict.md) | GPO | BGInfo wallpaper not applying due to conflicting domain-wide GPO |
| [TICKET-005](tickets/TICKET-005-account-lockout.md) | Security | Account lockout - investigated via Event Viewer before unlocking |
| [TICKET-006](tickets/TICKET-006-new-user-onboarding.md) | Onboarding | New user setup end-to-end manual process |
| [TICKET-007](tickets/TICKET-007-workstation-deployment.md) | Endpoint | Second workstation deployed and joined to domain |
| [TICKET-008](tickets/TICKET-008-user-offboarding.md) | Offboarding | Account disabled, groups removed, data retained for 30 days |
| [TICKET-009](tickets/TICKET-009-bulk-onboarding-automation.md) | Automation | Replaced manual onboarding with PowerShell scripts and logging |

---

## Scripts

| Script | What it does |
|---|---|
| [provision-home-drives.ps1](scripts/provision-home-drives.ps1) | Creates home folders on file server and maps H: for all users |
| [bulk-onboard-users.ps1](scripts/bulk-onboard-users.ps1) | Reads a CSV from HR and creates AD accounts with groups, home drives and logging |
| [verify-onboarding.ps1](scripts/verify-onboarding.ps1) | Checks every onboarding requirement and logs pass/fail per user |

---
