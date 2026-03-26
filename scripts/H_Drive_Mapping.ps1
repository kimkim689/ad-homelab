$users = Get-ADUser -Filter * -SearchBase "OU=Users,OU=Katie,DC=KatieNg,DC=local"

foreach ($user in $users) {
    $path = "\\KTN-FS01\Home$\$($user.SamAccountName)"

    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        
        # Set user permissions on their own folder
        $acl = Get-Acl $path
        $permission = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $user.SamAccountName,
            "Modify",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($permission)
        Set-Acl $path $acl
    }

    Set-ADUser $user -HomeDrive "H:" -HomeDirectory $path
    Write-Host "Configured home drive for $($user.SamAccountName)"
}