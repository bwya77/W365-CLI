#Requires -Version 7.0

[CmdletBinding()]
param()

Get-Module W365CLI, WindowsCloudPC | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\W365CLI.psd1" -Force -ErrorAction Stop
Invoke-W365CLI
