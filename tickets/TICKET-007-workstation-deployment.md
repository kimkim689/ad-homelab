# TICKET-007 — New Workstation Deployment (WS-002)

| Field | Detail |
|---|---|
| **ID** | TICKET-007 |
| **Category** | Endpoint Deployment |
| **Priority** | Medium |
| **Status** | ✅ Resolved |
| **Machine** | WS-002 (Windows 11 Pro) |
| **Environment** | KatieNg.local — VirtualBox, AD DS, GPO |

---

## Description

Deploy and configure a second Windows 11 workstation (WS-002), join it to the domain, and verify all GPOs apply correctly.

---

## Checklist

- [x] OS installation and VM setup
- [x] Rename machine to WS-002 (naming convention)
- [x] Network configuration and firewall
- [x] Domain join
- [x] Verify GPOs apply correctly

---

## Process

**Step 1 — OS Installation**

Created new VM in VirtualBox using the same Windows 11 Pro ISO.

Before first boot: changed Adapter 1 to `L_intnet` (internal network only — no NAT).

During Windows setup, bypassed Microsoft account requirement to create a local account:
```
Shift + F10 → Command Prompt
start ms-cxh:localonly
```

Named device: `WS-002`

**Step 2 — Network Configuration**

Navigated to `Settings → Network & Internet → Ethernet`.

Machine automatically received IP and DNS via DHCP (10.0.0.100–200 range from DC). ✅

Enabled ICMP inbound rule and confirmed ping to DC:
```powershell
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
ping 10.0.0.10
```
Result: Successful ✅

**Step 3 — Domain Join**

```
Settings → Accounts → Work or School → Connect → Join this device to a local Active Directory domain
```

Entered domain: `KatieNg.local`  
Authenticated with domain admin credentials → restarted.

---

## Verification

After restart and domain login:

- ✅ WS-002 appears in ADUC under Workstations OU
- ✅ Google Chrome installed and set as default (Software Installation GPO)
- ✅ BGInfo wallpaper overlay applied on login
- ✅ Drive mapping working — S: (shared) and H: (home) visible after user login
- ✅ Folder redirection confirmed — Documents and Desktop redirect to File Server
- ✅ Internet connectivity confirmed (routing via DC NAT/RRAS)

---

## Notes

- **Future consideration:** Windows Deployment Services (WDS) should be evaluated to automate OS deployment for additional workstations, replacing the manual ISO installation process.
