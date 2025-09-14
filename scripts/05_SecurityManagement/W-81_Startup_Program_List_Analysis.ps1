<#
.SYNOPSIS
    Analyzes the list of startup programs for unnecessary or suspicious entries.

.DESCRIPTION
    This script enumerates startup programs from common locations (Startup folders, Run registry keys).
    Determining if a startup program is 'unnecessary' or 'malicious' requires human intelligence and context-specific knowledge.
    Therefore, this check reports all identified startup programs and requires manual review.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including a list of startup programs.
#>

function Test-W81StartupProgramListAnalysis {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-81"
    $category = "Security Management"
    $result = "Manual Check Required"
    $details = "Review the list of startup programs to identify and disable/remove any unnecessary or suspicious ones."
    $startupPrograms = @()

    try {
        # Startup folder for current user
        $startupPrograms += Get-ChildItem -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | Select-Object Name, FullName, @{Name='Source';Expression={'Current User Startup Folder'}}

        # Startup folder for all users
        $startupPrograms += Get-ChildItem -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | Select-Object Name, FullName, @{Name='Source';Expression={'All Users Startup Folder'}}

        # Function to get registry run entries
        function Get-RegistryRunEntries {
            param(
                [string]$Path,
                [string]$Source
            )
            try {
                $regKey = Get-Item -Path $Path -ErrorAction SilentlyContinue
                if ($regKey) {
                    foreach ($propName in $regKey.Property) {
                        if ($propName -ne '(default)') {
                            $value = $regKey.GetValue($propName)
                            [PSCustomObject]@{Name=$propName; FullName=$value; Source=$Source}
                        }
                    }
                }
            } catch {
                $errorMessage = $_.Exception.Message
                Write-Warning ("Error accessing registry path {0}: {1}" -f $Path, $errorMessage)
            }
        }

        # Run registry key for current user
        $startupPrograms += Get-RegistryRunEntries -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Source 'Current User Run Registry'

        # RunOnce registry key for current user
        $startupPrograms += Get-RegistryRunEntries -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Source 'Current User RunOnce Registry'

        # Run registry key for local machine
        $startupPrograms += Get-RegistryRunEntries -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Source 'Local Machine Run Registry'

        # RunOnce registry key for local machine
        $startupPrograms += Get-RegistryRunEntries -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Source 'Local Machine RunOnce Registry'

        if ($startupPrograms.Count -eq 0) {
            $details = "No startup programs found in common locations. (Good)"
            $result = "Good"
        } else {
            $details = "The following startup programs were found. Manual review is required to identify and disable/remove any unnecessary or suspicious ones." + [Environment]::NewLine + ($startupPrograms | Out-String)
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while analyzing startup programs: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        StartupPrograms = $startupPrograms # Include program details for manual review
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W81StartupProgramListAnalysis
