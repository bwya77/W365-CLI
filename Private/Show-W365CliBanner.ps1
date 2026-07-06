function Show-W365CliBanner {
    [CmdletBinding()]
    param(
        [object]$Connection
    )

    begin { }

    process {
        Write-Host ''
        Write-Host '██╗    ██╗██████╗  ██████╗ ███████╗     ██████╗██╗     ██╗' -ForegroundColor Cyan
        Write-Host '██║    ██║╚════██╗██╔════╝ ██╔════╝    ██╔════╝██║     ██║' -ForegroundColor Cyan
        Write-Host '██║ █╗ ██║ █████╔╝███████╗ ███████╗    ██║     ██║     ██║' -ForegroundColor Cyan
        Write-Host '██║███╗██║ ╚═══██╗██╔═══██╗╚════██║    ██║     ██║     ██║' -ForegroundColor Cyan
        Write-Host '╚███╔███╔╝██████╔╝╚██████╔╝███████║    ╚██████╗███████╗██║' -ForegroundColor Cyan
        Write-Host ' ╚══╝╚══╝ ╚═════╝  ╚═════╝ ╚══════╝     ╚═════╝╚══════╝╚═╝' -ForegroundColor Cyan
        Write-Host '                                                          ' -ForegroundColor Cyan
        $module = Get-Module -Name W365CLI | Select-Object -First 1
        if ($module) {
            Write-Host ("W365CLI v{0} | {1}" -f $module.Version, $module.Author) -ForegroundColor DarkGray
        }
        Write-Host ''

        if ($Connection -and $Connection.Account) {
            Write-Host ("Connected: {0}  Tenant: {1}" -f $Connection.Account, $Connection.TenantId) -ForegroundColor Green
        }
        else {
            Write-Host 'Not connected' -ForegroundColor Yellow
        }
    }

    end { }
}
