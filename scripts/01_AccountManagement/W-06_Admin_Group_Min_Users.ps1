# W-06: Minimum Users in Administrators Group Check

$result = [PSCustomObject]@{
    "CheckItem" = "W-06"
    "Category" = "Account Management"
    "Result" = "Manual Check Required"
    "Details" = "Review the members of the 'Administrators' group in the 'GroupMembers' property."
    "GroupMembers" = @()
    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    # Get the members of the local 'Administrators' group
    $members = Get-LocalGroupMember -Group "Administrators"

    $memberList = foreach ($member in $members) {
        [PSCustomObject]@{
            Name = $member.Name
            PrincipalSource = $member.PrincipalSource # e.g., Local, Active Directory
            ObjectClass = $member.ObjectClass # e.g., User, Group
            SID = $member.SID.Value
        }
    }

    $result.GroupMembers = $memberList
} catch {
    $result.Result = "Error"
    $result.Details = "An error occurred while retrieving the members of the 'Administrators' group. $_"
}

$result | ConvertTo-Json
