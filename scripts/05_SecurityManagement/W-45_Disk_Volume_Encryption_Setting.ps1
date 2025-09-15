<#
.SYNOPSIS
    Checks if disk volumes are encrypted (e.g., with BitLocker).

.DESCRIPTION
    This script verifies the encryption status of all fixed data drives on the system.
    It uses the Win32_EncryptableVolume WMI class to determine if volumes are encrypted and protected,
    providing a more universal check than Get-BitLockerVolume.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including encryption status per volume.
#>

function Test-W45DiskVolumeEncryptionSetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-45"
    $category = "Security Management"
    $result = "Good"
    $details = @()
    $volumeEncryptionStatus = @()

    try {
        # Retrieve all encryptable volumes using CIM
        $encryptableVolumes = Get-CimInstance -Namespace "Root\CIMV2\Security\MicrosoftVolumeEncryption" -ClassName Win32_EncryptableVolume -ErrorAction SilentlyContinue

        if ($encryptableVolumes) {
            $allEncrypted = $true
            foreach ($volume in $encryptableVolumes) {
                # EncryptionMethod: 0=None, 1=AES128, 2=AES256, 3=XTS-AES128, 4=XTS-AES256
                # ProtectionStatus: 0=Off, 1=On, 2=Paused
                # ConversionStatus: 0=FullyDecrypted, 1=FullyEncrypted, 2=EncryptionInProgress, 3=DecryptionInProgress, 4=EncryptionPaused, 5=DecryptionPaused

                $status = @{
                    DriveLetter = $volume.DriveLetter
                    ProtectionStatus = $volume.ProtectionStatus # 0=Off, 1=On, 2=Paused
                    EncryptionMethod = $volume.EncryptionMethod
                    ConversionStatus = $volume.ConversionStatus
                }
                $volumeEncryptionStatus += $status

                # A volume is considered encrypted if ProtectionStatus is 1 (On) and ConversionStatus is 1 (FullyEncrypted)
                if ($volume.ProtectionStatus -ne 1 -or $volume.ConversionStatus -ne 1) {
                    $allEncrypted = $false
                }
            }

            if ($allEncrypted) {
                $details = "All fixed drives are encrypted and fully protected."
            } else {
                $result = "Vulnerable"
                $details = "Some fixed drives are not encrypted or not fully protected. Review volume encryption status."
            }
        } else {
            $result = "Vulnerable"
            $details = "No encryptable volumes found or BitLocker is not enabled on any fixed drives. Disk volume encryption is not configured."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking disk volume encryption: $($_.Exception.Message)."
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        VolumeEncryptionStatus = $volumeEncryptionStatus # Include detailed status for review
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W45DiskVolumeEncryptionSetting