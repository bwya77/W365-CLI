function Show-W365SettingProfile {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.SettingProfile')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $items = @(Get-CloudPCSettingProfile -IncludeDetails | Sort-Object DisplayName)
        if ($items.Count -eq 0) { Write-Warning 'No setting profiles were returned.'; return }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text 'Name' -Width 38),(Format-W365CliText -Text 'Type' -Width 18),(Format-W365CliText -Text 'Assigned' -Width 9),(Format-W365CliText -Text 'Priority' -Width 9),(Format-W365CliText -Text 'Assigns' -Width 8),(Format-W365CliText -Text 'Settings' -Width 8)
        Select-W365CliObject -InputObject $items -Title 'Windows 365 setting profiles' -DisplayProperties @('DisplayName','ProfileType','IsAssigned','Priority','AssignmentCount','SettingCount') -FilterProperties @('DisplayName','ProfileType','TemplateId','Description') -LabelScript {
            param($Profile)
            '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text $Profile.DisplayName -Width 38),(Format-W365CliText -Text $Profile.ProfileType -Width 18),(Format-W365CliText -Text $Profile.IsAssigned -Width 9),(Format-W365CliText -Text $Profile.Priority -Width 9),(Format-W365CliText -Text $Profile.AssignmentCount -Width 8),(Format-W365CliText -Text $Profile.SettingCount -Width 8)
        } -DetailScript {
            param($Profile)
            @("Name: $($Profile.DisplayName)","Description: $($Profile.Description)","Type: $($Profile.ProfileType)","Template ID: $($Profile.TemplateId)","Assigned: $($Profile.IsAssigned)","Priority: $($Profile.Priority)","Assignments: $($Profile.AssignmentCount)","Settings: $($Profile.SettingCount)","Modified: $($Profile.LastModifiedDateTime)","Profile ID: $($Profile.Id)")
        } -RefreshScript {
            @(Get-CloudPCSettingProfile -IncludeDetails | Sort-Object DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Tenant settings','Setting profiles')
    }
}
