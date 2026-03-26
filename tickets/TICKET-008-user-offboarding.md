# TICKET-008 — User Offboarding (John Smith)

| Field | Detail |
|---|---|
| **ID** | TICKET-008 |
| **Category** | User Offboarding |
| **Priority** | High |
| **Status** | ✅ Resolved |
| **Affected User** | John Smith |
| **Environment** | KatieNg.local — ADUC, File Server |

---

## Description

John Smith is leaving the organisation. Account must be securely disabled, access removed, and data retained per the 30-day retention policy before final deletion.

---

## Checklist

- [x] Create Disabled_Users OU
- [x] Reset password (kill active sessions)
- [x] Disable account and add offboarding note
- [x] Remove from all security groups
- [x] Set account expiry date (30 days)
- [x] Move account to Disabled_Users OU
- [x] Verify account is inaccessible
- [x] Confirm home drive data retained on File Server

---

## Process

**Step 1 — Create Disabled_Users OU**

First offboarding in this environment — created a dedicated OU for disabled accounts:

```
ADUC → right-click top-level OU (Katie) → New → Organisational Unit → "Disabled_Users"
```

**Step 2 — Reset password**

Resetting the password immediately terminates any active sessions and prevents re-authentication:

```
Users OU → right-click John Smith → Reset Password → enter new secure password
→ Untick "User must change password at next logon"
→ Click OK
```

**Step 3 — Disable account and document**

```
Users OU → right-click John Smith → Disable Account
```

Opened Properties → Description tab → added:
```
Offboarding [date]
```

**Step 4 — Remove security groups**

```
John Smith → Properties → Member Of
```

Removed all global security groups (G_Standard_Users, G_HR_Users, etc.).  
Left `Domain Users` — this is a default group and cannot be removed.

**Step 5 — Set account expiry and move to Disabled_Users OU**

```
Properties → Account tab → Account expires → End of → [date + 30 days]
```

Right-click John Smith → Move → select `Disabled_Users` OU → OK

---

## Verification

Attempted login as John Smith on WS-001:

- ✅ Login rejected — account disabled message displayed
- ✅ Home drive data intact on KTN-FS01 (confirmed via File Server browse)

---

## Post-Retention Actions (Due in 30 days)

- [ ] Notify department manager to retrieve any required files before deletion
- [ ] Remove user account from AD
- [ ] Backup or hand over home drive data if required
- [ ] Delete home folder from File Server

---

## Notes

Department manager has been notified to retrieve any files needed before the 30-day retention window closes.
