function Read-W365CliChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [string[]]$Choices,

        [switch]$AllowBack,

        [string[]]$Breadcrumb,

        [scriptblock]$HeaderScript
    )

    begin { }

    process {
        $selectedIndex = 0

        while ($true) {
            Clear-Host
            Write-Host ''

            if ($HeaderScript) {
                & $HeaderScript
                Write-Host ''
            }

            if ($Breadcrumb -and $Breadcrumb.Count -gt 0) {
                Write-Host ("Location: {0}" -f ($Breadcrumb -join ' > ')) -ForegroundColor DarkYellow
                Write-Host ''
            }

            Write-Host $Prompt -ForegroundColor Cyan
            Write-Host 'Use Up/Down arrows, Enter to select, Esc to go back.' -ForegroundColor DarkGray

            for ($index = 0; $index -lt $Choices.Count; $index++) {
                $prefix = if ($index -eq $selectedIndex) { '>' } else { ' ' }
                $line = (" {0} {1}" -f $prefix, $Choices[$index])

                if ($index -eq $selectedIndex) {
                    Write-Host $line -ForegroundColor White -BackgroundColor DarkCyan
                }
                else {
                    Write-Host $line
                }
            }

            if ($AllowBack) {
                Write-Host ''
                Write-Host 'Esc. Back'
            }

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    if ($selectedIndex -gt 0) {
                        $selectedIndex--
                    }
                }
                'DownArrow' {
                    if ($selectedIndex -lt ($Choices.Count - 1)) {
                        $selectedIndex++
                    }
                }
                'Home' {
                    $selectedIndex = 0
                }
                'End' {
                    $selectedIndex = $Choices.Count - 1
                }
                'Enter' {
                    return $selectedIndex
                }
                'Escape' {
                    if ($AllowBack) {
                        return -1
                    }
                }
                default {
                    $number = 0
                    if ([int]::TryParse($key.KeyChar, [ref]$number) -and $number -ge 1 -and $number -le $Choices.Count) {
                        return ($number - 1)
                    }
                }
            }
        }
    }

    end { }
}
