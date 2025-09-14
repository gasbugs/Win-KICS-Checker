<#
.SYNOPSIS
    Checks if logon warning message title and text are set.

.DESCRIPTION
    This script verifies the presence of a logon warning message, which is displayed to users before they log on.
    This message serves as a legal notice and a deterrent against unauthorized access.
    It checks the 'LegalNoticeCaption' and 'LegalNoticeText' registry values.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W75WarningMessageSetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-75"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $captionProperty = "LegalNoticeCaption"
        $textProperty = "LegalNoticeText"
        
        if (Test-Path $registryPath) {
            $caption = (Get-ItemProperty -Path $registryPath -Name $captionProperty -ErrorAction SilentlyContinue).$captionProperty
            $text = (Get-ItemProperty -Path $registryPath -Name $textProperty -ErrorAction SilentlyContinue).$textProperty

            $isCaptionSet = -not ([string]::IsNullOrEmpty($caption))
            $isTextSet = -not ([string]::IsNullOrEmpty($text))

            if ($isCaptionSet -and $isTextSet) {
                $details = "Logon warning message title and text are set."
            } else {
                $result = "Vulnerable"
                $details = "Logon warning message title or text is not set. "
                if (-not $isCaptionSet) { $details += "Title is missing. " }
                if (-not $isTextSet) { $details += "Text is missing. " }
            }
        } else {
            $result = "Error"
            $details = "Registry path '$registryPath' not found. Cannot check warning message settings."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking warning message settings: $($_.Exception.Message)"
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
Test-W75WarningMessageSetting
