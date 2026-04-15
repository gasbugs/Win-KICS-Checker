# W-14: 원격터미널 접속 가능한 사용자 그룹 제한
function Test-W14 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem    = "W-14"
        Category     = "계정 관리"
        Result       = "Good"
        Details      = ""
        GroupMembers = @()
        Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $groupName = "Remote Desktop Users"

    try {
        $group = Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue

        if ($group) {
            $members = Get-LocalGroupMember -Group $groupName -ErrorAction SilentlyContinue
            if ($members) {
                $result.GroupMembers = foreach ($member in $members) {
                    @{
                        Name            = $member.Name
                        SID             = $member.SID.Value
                        PrincipalSource = "$($member.PrincipalSource)"
                        ObjectClass     = $member.ObjectClass
                    }
                }

                $nonAdmin = $result.GroupMembers | Where-Object { $_.SID -notlike "*-500" }
                if ($nonAdmin.Count -eq 0) {
                    $result.Details = "The 'Remote Desktop Users' group contains only the built-in Administrator or is empty."
                } else {
                    $result.Result  = "Manual Check Required"
                    $result.Details = "The 'Remote Desktop Users' group contains non-administrator members. Manual review required."
                }
            } else {
                $result.Details = "The 'Remote Desktop Users' group is empty."
            }
        } else {
            $result.Result = "Not Applicable"
            $result.Details = "Group '$groupName' not found."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking 'Remote Desktop Users' group: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W14
