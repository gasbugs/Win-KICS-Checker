# W-61: 파일 및 디렉터리 보호
function Test-W61 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-61"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        $nonNtfs = @()

        foreach ($disk in $disks) {
            if ($disk.FileSystem -ne "NTFS") {
                $nonNtfs += "$($disk.DeviceID) ($($disk.FileSystem ?? 'Unknown'))"
            }
        }

        if ($nonNtfs.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Non-NTFS drives found: $($nonNtfs -join ', '). Convert to NTFS for file/directory protection."
        } else {
            $result.Details = "All fixed drives use NTFS file system."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking file system types: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W61
