function Show-W365LaunchDetail {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.CloudPCLaunchDetail')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $items = @(Invoke-W365CliSpinner -Message 'Loading Cloud PC launch details.' -ScriptBlock { Get-CloudPC | Get-CloudPCLaunchDetail | Sort-Object CloudPcName })
        if ($items.Count -eq 0) { Write-Warning 'No launch details were returned.'; return }
        $columnHeader = '{0} {1} {2} {3}' -f (Format-W365CliText -Text 'Cloud PC' -Width 34),(Format-W365CliText -Text 'Status' -Width 14),(Format-W365CliText -Text 'Switch' -Width 8),(Format-W365CliText -Text 'User' -Width 34)
        Select-W365CliObject -InputObject $items -Title 'Windows 365 launch details' -DisplayProperties @('CloudPcName','LaunchDetailStatus','Windows365SwitchCompatible','UserId') -FilterProperties @('CloudPcName','LaunchDetailStatus','UserId') -LabelScript {
            param($Launch)
            '{0} {1} {2} {3}' -f (Format-W365CliText -Text $Launch.CloudPcName -Width 34),(Format-W365CliText -Text $Launch.LaunchDetailStatus -Width 14),(Format-W365CliText -Text $Launch.Windows365SwitchCompatible -Width 8),(Format-W365CliText -Text $Launch.UserId -Width 34)
        } -DetailScript {
            param($Launch)
            @("Cloud PC: $($Launch.CloudPcName)","Status: $($Launch.LaunchDetailStatus)","User: $($Launch.UserId)","Switch compatible: $($Launch.Windows365SwitchCompatible)","Failure reason: $($Launch.Windows365SwitchCompatibilityFailureReasonType)","Launch URL: $($Launch.CloudPcLaunchUrl)","Windows App URI: $($Launch.WindowsAppLaunchUri)","Error: $($Launch.ErrorMessage)")
        } -RefreshScript {
            @(Invoke-W365CliSpinner -Message 'Refreshing Cloud PC launch details.' -ScriptBlock { Get-CloudPC | Get-CloudPCLaunchDetail | Sort-Object CloudPcName })
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Reports','Launch details')
    }
}
