# TICKET-003 - Cannot Add Domain Group to NTFS Permissions on File Server

| Field | Detail |
|---|---|
| **ID** | TICKET-003 |
| **Category** | Permissions / Authentication |
| **Priority** | Medium |
| **Status** | ✅ Resolved |
| **Environment** | KTN-FS01 File Server - NTFS permissions on Departments shared folder |

---

## Description

While configuring NTFS permissions on the HR shared folder (`C:\Shares\Departments\HR`), attempting to add the domain security group `DL_HR_Share` via the object picker returned an error. Clicking "Check Names" failed to resolve the group.

---

## Diagnosis Steps

**Step 1 - Verify domain join status of File Server**
```powershell
systeminfo | findstr "Domain"
```
Result: `katieng.local` - domain link confirmed ✅

**Step 2 - Identify current login context**
```powershell
whoami
```
Result: `ktn-fs01\admin`

This confirmed the session was running under a **local administrator account**, not a domain account. The object picker was scoped to the local machine only and could not query Active Directory.

---

## Root Cause

Logged into the File Server using the local `admin` account rather than the domain account `katieng\katie.admin`. When the security principal context is local, the object picker cannot browse or resolve domain objects such as AD security groups.

---

## Resolution

1. Logged out of the local `ktn-fs01\admin` session
2. Logged back in as `katieng\katie.admin` (domain account)
3. Re-opened NTFS permissions for the HR folder
4. Clicked Add → changed location to `KatieNg.local` → searched for `DL_HR_Share`
5. Group resolved successfully - applied Modify permission ✅
6. Repeated for `DL_Finance_Share` and `DL_IT_Share` ✅

---

## Lesson Learned

Always verify login context with `whoami` when AD-related operations fail unexpectedly. When managing domain resources on member servers, always use a domain account with appropriate privileges.
