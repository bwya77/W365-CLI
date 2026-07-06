function Show-W365GalleryImage {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.GalleryImage')]
    param(
        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $items = @(Get-CloudPCGalleryImage | Sort-Object Status, DisplayName)
        if ($items.Count -eq 0) {
            Write-Warning 'No gallery images were returned.'
            return
        }

        $title = if ($Browse) { 'Windows 365 gallery images' } else { 'Pick a Windows 365 gallery image' }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f
            (Format-W365CliText -Text 'Name' -Width 42),
            (Format-W365CliText -Text 'Status' -Width 14),
            (Format-W365CliText -Text 'Recommended SKU' -Width 24),
            (Format-W365CliText -Text 'Size' -Width 8),
            (Format-W365CliText -Text 'OS version' -Width 16),
            (Format-W365CliText -Text 'End date' -Width 18)

        Select-W365CliObject -InputObject $items -Title $title -DisplayProperties @(
            'DisplayName',
            'Status',
            'RecommendedSku',
            'SizeGB',
            'OsVersionNumber',
            'EndDate'
        ) -FilterProperties @(
            'DisplayName',
            'Status',
            'RecommendedSku',
            'OfferDisplayName',
            'SkuDisplayName',
            'PublisherName',
            'OsVersionNumber'
        ) -LabelScript {
            param($Image)

            '{0} {1} {2} {3} {4} {5}' -f
                (Format-W365CliText -Text $Image.DisplayName -Width 42),
                (Format-W365CliText -Text $Image.Status -Width 14),
                (Format-W365CliText -Text $Image.RecommendedSku -Width 24),
                (Format-W365CliText -Text "$($Image.SizeGB) GB" -Width 8),
                (Format-W365CliText -Text $Image.OsVersionNumber -Width 16),
                (Format-W365CliText -Text $Image.EndDate -Width 18)
        } -DetailScript {
            param($Image)

            @(
                "Name:             $($Image.DisplayName)"
                "Status:           $($Image.Status)"
                "Recommended SKU:  $($Image.RecommendedSku)"
                "Size:             $($Image.SizeGB) GB"
                "OS version:       $($Image.OsVersionNumber)"
                "Offer:            $($Image.OfferDisplayName)"
                "SKU:              $($Image.SkuDisplayName)"
                "Publisher:        $($Image.PublisherName)"
                "Start date:       $($Image.StartDate)"
                "End date:         $($Image.EndDate)"
                "Expiration date:  $($Image.ExpirationDate)"
                "Image ID:         $($Image.Id)"
            )
        } -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $statusSummary = @(
                $AllItems |
                    Group-Object -Property Status |
                    Sort-Object Name |
                    ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
            ) -join ' | '

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "Status: $statusSummary"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-CloudPCGalleryImage | Sort-Object Status, DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Catalog','Gallery images')
    }

    end { }
}
