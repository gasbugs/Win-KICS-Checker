<#
.SYNOPSIS
    Checks if SAM file access permissions are restricted to Administrators and System groups only.

.DESCRIPTION
    This script verifies the Access Control List (ACL) of the SAM (Security Account Manager) file.
    The SAM file contains hashed user passwords and sensitive account information.
    Access should be strictly limited to built-in Administrators and System accounts to prevent unauthorized access.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W37SAMFileAccessControl {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-37"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    $samFilePath = "$env:SystemRoot\System32\config\SAM"

    try {
        if (Test-Path $samFilePath) {
            $acl = Get-Acl -Path $samFilePath -ErrorAction SilentlyContinue
            $vulnerablePermissions = @()

            foreach ($access in $acl.Access) {
                $identity = $access.IdentityReference.Value
                $fileSystemRights = $access.FileSystemRights

                # Check for Everyone, Users, Authenticated Users, etc., having excessive rights
                # Or any non-Administrators/System having Write/Modify/FullControl
                # S-1-5-32-544 = Administrators group
                # S-1-5-18 = Local System
                if ($identity -notmatch '(S-1-5-32-544|S-1-5-18|Administrators|SYSTEM)' -and ($fileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write -or $fileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify -or $fileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl)) {
                    $vulnerablePermissions += "Identity: $identity, Rights: $fileSystemRights"
                }
            }

            if ($vulnerablePermissions.Count -eq 0) {
                $details = "SAM file access permissions are appropriately restricted to Administrators and System."
            } else {
                $result = "Vulnerable"
                $details = "SAM file has excessive permissions for the following identities: $($vulnerablePermissions -join '; ')."
            }
        } else {
            $result = "Error"
            $details = "SAM file not found at '$samFilePath'. Cannot check permissions."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking SAM file access control: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W37SAMFileAccessControl
