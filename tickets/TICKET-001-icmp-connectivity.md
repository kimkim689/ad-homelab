# TICKET-001 - Client Cannot Ping Domain Controller

| Field | Detail |
|---|---|
| **ID** | TICKET-001 |
| **Category** | Network Connectivity |
| **Priority** | High |
| **Status** | ✅ Resolved |
| **Environment** | VirtualBox - Windows 11 Client → Windows Server 2022 DC |

---

## Description

After configuring the Windows 11 client with a static IP on the internal network (L_intnet), the machine was unable to ping the Domain Controller at 10.0.0.10. This blocked the domain join process entirely.

---

## Diagnosis Steps

**Step 1 - Verify network adapter configuration**
✅Confirmed both machines were connected to the same internal network adapter (L_intnet) in VirtualBox. 

**Step 2 - Verify IP configuration on both machines**

| Machine | IP | Subnet | DNS |
|---|---|---|---|
| DC (KTN-DC) | 10.0.0.10 | 255.255.255.0 | 127.0.0.1 |
| Client (WS-001) | 10.0.0.20 | 255.255.255.0 | 10.0.0.10 |

✅Both configurations confirmed correct. 

**Step 3 - Test connectivity**
```
ping 10.0.0.10
```
Result: Request timed out - confirmed firewall blocking ICMP.

---

## Root Cause

Windows Firewall blocks ICMP (ping) requests by default on both machines. No inbound ICMPv4 rule was enabled.

---

## Resolution

Ran the following PowerShell command **on both the DC and the client** (as Administrator):

```powershell
New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4
```

✅Re-ran ping test - confirmed successful in both directions.   
Domain join proceeded without further issues.

---

## Lesson Learned

When building a new VM environment, enable ICMP early as a baseline connectivity check before configuring more complex services like DNS or AD. Saves significant time later.
