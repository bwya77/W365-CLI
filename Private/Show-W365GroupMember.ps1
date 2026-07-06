function Show-W365GroupMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,

        [string]$GroupName
    )

    begin {
        Import-W365CliWindowsCloudPC
        Connect-CloudPC | Out-Null
    }

    process {
        $escapedGroupId = [uri]::EscapeDataString($GroupId)
        $uri = "https://graph.microsoft.com/v1.0/groups/$escapedGroupId/members?`$select=id,displayName,userPrincipalName,mail,jobTitle"
        $members = @(
            Invoke-GraphPaged -Uri $uri | Sort-Object displayName
        )

        if ($members.Count -eq 0) {
            Write-Warning 'No group members were returned.'
            Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
            return
        }

        $columnHeader = '{0} {1} {2} {3}' -f
            (Format-W365CliText -Text 'Name' -Width 36),
            (Format-W365CliText -Text 'UPN' -Width 38),
            (Format-W365CliText -Text 'Mail' -Width 38),
            (Format-W365CliText -Text 'Job title' -Width 28)

        Select-W365CliObject -InputObject $members -Title "Members of $GroupName" -DisplayProperties @(
            'displayName',
            'userPrincipalName',
            'mail',
            'jobTitle'
        ) -FilterProperties @(
            'displayName',
            'userPrincipalName',
            'mail',
            'jobTitle'
        ) -LabelScript {
            param($Member)

            '{0} {1} {2} {3}' -f
                (Format-W365CliText -Text $Member.displayName -Width 36),
                (Format-W365CliText -Text $Member.userPrincipalName -Width 38),
                (Format-W365CliText -Text $Member.mail -Width 38),
                (Format-W365CliText -Text $Member.jobTitle -Width 28)
        } -DetailScript {
            param($Member)

            @(
                "Name:       $($Member.displayName)"
                "UPN:        $($Member.userPrincipalName)"
                "Mail:       $($Member.mail)"
                "Job title:  $($Member.jobTitle)"
                "Object ID:  $($Member.id)"
            )
        } -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Invoke-GraphPaged -Uri $uri | Sort-Object displayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly -Breadcrumb @('W365CLI','Provisioning','Maintenance windows','Group members') | Out-Null
    }

    end { }
}
