################################## SCRIPT INFORMATION ##################################
### Script Name: rem_ioc.ps1                                                         ###
### Purpose: Script to clean up files based on file hashes                           ###
### Author: TWFpa2Vs                                                                 ### 
### Version: 1.1.0                                                                   ###
### Version Date: 03 April 2018                                                      ###
### version update: Added ability to remove registry keys                            ###
### Powershell version preferred: V5                                                 ###
################################## SCRIPT INFORMATION ##################################

### WHAT FUNCTIONS DO WE NEED? ####

$DELETEFILES = "N" # Default is N (Y is enabled N is disabled)
$DELETEREGKEYS = "N" # Default is N (Y is enabled N is disabled)

### LOG, INPUT FILES & HASH ALGORITHM ###
$logFile = "\\localhost\Scripts\logfile.log" # network path to write logfile to
$regkeys = Import-Csv -Path "\\localhost\Scripts\regkeys.txt" # network path with regkeys
$hashes = Get-Content "\\localhost\Scripts\hashes.txt" # network path with IOC hashes
$hashalgorithm = "SHA1" # default is SHA1

### SEARCH PATH & EXTENSION ###
$searchPath = "C:\Test" # search pad on the host (Default is C:\)
$searchExt1= ".exe" # set first extension to look for (Default is .exe)
$searchExt2= ".txt" # set second extension to look for (Default is .txt)
$searchExt3= ".bat" # set third extension to look for (Default is .bat)

### OPTION REQUIRES POWERSHELL V5 ###
$searchDept = "1" # specify dept of recurse search (Default is 1)
### change line 64 after Recurse add "-Depth $searchDept -Force"

################################################################################################################################## INPUT EXAMPLE ##################################################################################################################################




############################## INPUT FILE REGKEYS EXAMPLE ##############################
###regpath,regname                                                                   ###
###"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\","Catalyst Control Center"  ###
###"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\","Test"                     ###
###"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\","Test2"                    ###
###                                                                                  ###
### Script needs headers like regpath & regname                                      ###
### replace first part of IOC like HKEY_CURRENT_USER to HKCU:\                       ###
############################## INPUT FILE REGKEYS EXAMPLE ##############################


############################## INPUT FILE HASHES EXAMPLE ###############################
### 4026E982E356B8AFF02CAA2601C6BCB17FB5C645                                         ###
### 7A5DE9DD091C378B7E788D009BC8FCDE289222A5                                         ###
###                                                                                  ###
### Scripts needs a clean input file only containing file hases                      ###
############################## INPUT FILE HASHES EXAMPLE ###############################




######################################################################################################################### DO NOT CHANGE BELOW THIS LINE #########################################################################################################################

if ($DELETEFILES -eq "Y")
    { ### START OF DELETEFILES ###
        foreach ($hash in $hashes) #for each hash do a search on machine
        {
            if ($badFiles = Get-ChildItem -Path $searchPath -Recurse -Force -File | Where-Object {$_.Extension -eq $searchExt1 -or $_.Extension -eq $searchExt2 -or $_.Extension -eq $searchExt3} | Get-Filehash -Algorithm $hashalgorithm | Where-Object {$_.Hash -eq $hash}) # find bad files on host with matching hashes
                {
                    foreach ($badFile in $BadFiles) #for each bad file in found files
                        {
                            Remove-Item $badFile.path -Force # Try to remove the file
                                if (Test-Path $badFile.path) # Test if file is present
                                    {
                                        $status = "$(Get-Date): File with hash $hash found, failed to remove $($badfile.path) from host $env:computername" #if the file still exists deletion has failed
                                    }
                                else
                                    {
                                        $status = "$(Get-Date): File with hash $hash found, removed $($badfile.path) from host $env:computername" #file succesfully deleted, file cannot be found anymore
                                    }
                            $status | Add-Content $logFile # write status to logfile
                        }
                }
            else
                {
                    Write-Output "$(Get-Date): File with $hash not found on host $env:computername" | Add-Content $logFile #if no bad files report back to logfile 
                }   
        }
    } ### END OF DELETEFILES ###

if ($DELETEREGKEYS -eq "Y")
    { ### START OF DELETEREGKEYS ###
        foreach ($key in $regkeys) #for each regkey do a search on machine
        {
            if (Get-ItemProperty -Path $key.regpath -Name $key.regname -ErrorAction SilentlyContinue) # check if key exist
                {
                    Remove-ItemProperty -Path $key.regpath -Name $key.regname # try to remove key
                    if (Get-ItemProperty -Path $key.regpath -Name $key.regname -ErrorAction SilentlyContinue) #check if key is removed
                            {
                                $status = "$(Get-Date): registery key found, failed to remove $($key.regpath)$($key.regname) from host $env:computername" #if the key still exists deletion has failed
                            }
                        else
                            {
                                $status = "$(Get-Date): registery key found, removed $($key.regpath)$($key.regname) from host $env:computername" #key succesfully deleted, key cannot be found anymore
                            }
                    $status | Add-Content $logFile # write status to logfile
                 }
            else
                {
                    Write-Output "$(Get-Date): registery key $($key.regpath)$($key.regname) not found on host $env:computername" | Add-Content $logFile #if no keys where found report back to logfile 
                } 
          } 
    } ### END OF DELETEREGKEYS ###

######################################################################################################################### DO NOT CHANGE ABOVE THIS LINE #########################################################################################################################

### END OF SCRIPT ###
