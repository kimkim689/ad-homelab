# TICKET-002 - File Server Cannot Join Domain (DNS Mismatch After DC Rename)

| Field | Detail |
|---|---|
| **ID** | TICKET-002 |
| **Category** | DNS / Domain Join |
| **Priority** | High |
| **Status** | ✅ Resolved |
| **Environment** | KTN-FS01 (Windows Server 2022) → KTN-DC Domain Controller |

---

## Description

After setting up the File Server (KTN-FS01) and attempting to join it to the KatieNg.local domain, the join process failed. The error indicated the machine could locate the domain name but could not complete the join due to a record mismatch.

---

## Diagnosis Steps

**Step 1 — Verify DNS resolution from File Server**
```
nslookup KatieNg.local
```
Result: DC was reachable, but DNS resolution was inconsistent — confirmed DNS service on DC was not resolving cleanly.

**Step 2 — Check DNS service status on DC**
```powershell
Get-Service DNS
```
Result: Status = Running. DNS service itself was not the problem.

**Step 3 — Inspect DNS records in DNS Manager**

Opened DNS Manager on the DC:  
`Server Manager → Tools → DNS → KTN-DC → Forward Lookup Zones → KatieNg.local`

Found **two A records** for the DC — one for the old hostname and one for the new hostname, both pointing to the same IP (10.0.0.10).

---

## Root Cause

The DC hostname was renamed **after** Active Directory Domain Services was already installed. AD and DNS had already registered the old hostname. The rename created a duplicate stale DNS record, causing the domain join process to fail due to the mismatch.

---

## Resolution

1. Deleted the stale A record (old hostname) via DNS Manager — right-click → Delete
2. Restarted the DNS service:
```powershell
Restart-Service DNS
```
3. Re-attempted domain join from KTN-FS01 — successful ✅
4. Verified in ADUC: KTN-FS01 appeared in the Workstations OU, then manually moved to Servers OU ✅

---

## Lesson Learned

Always rename a server **before** promoting it to a Domain Controller or installing AD DS. Post-promotion renames create DNS inconsistencies that require manual cleanup. When troubleshooting domain join failures, always check for stale DNS records as a first step alongside service status.
