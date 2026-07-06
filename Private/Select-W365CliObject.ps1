function Select-W365CliObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$InputObject,

        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string[]]$DisplayProperties,

        [string[]]$FilterProperties = $DisplayProperties,

        [scriptblock]$LabelScript,

        [string[]]$DetailProperties,

        [scriptblock]$DetailScript,

        [scriptblock]$ActionScript,

        [string[]]$ActionLabels,

        [scriptblock]$ActionLabelsScript,

        [scriptblock]$EmptyActionScript,

        [string[]]$EmptyActionLabels,

        [scriptblock]$NewActionScript,

        [string]$NewActionLabel,

        [scriptblock]$SummaryScript,

        [scriptblock]$RefreshScript,

        [string[]]$Breadcrumb,

        [string]$ColumnHeader,

        [switch]$ViewOnly,

        [ValidateRange(3, 40)]
        [int]$PageSize = 8
    )

    begin { }

    process {
        $filter = ''
        $selectedIndex = 0

        while ($true) {
            $items = @($InputObject)

            if (-not [string]::IsNullOrWhiteSpace($filter)) {
                $items = @(
                    $items | Where-Object {
                        $item = $_
                        foreach ($property in $FilterProperties) {
                            $value = $item.$property
                            if ($null -ne $value -and "$value" -like "*$filter*") {
                                return $true
                            }
                        }

                        return $false
                    }
                )
            }

            if ($items.Count -eq 0) {
                $selectedIndex = 0
            }
            elseif ($selectedIndex -ge $items.Count) {
                $selectedIndex = $items.Count - 1
            }

            $windowStart = 0
            if ($items.Count -gt $PageSize) {
                $halfPage = [math]::Floor($PageSize / 2)
                $maxStart = $items.Count - $PageSize
                $windowStart = [math]::Max(0, [math]::Min($selectedIndex - $halfPage, $maxStart))
            }

            $windowEnd = if ($items.Count -eq 0) { -1 } else { [math]::Min($items.Count - 1, $windowStart + $PageSize - 1) }

            Clear-Host
            Write-Host ''
            if ($Breadcrumb -and $Breadcrumb.Count -gt 0) {
                Write-Host ("Location: {0}" -f ($Breadcrumb -join ' > ')) -ForegroundColor DarkYellow
                Write-Host ''
            }

            Write-Host $Title -ForegroundColor Cyan

            if ($SummaryScript) {
                $summaryLines = @(& $SummaryScript -AllItems $InputObject -VisibleItems $items -Filter $filter -SelectedIndex $selectedIndex)
                foreach ($summaryLine in $summaryLines) {
                    if (-not [string]::IsNullOrWhiteSpace($summaryLine)) {
                        Write-Host $summaryLine -ForegroundColor DarkGray
                    }
                }
            }
            else {
                Write-Host ("Showing {0} of {1}" -f $items.Count, $InputObject.Count) -ForegroundColor DarkGray
            }

            $refreshHint = if ($RefreshScript) { ' | R refresh' } else { '' }
            $newHint = if ($NewActionScript -and $NewActionLabel) { " | N $NewActionLabel" } else { '' }
            Write-Host "Up/Down move | PgUp/PgDn page | Enter select/details | D details | / or F filter | C clear$refreshHint$newHint | Esc back" -ForegroundColor DarkGray
            if ($filter) {
                Write-Host "Filter: $filter"
            }
            Write-Host ''

            if ($items.Count -gt $PageSize) {
                Write-Host ("Showing {0}-{1} of {2}" -f ($windowStart + 1), ($windowEnd + 1), $items.Count) -ForegroundColor DarkGray
            }

            if ($ColumnHeader) {
                Write-Host ("   {0}" -f $ColumnHeader) -ForegroundColor DarkCyan
                Write-Host ("   {0}" -f ('-' * $ColumnHeader.Length)) -ForegroundColor DarkCyan
            }

            if ($items.Count -eq 0) {
                Write-Host '   No rows.' -ForegroundColor DarkGray
                if ($EmptyActionScript -and $EmptyActionLabels -and $EmptyActionLabels.Count -gt 0) {
                    Write-Host ''
                    Write-Host 'Actions' -ForegroundColor Cyan
                    Write-Host 'Use Enter to run the highlighted action, Esc to go back.' -ForegroundColor DarkGray
                    Write-Host (" > {0}" -f $EmptyActionLabels[0]) -ForegroundColor White -BackgroundColor DarkCyan
                }
            }
            else {

                for ($index = $windowStart; $index -le $windowEnd; $index++) {
                    $item = $items[$index]
                    $labelLines = @(
                        if ($LabelScript) {
                            & $LabelScript $item
                        }
                        else {
                            $labelParts = foreach ($property in $DisplayProperties) {
                                $value = $item.$property
                                if ($null -ne $value -and "$value" -ne '') {
                                    "$property=$value"
                                }
                            }

                            $labelParts -join '; '
                        }
                    )

                    $firstLine = if ($labelLines.Count -gt 0) { $labelLines[0] } else { "$item" }
                    $prefix = if ($index -eq $selectedIndex) { '>' } else { ' ' }
                    $line = (" {0} {1}" -f $prefix, $firstLine)

                    if ($index -eq $selectedIndex) {
                        Write-Host $line -ForegroundColor White -BackgroundColor DarkCyan
                    }
                    else {
                        Write-Host $line
                    }

                    foreach ($line in @($labelLines | Select-Object -Skip 1)) {
                        if (-not [string]::IsNullOrWhiteSpace($line)) {
                            Write-Host ("     {0}" -f $line) -ForegroundColor DarkGray
                        }
                    }
                }

                if ($NewActionScript -and $NewActionLabel) {
                    Write-Host ''
                    Write-Host 'Actions' -ForegroundColor Cyan
                    Write-Host 'Press N to run a list action.' -ForegroundColor DarkGray
                    Write-Host ("   N. {0}" -f $NewActionLabel) -ForegroundColor White
                }
            }

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    if ($selectedIndex -gt 0) {
                        $selectedIndex--
                    }
                }
                'DownArrow' {
                    if ($selectedIndex -lt ($items.Count - 1)) {
                        $selectedIndex++
                    }
                }
                'PageUp' {
                    $selectedIndex = [math]::Max(0, $selectedIndex - $PageSize)
                }
                'PageDown' {
                    $selectedIndex = [math]::Min($items.Count - 1, $selectedIndex + $PageSize)
                }
                'Home' {
                    $selectedIndex = 0
                }
                'End' {
                    $selectedIndex = [math]::Max(0, $items.Count - 1)
                }
                'Enter' {
                    if ($items.Count -eq 0) {
                        if ($EmptyActionScript -and $EmptyActionLabels -and $EmptyActionLabels.Count -gt 0) {
                            & $EmptyActionScript $EmptyActionLabels[0]
                        }
                        continue
                    }

                    if ($ViewOnly) {
                        Show-W365CliObjectDetail -InputObject $items[$selectedIndex] -Title $Title -DetailProperties $DetailProperties -DetailScript $DetailScript -ActionScript $ActionScript -ActionLabels $ActionLabels -ActionLabelsScript $ActionLabelsScript -Breadcrumb ($Breadcrumb + $Title)
                        continue
                    }

                    return $items[$selectedIndex]
                }
                'RightArrow' {
                    if ($items.Count -gt 0) {
                        Show-W365CliObjectDetail -InputObject $items[$selectedIndex] -Title $Title -DetailProperties $DetailProperties -DetailScript $DetailScript -ActionScript $ActionScript -ActionLabels $ActionLabels -ActionLabelsScript $ActionLabelsScript -Breadcrumb ($Breadcrumb + $Title)
                    }
                }
                'Escape' {
                    return $null
                }
                'LeftArrow' {
                    return $null
                }
                default {
                    if ($key.KeyChar -match '^[bBqQ]$') {
                        return $null
                    }

                    if ($key.KeyChar -match '^[dD]$' -and $items.Count -gt 0) {
                        Show-W365CliObjectDetail -InputObject $items[$selectedIndex] -Title $Title -DetailProperties $DetailProperties -DetailScript $DetailScript -ActionScript $ActionScript -ActionLabels $ActionLabels -ActionLabelsScript $ActionLabelsScript -Breadcrumb ($Breadcrumb + $Title)
                        continue
                    }

                    if ($key.KeyChar -match '^[cC]$') {
                        $filter = ''
                        $selectedIndex = 0
                        continue
                    }

                    if ($NewActionScript -and $NewActionLabel -and $key.KeyChar -match '^[nN]$') {
                        & $NewActionScript $NewActionLabel
                        continue
                    }

                    if ($RefreshScript -and $key.KeyChar -match '^[rR]$') {
                        Clear-Host
                        Write-Host ''
                        Write-Host "Refreshing $Title..." -ForegroundColor Cyan
                        $InputObject = @(& $RefreshScript)
                        $selectedIndex = 0
                        continue
                    }

                    if ($key.KeyChar -match '^[fF/]$') {
                        Write-Host ''
                        $filter = (Read-Host 'Filter text').Trim()
                        $selectedIndex = 0
                        continue
                    }

                    $number = 0
                    if ([int]::TryParse($key.KeyChar, [ref]$number) -and $number -ge 1 -and $number -le [math]::Min(9, $items.Count)) {
                        $targetIndex = $windowStart + $number - 1
                        if ($targetIndex -lt $items.Count) {
                            if ($ViewOnly) {
                                Show-W365CliObjectDetail -InputObject $items[$targetIndex] -Title $Title -DetailProperties $DetailProperties -DetailScript $DetailScript -ActionScript $ActionScript -ActionLabels $ActionLabels -ActionLabelsScript $ActionLabelsScript -Breadcrumb ($Breadcrumb + $Title)
                                continue
                            }

                            return $items[$targetIndex]
                        }
                    }
                }
            }
        }
    }

    end { }
}
