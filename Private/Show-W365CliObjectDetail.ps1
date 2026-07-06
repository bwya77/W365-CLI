function Show-W365CliObjectDetail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Title,

        [string[]]$DetailProperties,

        [scriptblock]$DetailScript,

        [scriptblock]$ActionScript,

        [string[]]$ActionLabels,

        [scriptblock]$ActionLabelsScript,

        [string[]]$Breadcrumb
    )

    begin { }

    process {
        $lines = @(
            if ($DetailScript) {
                & $DetailScript $InputObject
            }
            elseif ($DetailProperties) {
                foreach ($property in $DetailProperties) {
                    $value = $InputObject.$property
                    if ($null -ne $value -and "$value" -ne '') {
                        "{0}: {1}" -f $property, $value
                    }
                }
            }
            else {
                foreach ($property in $InputObject.PSObject.Properties) {
                    if ($property.Name -like 'Raw*') {
                        continue
                    }

                    if ($null -ne $property.Value -and "$($property.Value)" -ne '') {
                        "{0}: {1}" -f $property.Name, $property.Value
                    }
                }
            }
        )

        $selectedActionIndex = 0

        function Get-ActionItem {
            $rawItems = if ($ActionLabelsScript) {
                @(& $ActionLabelsScript $InputObject)
            }
            else {
                @($ActionLabels)
            }

            @(
                foreach ($item in $rawItems) {
                    if ($item -is [string]) {
                        [pscustomobject]@{
                            Label    = $item
                            Action   = $item
                            Disabled = $false
                            Reason   = $null
                        }
                    }
                    else {
                        [pscustomobject]@{
                            Label    = $item.Label
                            Action   = if ($item.Action) { $item.Action } else { $item.Label }
                            Disabled = [bool]$item.Disabled
                            Reason   = $item.Reason
                        }
                    }
                }
            )
        }

        function Show-DetailScreen {
            $actionItems = Get-ActionItem
            Clear-Host
            Write-Host ''
            if ($Breadcrumb -and $Breadcrumb.Count -gt 0) {
                Write-Host ("Location: {0}" -f ($Breadcrumb -join ' > ')) -ForegroundColor DarkYellow
                Write-Host ''
            }

            Write-Host $Title -ForegroundColor Cyan
            Write-Host ('=' * $Title.Length) -ForegroundColor DarkCyan
            Write-Host ''

            foreach ($line in $lines) {
                Write-Host $line
            }

            Write-Host ''
            if ($ActionScript -and $actionItems -and $actionItems.Count -gt 0) {
                Write-Host 'Actions' -ForegroundColor Cyan
                Write-Host 'Use Up/Down to choose an action, Enter to run, Esc to go back.' -ForegroundColor DarkGray
                for ($index = 0; $index -lt $actionItems.Count; $index++) {
                    $prefix = if ($index -eq $selectedActionIndex) { '>' } else { ' ' }
                    $actionItem = $actionItems[$index]
                    $label = if ($actionItem.Disabled -and $actionItem.Reason) {
                        "{0} (unavailable: {1})" -f $actionItem.Label, $actionItem.Reason
                    }
                    elseif ($actionItem.Disabled) {
                        "{0} (unavailable)" -f $actionItem.Label
                    }
                    else {
                        $actionItem.Label
                    }
                    $line = (" {0} {1}" -f $prefix, $label)
                    if ($index -eq $selectedActionIndex) {
                        if ($actionItem.Disabled) {
                            Write-Host $line -ForegroundColor Gray -BackgroundColor DarkGray
                        }
                        else {
                            Write-Host $line -ForegroundColor White -BackgroundColor DarkCyan
                        }
                    }
                    elseif ($actionItem.Disabled) {
                        Write-Host $line -ForegroundColor DarkGray
                    }
                    else {
                        Write-Host $line
                    }
                }
            }
            else {
                Write-Host 'Press any key to return...' -ForegroundColor DarkGray
            }
        }

        while ($true) {
            Show-DetailScreen
            $actionItems = Get-ActionItem

            $key = [Console]::ReadKey($true)
            if (-not $ActionScript -or -not $actionItems -or $actionItems.Count -eq 0) {
                return
            }

            switch ($key.Key) {
                'UpArrow' {
                    if ($selectedActionIndex -gt 0) {
                        $selectedActionIndex--
                    }
                }
                'DownArrow' {
                    if ($selectedActionIndex -lt ($actionItems.Count - 1)) {
                        $selectedActionIndex++
                    }
                }
                'Home' {
                    $selectedActionIndex = 0
                }
                'End' {
                    $selectedActionIndex = $actionItems.Count - 1
                }
                'Enter' {
                    $actionItem = $actionItems[$selectedActionIndex]
                    if ($actionItem.Disabled) {
                        continue
                    }

                    $script:W365CliCloseDetailRequested = $false
                    & $ActionScript $InputObject $actionItem.Action
                    if ($script:W365CliCloseDetailRequested) {
                        $script:W365CliCloseDetailRequested = $false
                        return
                    }
                }
                'Escape' {
                    return
                }
                'LeftArrow' {
                    return
                }
                default {
                    if ($key.KeyChar -match '^[bBqQ]$') {
                        return
                    }
                }
            }
        }
    }

    end { }
}
