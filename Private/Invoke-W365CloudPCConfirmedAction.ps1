function Invoke-W365CloudPCConfirmedAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CloudPC,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [string]$TargetType = 'Cloud PC',

        [Parameter(Mandatory)]
        [scriptblock]$PreviewScript,

        [Parameter(Mandatory)]
        [scriptblock]$SubmitScript,

        [hashtable]$Context = @{},

        [switch]$OfferRemoteActionHistory
    )

    begin { }

    process {
        Clear-Host
        Write-Host ''
        Write-Host "$ActionName $TargetType" -ForegroundColor Cyan
        Write-Host ("Target: {0}" -f $CloudPC.Name)
        if ($CloudPC.AssignedUserUpn) {
            Write-Host ("User:   {0}" -f $CloudPC.AssignedUserUpn)
        }
        Write-Host ''

        $choice = Read-W365CliChoice -Prompt 'Choose action' -Choices @(
            'Preview only with -WhatIf',
            'Submit now',
            'Cancel'
        ) -AllowBack

        switch ($choice) {
            0 {
                & $PreviewScript $CloudPC $Context
            }
            1 {
                $confirmChoice = Read-W365CliChoice -Prompt "Submit $ActionName now?" -Choices @(
                    'Confirm',
                    'Cancel'
                ) -AllowBack

                if ($confirmChoice -ne 0) {
                    Write-Warning "$ActionName cancelled."
                    return
                }

                & $SubmitScript $CloudPC $Context

                if ($OfferRemoteActionHistory) {
                    $historyChoice = Read-W365CliChoice -Prompt 'Check remote action history now?' -Choices @(
                        'Yes',
                        'No'
                    ) -AllowBack

                    if ($historyChoice -eq 0) {
                        Show-W365CloudPCRemoteActionHistory -CloudPC $CloudPC
                    }
                }
            }
            default {
                Write-Host "$ActionName cancelled."
            }
        }

        Write-Host ''
        Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
        [Console]::ReadKey($true) | Out-Null
    }

    end { }
}
