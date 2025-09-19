<#
.SYNOPSIS
    Checks if the 'Maximum password age' policy is set to 90 days or less.

.DESCRIPTION
    This script verifies if the security policy 'Maximum password age'
    is configured to 90 days (or 0 for never expires, which is vulnerable) or less.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W50MaximumPasswordAge {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-50"
    $category = "Account Management"
    $result = "Good"
    $details = ""
    $maxRecommendedDays = 90

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $maximumPasswordAgeRaw = ($content | Select-String -Pattern "MaximumPasswordAge = " | ForEach-Object { $_.ToString().Split("=")[1].Trim() } | Select-Object -First 1)

        if (-not $maximumPasswordAgeRaw) {
            throw "MaximumPasswordAge setting not found in the exported security policy."
        }

        $maximumPasswordAgeDays = $maximumPasswordAgeRaw -as [int]
        if ($null -eq $maximumPasswordAgeDays) {
            throw "Unable to parse MaximumPasswordAge value: '$maximumPasswordAgeRaw'."
        }

        if ($maximumPasswordAgeDays -eq 0) {
            $result = "Vulnerable"
            $details = "The 'Maximum password age' policy is set to never expire (Current value: 0 days)."
        } elseif ($maximumPasswordAgeDays -le $maxRecommendedDays) {
            $details = "The 'Maximum password age' policy is set to $maximumPasswordAgeDays days (Recommended: <= $maxRecommendedDays days)."
        } else {
            $result = "Vulnerable"
            $details = "The 'Maximum password age' policy is set to $maximumPasswordAgeDays days, which is greater than the recommended $maxRecommendedDays days."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking maximum password age policy: $($_.Exception.Message)"
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
Test-W50MaximumPasswordAge
