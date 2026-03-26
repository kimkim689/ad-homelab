# TICKET-004 - BGInfo Wallpaper Not Applying (GPO Conflict)

| Field | Detail |
|---|---|
| **ID** | TICKET-004 |
| **Category** | Group Policy / Software Deployment |
| **Priority** | Low |
| **Status** | ✅ Resolved |
| **Environment** | Domain-wide GPO conflict - BGInfo vs Wallpaper Policy |

---

## Description

After deploying BGInfo via a GPO scheduled task linked to the Workstations OU, the BGInfo system information overlay did not appear on the desktop wallpaper. Running BGInfo manually as Administrator also failed to apply the wallpaper change.

---

## Diagnosis Steps

**Step 1 - Manual execution test**

Ran `Bginfo.exe` directly with the saved config file as Administrator. No error messages returned, but wallpaper did not change.

**Step 2 - Identify GPO conflicts**

Reviewed active GPOs in Group Policy Management. Identified an existing domain-wide GPO (`Lab_Workstation_Policy`) configured under:

`User Configuration → Policies → Administrative Templates → Desktop → Desktop Wallpaper`

This GPO was enforcing a specific wallpaper path across all users domain-wide.

**Step 3 - Test by disabling conflicting GPO**

Temporarily disabled `Lab_Workstation_Policy` in Group Policy Management, then ran:
```
gpupdate /force
```
Re-ran BGInfo - wallpaper applied successfully ✅. Confirmed the domain-wide wallpaper policy was the cause.

---

## Root Cause

A domain-wide wallpaper GPO (`Lab_Workstation_Policy`) was enforcing a wallpaper setting with higher precedence than the BGInfo scheduled task. Because GPO wallpaper settings are enforced as policies (not preferences), they override any application-level wallpaper changes including BGInfo.

---

## Resolution

1. Disabled the domain-wide wallpaper GPO (`Lab_Workstation_Policy`)
2. Reconfigured the BGInfo GPO deployment:
   - GPO linked to Workstations OU
   - Scheduled task under `Computer Configuration → Preferences → Control Panel Settings → Scheduled Tasks`
   - Trigger: At user logon
   - Action: Run `\\KTN-FS01\Shares$\Software\BGInfo\Bginfo.exe` with arguments `/silent /timer:0 /nolicprompt`
3. Enabled **GPO loopback processing (Merge mode)** to ensure the computer-linked GPO applies user-context settings:
   - `Computer Configuration → Policies → Administrative Templates → System → Group Policy → Configure user Group Policy loopback processing mode` → Enabled (Merge)
4. Tested on client login - BGInfo overlay confirmed working ✅

---

## Lesson Learned

When deploying tools that modify desktop settings (wallpaper, screensaver), always audit existing GPOs for conflicts first. GPO policies take precedence over preferences and application-level changes. Loopback processing is required when user configuration settings need to be applied based on the computer the user logs into, not their user OU.
