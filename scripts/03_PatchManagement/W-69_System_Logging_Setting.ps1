<#
.SYNOPSIS
    Checks both Basic and Advanced audit policies against organizational recommendations.

.DESCRIPTION
    This script uses 'auditpol.exe' to check all Basic and Advanced audit policies.
    It compares the current system settings against a predefined list of KISA recommendations.
    If any policy (either Basic or Advanced) is not compliant, the overall result is 'Vulnerable'.

.OUTPUTS
    A JSON object showing the overall result and details of any non-compliant policies from both categories.
#>
function Test-AuditPolicyCompliance-Combined {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-69"
    $category = "Policy and Logging"
    $result = "Good"
    $details = ""
    $vulnerableItems = [System.Collections.Generic.List[string]]::new()

    try {
        # --- 1. 고급 감사 정책(Advanced) 권고 기준 및 점검 ---
        $advancedRecommendations = @{
            "User Account Management"       = "Success"
            "Computer Account Management"   = "Success"
            "Security Group Management"     = "Success"
            "Credential Validation"         = "Success"
            "Kerberos Service Ticket Operations" = "Success"
            "Kerberos Authentication Service"  = "Success"
            "Directory Service Access"      = "Success"
            "Logon"                         = "Success, Failure"
            "Logoff"                        = "Success"
            "Account Lockout"               = "Success"
            "Special Logon"                 = "Success"
            "Network Policy Server"         = "Success, Failure"
            "Audit Policy Change"           = "Success"
            "Authentication Policy Change"  = "Success"
        }
        $currentAdvancedPolicies = auditpol /get /category:* /r | ConvertFrom-Csv
        
        foreach ($subcategory in $advancedRecommendations.Keys) {
            $recommended = $advancedRecommendations[$subcategory]
            $current = ($currentAdvancedPolicies | Where-Object { $_.Subcategory -eq $subcategory }).'Inclusion Setting'
            $normalizedCurrent = if ($current) { $current.Replace(' and ', ', ') } else { $null }

            if ($normalizedCurrent -ne $recommended) {
                $vulnerableItems.Add("▶ [Advanced] $($subcategory): Current '$($current)', Recommended '$($recommended)'")
            }
        }

        # --- 2. 기본 감사 정책(Basic) 권고 기준 및 점검 ---
        $basicRecommendations = @{
            "Object Access"              = "No Auditing"
            "Account Management"         = "Success"
            "Account Logon"              = "Success"
            "Privilege Use"              = "No Auditing"
            "DS Access"                  = "Success"
            "Logon/Logoff"               = "Success and Failure"
            "System"                     = "Success and Failure"
            "Policy Change"              = "Success"
            "Detailed Tracking"          = "No Auditing"
        }
        
        foreach ($categoryName in $basicRecommendations.Keys) {
            $recommended = $basicRecommendations[$categoryName]
            $policyOutput = auditpol /get /category:"$categoryName"
            
            $current = $policyOutput | Select-String -Pattern "Per-user auditing"
            if ($current) {
                $currentSetting = ($current.ToString() -split '\s{2,}')[-1].Trim()
                if ($currentSetting -ne $recommended) {
                     $vulnerableItems.Add("▶ [Basic] $($categoryName): Current '$($currentSetting)', Recommended '$($recommended)'")
                }
            }
        }

        # --- 3. 최종 결과 종합 ---
        if ($vulnerableItems.Count -gt 0) {
            $result = "Vulnerable"
            $details = "The following audit policies differ from recommendations:`n" + ($vulnerableItems -join "`n")
        } else {
            $result = "Good"
            $details = "All Basic and Advanced audit policies are correctly configured according to recommendations."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking audit policies: $($_.Exception.Message)"
    }

    # 최종 결과를 JSON 형태로 출력
    $output = @{
        CheckItem = $checkItem
        Category  = $category
        Result    = $result
        Details   = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $output | ConvertTo-Json -Depth 4
}

# 함수 실행
Test-AuditPolicyCompliance-Combined