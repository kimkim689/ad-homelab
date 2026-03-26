# TICKET-005 — Account Lockout Investigation (Potential Brute Force)

| Field | Detail |
|---|---|
| **ID** | TICKET-005 |
| **Category** | Account Management / Security |
| **Priority** | High |
| **Status** | ✅ Resolved |
| **Affected User** | Hanni Pham (hpham) |
| **Environment** | KatieNg.local — DC Event Viewer, ADUC |

---

## Description

User Hanni Pham was unable to log in. Account appeared to be locked out. Investigation required to determine whether this was a forgotten password scenario or a potential brute-force attempt before unlocking.

---

## Checklist

- [x] Confirm lockout via Event Viewer — check if part of a brute-force attempt
- [x] Unlock account and reset password

---

## Investigation

**Step 1 — Check Event Viewer on DC**

```
Event Viewer → Windows Logs → Security
```

Filtered for the following Event IDs:

| Event ID | Meaning |
|---|---|
| 4740 | Account Lockout |
| 4625 | Failed Logon Attempt |

**Finding:** Event ID 4740 logged at 11:00 AM — source workstation identified as WS-001.

Multiple 4625 events preceded the lockout, consistent with repeated failed password attempts from the same machine. No indication of external access or unusual source IPs — assessed as accidental lockout (likely user error), not a brute-force attack.

---

## Resolution

Unlocked account via ADUC:

1. `Active Directory Users and Computers → Users OU → hpham`
2. Right-click → **Reset Password**
3. Entered temporary password
4. Ticked **User must change password at next logon** ✅
5. Ticked **Unlock account** ✅
6. Clicked OK

**Result:** User confirmed successful login. ✅

---

## Lesson Learned

Always check Event Viewer **before** unlocking an account. A lockout caused by repeated 4625 failures from an unexpected workstation or outside business hours should be escalated rather than immediately resolved. In this case the source (WS-001, during business hours) was consistent with a legitimate user error.
