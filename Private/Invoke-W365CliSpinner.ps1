function Invoke-W365CliSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [object[]]$ArgumentList = @()
    )

    begin { }

    process {
        if (-not (Get-Command -Name Start-ThreadJob -ErrorAction SilentlyContinue)) {
            Clear-Host
            Write-Host ''
            Write-Host 'Loading' -ForegroundColor Cyan
            Write-Host $Message -ForegroundColor DarkGray
            & $ScriptBlock
            return
        }

        $moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $repoRoot = Split-Path -Path $moduleRoot -Parent
        $w365CliManifest = Join-Path -Path $moduleRoot -ChildPath 'W365CLI.psd1'
        $windowsCloudPcManifest = Join-Path -Path $repoRoot -ChildPath 'WindowsCloudPC\WindowsCloudPC.psd1'

        $job = Start-ThreadJob -ScriptBlock {
            param(
                [string]$CliManifestPath,
                [string]$WindowsCloudPcManifestPath,
                [scriptblock]$InnerScriptBlock,
                [object[]]$InnerArgumentList
            )

            if (Test-Path -Path $WindowsCloudPcManifestPath) {
                Get-Module WindowsCloudPC | Remove-Module -Force -ErrorAction SilentlyContinue
                Import-Module $WindowsCloudPcManifestPath -Force -ErrorAction Stop
                $expectedRoot = Split-Path -Path $WindowsCloudPcManifestPath -Parent
                $snapshotCommand = Get-Command Get-CloudPCSnapshot -ErrorAction Stop
                if ($snapshotCommand.ScriptBlock.File -and -not $snapshotCommand.ScriptBlock.File.StartsWith($expectedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Spinner loaded WindowsCloudPC from '$($snapshotCommand.ScriptBlock.File)' instead of '$expectedRoot'."
                }
            }

            Import-Module $CliManifestPath -Force -ErrorAction Stop

            & $InnerScriptBlock @InnerArgumentList
        } -ArgumentList $w365CliManifest, $windowsCloudPcManifest, $ScriptBlock, $ArgumentList

        $frames = @('|','/','-','\')
        $index = 0
        $started = Get-Date
        $activeStates = @('NotStarted','Running','Blocked','Suspending','Stopping')

        try {
            while ($job.State -in $activeStates) {
                Clear-Host
                Write-Host ''
                Write-Host 'Loading' -ForegroundColor Cyan
                Write-Host ''
                Write-Host (" {0} {1}" -f $frames[$index % $frames.Count], $Message) -ForegroundColor Yellow
                Write-Host ''
                Write-Host ("Elapsed: {0:n1}s" -f ((Get-Date) - $started).TotalSeconds) -ForegroundColor DarkGray
                Write-Host ("State: {0}" -f $job.State) -ForegroundColor DarkGray
                Write-Host ''
                Write-Host 'Please wait. Do not press keys while data is loading.' -ForegroundColor DarkGray
                $index++
                Start-Sleep -Milliseconds 250
            }

            $result = Receive-Job -Job $job -Wait -AutoRemoveJob -ErrorAction Stop
            Clear-Host
            $result
        }
        finally {
            if ($job -and $job.State -ne 'Completed' -and $job.State -ne 'Failed' -and $job.State -ne 'Stopped') {
                Stop-Job -Job $job -ErrorAction SilentlyContinue
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            }
        }
    }

    end { }
}
