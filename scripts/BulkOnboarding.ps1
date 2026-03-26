#import AD module 
Import-Module ActiveDirectory

#$WhatIfPreference = $true

#Check log directory 
$logDir = '\\KTN-FS01\Admin Only$\LogFiles\Onboarding'
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir
}

#State log path 
$logPath = "\\KTN-FS01\Admin Only$\LogFiles\Onboarding\onboarding_$(Get-Date -Format 'yyyy-MM-dd').log"
#Log header
Add-Content -Path $logPath -Value "`n--- Onboarding run started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---"

#Import csv of onboarding users
$users = Import-Csv '\\KTN-FS01\Admin Only$\Data\NewUser.csv'

#Fixed variables 
$usersOU = "OU=Users,OU=Katie,DC=KatieNg,DC=local"
$standardGroup = "G_Standard_Users"
$password = ConvertTo-SecureString "Welcome2026!" -asPlainText -Force

#Hash map of Dept and G_group 
$G_GroupMapping = @{
    "HR" = "G_HR_Users"
    "IT" = "G_IT_Users"
    "Finance" = "G_Finance_Users"
}

#Loop through each user in the file 
foreach ($user in $users) {
    
    #create username based on the naming convention 
    $baseUsername = ($user.FirstName[0] + $user.LastName).ToLower()
    $username = $baseUsername
    $baseFullname = "$($user.FirstName) $($user.LastName)"
    $fullname = $baseFullname
    $counter = 2

    #Check if fullname or username is already existed 
    while (
    (Get-ADUser -Filter {SamAccountName -eq $username} -ErrorAction SilentlyContinue) -or
    (Get-ADUser -Filter {Name -eq $fullname} -ErrorAction SilentlyContinue)
    ) {
        #Add number to username 
        $username = $baseUsername + $counter
        $counter++
        #Add username behind name if either name or username is existed 
        $fullname = "$baseFullname ($username)"
    }
    
    #User principal name 
    $upn = "$username@KatieNg.local"

    #Check if department exists/matches 
    if ($G_GroupMapping.ContainsKey($user.Department)) {
        $deptGroup = $G_GroupMapping[$user.Department]
    } else {
        Write-Host "WARNING: Unknown department '$($user.Department)' for $($user.FirstName) $($user.LastName) - skipping"
        Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | WARNING | $username | $fullname | Unknown department: $($user.Department)"
        continue
    }

    #Create new user in AD
    try{
        New-ADUser `
            -Name $fullname `
            -SamAccountName $username `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -UserPrincipalName $upn `
            -AccountPassword $password `
            -ChangePasswordAtLogon $true `
            -Enabled $true `
            -Path $usersOU `
            -HomeDrive "H:" `
            -HomeDirectory "\\KTN-FS01\Home$\$username"
        
        #Print success message to log
        Add-Content -Path $logPath -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | SUCCESS |$username|$fullname|$($user.Department)" 

        #Add member to security group 
        Add-ADGroupMember -Identity $deptGroup     -Members $username
        Add-ADGroupMember -Identity $standardGroup -Members $username

        #Create home drive if not exists
        $homepath="\\KTN-FS01\Home$\$username"
        if (-not (Test-Path $homepath)){
            New-Item -ItemType Directory -Path $homepath
        }   
        
        #Apply NTFS permission 
        $acl=Get-Acl $homepath 

        $rule=New-Object System.Security.AccessControl.FileSystemAccessRule(
            $username, 
            "Modify",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
         )
         $acl.AddAccessRule($rule)
         Set-Acl $homepath $acl 
     }catch{
          #Log error 
          Write-Host "ERROR: Failed to onboard $($user.FirstName) $($user.LastName) - $_"
          Write-Host "DETAIL: $($_.Exception.Message)"
          Write-Host "LOCATION: $($_.InvocationInfo.ScriptLineNumber)"
          Add-Content -Path $logPath -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | ERROR |$username|$fullname| - $_" 
          continue
     }

}
