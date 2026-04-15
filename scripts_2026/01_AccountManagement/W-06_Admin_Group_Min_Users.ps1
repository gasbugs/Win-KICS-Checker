# W-06: 관리자 그룹에 최소한의 사용자 포함
function Test-W06 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem    = "W-06"
        Category     = "계정 관리"
        Result       = "Manual Check Required"
        Details      = "Review the members of the 'Administrators' group."
        GroupMembers = @()
        Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $members = Get-LocalGroupMember -Group "Administrators"
        $result.GroupMembers = foreach ($member in $members) {
            @{
                Name            = $member.Name
                PrincipalSource = "$($member.PrincipalSource)"
                ObjectClass     = $member.ObjectClass
                SID             = $member.SID.Value
            }
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while retrieving the 'Administrators' group members: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W06
