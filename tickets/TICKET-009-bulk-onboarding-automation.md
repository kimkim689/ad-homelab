# TICKET-009 — Bulk User Onboarding Automation (PowerShell)

| Field | Detail |
|---|---|
| **ID** | TICKET-009 |
| **Category** | Automation / Scripting |
| **Priority** | Medium |
| **Status** | ✅ Resolved |
| **Environment** | KatieNg.local — DC PowerShell, KTN-FS01 File Server |

---

## Description

Manual user onboarding (TICKET-006) does not scale. Built a PowerShell automation system to onboard multiple users from a CSV file, including account creation, group assignment, home drive provisioning, and full audit logging. A separate verification script was also written to validate each onboarding step.

---

## Checklist

- [x] Send CSV template to HR to complete
- [x] Create Admin Only shared drive for scripts and logs
- [x] Write and test onboarding script
- [x] Write and test verification script
- [x] Confirm log files generated correctly

---

## Process

### 1. CSV Input Format

HR completes a spreadsheet with the following columns, saved as `.csv`:

| Column | Example |
|---|---|
| FirstName | Emma |
| LastName | Watson |
| Department | HR |
| StartDate | 2026-03-18 |

### 2. Admin Only Shared Drive

Created a centralised admin file share on KTN-FS01 for scripts and logs — accessible only to Domain Admins and G_IT_Admins:

- Share name: `Admin Only$` (hidden share)
- Share permissions: Domain Admins + G_IT_Admins — Full Control
- NTFS permissions: Domain Admins + G_IT_Admins — Full Control (Users group removed)
- Drive mapped to `Z:` via GPO with Item-Level Targeting scoped to Domain Admins and G_IT_Admins

### 3. Onboarding Script — Key Features

See `scripts/bulk-onboard-users.ps1` for the full script.

**Username generation and duplicate handling:**

Naming convention: first initial + last name (e.g. Emma Watson → `ewatson`)

The script checks both `SamAccountName` and `Name` (CN) for uniqueness before creating an account:
- If `ewatson` exists → try `ewatson2`, `ewatson3`, and so on
- If `Emma Watson` already exists as a CN → display name becomes `Emma Watson (ewatson2)`

> **Lesson learned:** AD enforces uniqueness on both `SamAccountName` AND the `Name` (CN) field. Both must be checked before attempting account creation. This was discovered when a test run left a CN behind that caused the next run to fail.

**AD Module requirement:**

> **Lesson learned:** The `New-ADUser` cmdlet requires the Active Directory PowerShell module. If the module is not imported, the cmdlet is not recognised. Added `Import-Module ActiveDirectory` to the top of the script.

**Security group assignment:**

A hashtable maps CSV department names to AD security groups:

```powershell
$G_GroupMapping = @{
    "HR"      = "G_HR_Users"
    "IT"      = "G_IT_Users"
    "Finance" = "G_Finance_Users"
}
```

If the department value in the CSV doesn't match any key (e.g. typo), the script logs a WARNING and skips that user rather than creating an account with no group.

**Error handling:**

Each user creation block is wrapped in `try/catch`. A failure on one user is logged and the script continues — a single bad CSV record cannot block the rest of the batch.

**Logging:**

All actions written to a daily log file:
```
\\KTN-FS01\Admin Only$\LogFiles\Onboarding\onboarding_yyyy-MM-dd.log
```

Example log output:
```
--- Onboarding run started: 2026-03-18 09:30:00 ---
2026-03-18 09:30:01 | SUCCESS | ewatson | Emma Watson | HR
```

### 4. Verification Script — Key Checks

See `scripts/verify-onboarding.ps1` for the full script.

| Check | Method |
|---|---|
| User exists in AD | `Get-ADUser` by GivenName and Surname |
| Account is enabled | `$adUser.Enabled -eq $true` |
| Member of department group | `Get-ADGroupMember` + `Where-Object` |
| Member of Standard group | `Get-ADGroupMember` + `Where-Object` |
| Home Drive set to H: | `$adUser.HomeDrive` |
| Home Directory path correct | `$adUser.HomeDirectory` |
| Home folder physically exists | `Test-Path` |
| NTFS permissions correct | `Get-Acl` + `$acl.Access` |

If `Get-ADUser` returns more than one result for the same name, the script logs a WARNING and flags for manual review.

**Reusable logging function (refactor):**

> **Lesson learned:** Initially duplicated `Write-Host` and `Add-Content` calls for every log message. Refactored into a single reusable function:

```powershell
function Write-Log {
    param($message)
    Write-Host $message
    Add-Content -Path $logPath -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | $message"
}
```

---

## Verification Results

**Execution policy note:** PowerShell blocked script execution by default. Bypassed for the current session only:

```powershell
Set-ExecutionPolicy Bypass -Scope Process
```

- ✅ Onboarding script ran successfully — all users created
- ✅ Verification script ran — all checks passed
- ✅ Log files generated at correct path on File Server
- ✅ Random spot-check user confirmed in correct AD groups
- ✅ Password change prompted on first workstation login
- ✅ GPO applied (BGInfo, Chrome, drives) on login
- ✅ H: drive and S: share mapped correctly
