# TICKET-006 — New User Onboarding (Kevin Nguyen)

| Field | Detail |
|---|---|
| **ID** | TICKET-006 |
| **Category** | User Onboarding |
| **Priority** | Medium |
| **Status** | ✅ Resolved |
| **New User** | Kevin Nguyen — HR Department |
| **Environment** | KatieNg.local — ADUC, PowerShell, WS-001 |

---

## Description

New employee Kevin Nguyen joining the HR department. Account needs to be created, configured, and verified before his start date.

---

## Checklist

- [x] Check for existing username conflicts
- [x] Create account in Users OU
- [x] Set temporary password
- [x] Assign security groups (HR + Standard)
- [x] Configure home drive (H:)
- [x] Verify end-to-end on workstation

---

## Process

**Step 1 — Check for username conflicts**

Naming convention: first letter of first name + full last name (e.g. Kevin Nguyen → knguyen)

```powershell
Get-ADUser -Filter {SamAccountName -like "knguyen*"}
```

Result: No matches returned — username `knguyen` is available. ✅

**Step 2 — Create account in Users OU**

Created via ADUC:
- OU: `OU=Users,OU=Katie,DC=KatieNg,DC=local`
- SamAccountName: `knguyen`
- UPN: `knguyen@KatieNg.local`
- Temporary password set
- **User must change password at next logon:** ✅

**Step 3 — Assign security groups**

Added to:
- `G_HR_Users` — department group
- `G_Standard_Users` — company-wide baseline group

**Step 4 — Configure home drive (H:)**

Used the existing PowerShell home drive provisioning script (`scripts/provision-home-drives.ps1`) to create the folder on KTN-FS01 and map it to H: in the user's AD profile.

---

## Verification

Logged into `knguyen` on WS-001:

- ✅ Password change prompted on first login
- ✅ H: (home drive) and S: (shared drive) mapped correctly
- ✅ Access to HR department folder confirmed
- ✅ Access restricted to HR only (ABE working — Finance and IT folders not visible)
- ✅ BGInfo wallpaper overlay applied
- ✅ Google Chrome installed and set as default

---

## Notes

- Reset Kevin's account password again after testing to ensure password change is prompted on actual first login
