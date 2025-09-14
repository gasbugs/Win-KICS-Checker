<#
.SYNOPSIS
    Checks if the 'Domain member: Disable machine account password changes' policy is disabled and 'Domain member: Maximum machine account password age' is set to 90 days.

.DESCRIPTION
    This script verifies two security policies related to computer account password management.
    It ensures that machine account password changes are not disabled and that the maximum age is set to 90 days,
    promoting regular password rotation for domain members.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W80ComputerAccountPasswordMaxAge {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-80"
    $category = "Security Management"
    $result = "Good"
    $details = @()
    $recommendedMaxAgeSeconds = 90 * 24 * 60 * 60 # 90 days

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $disableMachineAccountPasswordChange = ($content | Select-String -Pattern "DisableMachineAccountPasswordChange = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $maximumMachineAccountPasswordAge = ($content | Select-String -Pattern "MaximumMachineAccountPasswordAge = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $isDisableChangeGood = ($disableMachineAccountPasswordChange -eq 0)
        $isMaxAgeGood = ($maximumMachineAccountPasswordAge -eq $recommendedMaxAgeSeconds)

        if (-not $isDisableChangeGood) {
            $result = "Vulnerable"
            $details += "'Domain member: Disable machine account password changes' policy is enabled (Current: $disableMachineAccountPasswordChange). "
        }
        if (-not $isMaxAgeGood) {
            $result = "Vulnerable"
            $details += "'Domain member: Maximum machine account password age' policy is not set to 90 days (Current: $($maximumMachineAccountPasswordAge / (24*60*60)) days). "
        }

        if ($result -eq "Good") {
            $details = "Both computer account password policies are configured as recommended."
        } elseif ($details.Count -gt 0) {
            $details = "Computer account password policies are vulnerable: " + ($details -join [Environment]::NewLine)
        } else {
            $result = "Error"
            $details = "Could not retrieve all computer account password policy settings."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking computer account password policies: $($_.Exception.Message)"
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
Test-W80ComputerAccountPasswordMaxAge
