function Show-W365CustomImage {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.CustomImage')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $items = @(Get-CloudPCCustomImage | Sort-Object Status, DisplayName)
        if ($items.Count -eq 0) { Write-Warning 'No custom images were returned.'; return }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text 'Name' -Width 40),(Format-W365CliText -Text 'Status' -Width 14),(Format-W365CliText -Text 'OS' -Width 16),(Format-W365CliText -Text 'Build' -Width 14),(Format-W365CliText -Text 'Size' -Width 8),(Format-W365CliText -Text 'Modified' -Width 22)
        Select-W365CliObject -InputObject $items -Title 'Windows 365 custom images' -DisplayProperties @('DisplayName','Status','OperatingSystem','OsBuildNumber','SizeGB','LastModifiedDateTime') -FilterProperties @('DisplayName','Status','OperatingSystem','OsBuildNumber','Version','OsVersionNumber') -LabelScript {
            param($Image)
            '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text $Image.DisplayName -Width 40),(Format-W365CliText -Text $Image.Status -Width 14),(Format-W365CliText -Text $Image.OperatingSystem -Width 16),(Format-W365CliText -Text $Image.OsBuildNumber -Width 14),(Format-W365CliText -Text "$($Image.SizeGB) GB" -Width 8),(Format-W365CliText -Text $Image.LastModifiedDateTime -Width 22)
        } -DetailScript {
            param($Image)
            @("Name: $($Image.DisplayName)","Status: $($Image.Status)","Status details: $($Image.StatusDetails)","Error code: $($Image.ErrorCode)","OS: $($Image.OperatingSystem)","OS build: $($Image.OsBuildNumber)","OS version: $($Image.OsVersionNumber)","Version: $($Image.Version)","Size: $($Image.SizeGB) GB","Expires: $($Image.ExpirationDate)","Modified: $($Image.LastModifiedDateTime)","Source image: $($Image.SourceImageResourceId)","Image ID: $($Image.Id)")
        } -SummaryScript {
            param([object[]]$AllItems,[object[]]$VisibleItems,[string]$Filter,[int]$SelectedIndex)
            $statusSummary = @($AllItems | Group-Object Status | Sort-Object Name | ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }) -join ' | '
            @("Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))","Status: $statusSummary",$(if ($Filter) { "Search: $Filter" } else { 'Search: none' }))
        } -RefreshScript {
            @(Get-CloudPCCustomImage | Sort-Object Status, DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Catalog','Custom images')
    }
}
