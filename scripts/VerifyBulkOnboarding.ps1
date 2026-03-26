#import AD module 
Import-Module ActiveDirectory 

#function to write message to log
function Write-Log{
    param($message)
    Write-Host $message
    Add-Content -Path $logPath -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | $message"
}

#State log path 
$logPath = "\\KTN-FS01\Admin Only`$\LogFiles\Onboarding\verify_onboard_$(Get-Date -Format 'yyyy-MM-dd').log"

#Log header
Add-Content -Path $logPath -Value "`n---Verify Onboarding run started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---"

#Import csv
$users = Import-Csv "\\KTN-FS01\Admin Only`$\Data\NewUser.csv"

#Hashtable of Dept and G_group 
$G_GroupMapping = @{
    "HR" = "G_HR_Users"
    "IT" = "G_IT_Users"
    "Finance" = "G_Finance_Users"
}
$standardGroup = "G_Standard_Users"

#Loop through each user in file 
foreach($user in $users){
    $firstname = $user.FirstName
    $lastname = $user.LastName 
    $fullname = "$firstname $lastname"

    #Store all variables pulled from AD 
    $adUser = Get-ADUser -Filter {GivenName -eq $firstname -and Surname -eq $lastname} -Properties *

    #Check if there is more than 1 record for a name 
    if ($adUser.Count -gt 1){
        Write-Log "Multiple user found for $fullname -manual check"
        continue  
    }

    #Check if user with matched name is found in record 
    if($adUser){
        Write-Log "[PASS] $($adUser.SamAccountName)- user exists in AD"
        
        #Check if user is enabled 
        if($adUser.Enabled -eq $true){
            Write-Log "[PASS] $($adUser.SamAccountName)- user is enabled in AD"
        }else{
            Write-Log "[FAIL] $($adUser.SamAccountName)- user is not enabled in AD"
        }
        
        #Map department to security group 
        $userDept = $G_GroupMapping[$user.Department]
        
        #Check if user is in the designated group 
        $inGGroup = Get-ADGroupMember -Identity $userDept | Where-Object {$_.SamAccountName -eq $adUser.SamAccountName}
        $inStandard = Get-ADGroupMember -Identity $standardGroup | Where-Object {$_.SamAccountName -eq $adUser.SamAccountName}
        if($inGGroup){
            Write-Log "[PASS] $($adUser.SamAccountName)- user is in $userDept"
        }else{
            Write-Log "[FAIL] $($adUser.SamAccountName)- user is not in $userDept"
        }
        if($inStandard){
            Write-Log "[PASS] $($adUser.SamAccountName)- user is in $standardGroup"
        }else{
            Write-Log "[FAIL] $($adUser.SamAccountName)- user is not in $standardGroup"
        }

        #Check if "H:" drive is assigned 
        if($adUser.HomeDrive -eq "H:"){
            Write-Log "[PASS] $($adUser.SamAccountName)- user has $($adUser.HomeDrive)"
        }else{
            Write-Log "[FAIL] $($adUser.SamAccountName) - HomeDrive is '$($adUser.HomeDrive)', expected 'H:'"
        }

        #Check the Home Directory 
        $homepath = "\\KTN-FS01\Home$\$($adUser.SamAccountName)"
        if($adUser.HomeDirectory -eq $homepath){
            Write-Log "[PASS] $($adUser.SamAccountName)- user has $($adUser.HomeDirectory)"
        }else{
            Write-Log "[FAIL] $($adUser.SamAccountName) - HomeDirectory is '$($adUser.HomeDirectory)', expected '$homepath'"
        }

        #Check if th the path exists on FS 
        try{
            if (Test-Path $homepath) {
                Write-Log "[PASS] $($adUser.SamAccountName) - home folder exists"

                # only check NTFS if folder exists
                $acl = Get-Acl $homepath
                $ntfsRule = $acl.Access | Where-Object {
                    $_.IdentityReference -eq "KATIENG\$($adUser.SamAccountName)" -and
                    $_.FileSystemRights  -match "Modify" -and
                    $_.AccessControlType -eq "Allow"
                }
                if ($ntfsRule) {
                    Write-Log "[PASS] $($adUser.SamAccountName) - NTFS permission is set correctly"
                }else{
                    Write-Log "[FAIL] $($adUser.SamAccountName) - NTFS permission missing or incorrect"
                }
            }else{
                Write-Log "[FAIL] $($adUser.SamAccountName) - home folder missing"
                Write-Log "[SKIP] $($adUser.SamAccountName) - NTFS check skipped, folder does not exist"
            }
        }catch{
            Write-Log "[ERROR] $homepath does not exists for $($adUser.SamAccountName)"
            continue
        }

    }else{
        Write-Log "[FAIL] cannot found user with $firstname $lastname"
    }

}
