# W365 CLI

Interactive PowerShell CLI for Windows 365 Cloud PC workflows. It builds on the existing `WindowsCloudPC` module instead of duplicating Microsoft Graph logic.

## Start

Install from PowerShell Gallery:

```powershell
Install-Module W365CLI -Scope CurrentUser
w365
```

Update an existing install:

```powershell
Update-Module W365CLI
```

Use the local source build:

```powershell
Import-Module C:\Git\GitHub\W365-CLI\W365CLI.psd1 -Force
w365
```

Or run the development launcher directly:

```powershell
C:\Git\GitHub\W365-CLI\w365.ps1
```

During local development, W365CLI automatically imports the sibling module at:

```text
C:\Git\GitHub\WindowsCloudPC\WindowsCloudPC.psd1
```

If the sibling repo is not present, it falls back to importing `WindowsCloudPC` from the installed module path.

## Build and publish

Run local validation:

```powershell
.\build.ps1 -Task All
```

Publish is handled by GitHub Actions when a version tag is pushed:

```powershell
git tag v0.1.0
git push origin v0.1.0
```

The release workflow reads the PowerShell Gallery key from the `PSGALLERY_API_KEY` repository secret.

## Current workflows

| Command | Purpose |
| --- | --- |
| `Invoke-W365CLI` | Opens the main interactive menu. Alias: `w365`. |
| `Invoke-W365Resize` | Pick a Cloud PC, filter and pick a target service plan, then preview or submit resize. |
| `Show-W365CloudApp` | Browse, publish, and unpublish Windows 365 Cloud Apps. |
| `Show-W365CloudPC` | Interactive Cloud PC picker with filtering. |
| `Show-W365ConnectivityHistory` | Pick a Cloud PC and browse connectivity events. |
| `Show-W365CustomImage` | Browse tenant-uploaded custom Cloud PC images. |
| `Show-W365DiskSpace` | Interactive Cloud PC disk space report sorted by lowest percent free. |
| `Show-W365GalleryImage` | Interactive Windows 365 gallery image browser. |
| `Show-W365LaunchDetail` | Browse Cloud PC launch details, URLs, and Switch compatibility. |
| `Show-W365LicensingAllotment` | Browse Cloud licensing allotments and capacity. |
| `Show-W365MaintenanceWindow` | Interactive maintenance window browser with assignment details. |
| `Show-W365OrganizationSetting` | Interactive view of tenant-wide Windows 365 organization settings. |
| `Show-W365ProvisioningPolicy` | Interactive provisioning policy browser with management actions. |
| `Show-W365Report` | Browse selected Microsoft Graph Cloud PC report streams. |
| `Show-W365ServicePlan` | Interactive service plan picker with filtering by name, type, vCPU, RAM, and storage. |
| `Show-W365SettingProfile` | Browse Cloud PC setting profiles. |
| `Show-W365Snapshot` | Browse restore point snapshots across all Cloud PCs or one selected Cloud PC. |
| `Show-W365SupportedRegion` | Browse Windows 365 supported regions. |
| `Show-W365UserSetting` | Browse Cloud PC user settings. |
| `Show-W365Usage` | Browse Cloud PC usage, sign-in, current user, and idle-day status. |

The main menu includes an ASCII banner and connection status. When you are already connected, the connection area offers reconnect and disconnect actions, and successful connects do not dump the full Graph context into the menu.

Most menus, browsers, and details include a breadcrumb line such as:

```text
Location: W365CLI > Provisioning > Maintenance windows
```

This makes it clear where you are when drilling into nested workflows.

## Main menu areas

The main menu is grouped by work area:

| Area | Includes |
| --- | --- |
| Cloud PCs | Browse and manage Cloud PCs, resize, rename, disk space, snapshots, remote action history. |
| Provisioning | Provisioning policies, policy copy/export/delete, maintenance windows. |
| Reports | Usage, connectivity history, launch details, snapshots, and Graph Cloud PC report streams. |
| Cloud Apps | Browse Cloud Apps in one filterable table; publish and unpublish. |
| Catalog | Service plans, gallery images, custom images, supported regions, licensing allotments. |
| Tenant settings | Organization-wide Windows 365 defaults, setting profiles, user settings. |
| Connection | Connect, reconnect, or disconnect Microsoft Graph account context. |

## Cloud PC browser

The Cloud PC and service plan browsers are optimized for large tenants:

- Dense single-line rows instead of multi-line cards.
- Fixed columns for important fields.
- Summary rollups with total count, visible count, type, status, vCPU, or storage depending on the browser.
- Paged viewport so thousands of objects remain navigable.
- Detail pane on demand with `D`, `RightArrow`, or `Enter` in browse mode.
- Inline detail actions: remote action history, disk space utilization, snapshots, resize, power on, rename, sync, restart, reset local admin password, restore from snapshot, end grace period, and reprovision.
- Optional remote action history check immediately after submitting device actions.
- Search across key fields like name, assigned user, provisioning type, status, service plan, vCPU, RAM, and storage.

## Inventory and settings screens

The main menu also includes:

- Cloud PC disk space: free, used, total, percent free, last sync, and low/critical free-space rollups.
- Usage: in-use/available status, sign-in status, current user, last active time, and idle days.
- Connectivity history: connection events for a selected Cloud PC.
- Launch details: Cloud PC launch URL, Windows App URI, and Windows 365 Switch compatibility.
- Cloud PC reports: selected Microsoft Graph Cloud PC report streams with configurable top row count.
- Snapshots: browse restore point snapshots, show an empty-state row when none exist, create snapshots from the snapshot browser, and restore or delete from selected snapshot details.
- Gallery images and custom images: image name, status, recommended SKU/build, size, OS version, and lifecycle dates.
- Cloud apps: app status, type, publisher, added/published dates, plus publish and unpublish actions.
- Supported regions: status, solution, region group, and geographic location.
- Licensing allotments: SKU, allotted, consumed, available, waiting members, services, and subscriptions.
- Maintenance windows: schedule summary, notification lead time, and assigned groups.
- Organization settings: default OS version, user account type, MEM auto-enrollment, SSO, Windows language, and an update action.
- Setting profiles and user settings: assignment/state visibility for Windows 365 configuration.

Maintenance window details include inline actions:

- View assigned group members.
- Edit display name, description, notification lead time, and weekday/weekend schedule.
- Delete with preview-first confirmation.

The Provisioning area also includes **Create maintenance window** for the common weekday/weekend schedule model, with optional group assignment.

## Provisioning policy browser

The provisioning policy browser includes:

- Dense policy rows with name, type, image, domain join, SSO, and assigned groups.
- Summary rollups for provisioning type and join type.
- Detail view with inline actions:
  - View Cloud PCs in the policy.
  - Export the policy to reusable JSON.
  - Create a copy from the selected policy.
  - Reprovision every Cloud PC in the policy, with optional exclusions.
  - Delete the policy with preview-first confirmation.

Create copy uses the existing module export/create flow: `Export-CloudPCProvisioningPolicy` into `New-CloudPCProvisioningPolicy`, with optional assignment recreation.

## Keyboard controls

Menus and pickers are key-driven:

| Key | Action |
| --- | --- |
| Up / Down | Move the highlighted selection. |
| PageUp / PageDown | Jump a page in long pickers. |
| Home / End | Jump to the first or last item. |
| Enter | Select the highlighted item. In browse mode, opens details. |
| D or RightArrow | Open details for the highlighted item. |
| F or / | Filter the current picker. |
| C | Clear the active filter. |
| R | Refresh the current data-backed screen. |
| Esc, B, or Q | Go back. |

## Resize flow

```powershell
Invoke-W365Resize
```

The flow:

1. Loads `WindowsCloudPC`.
2. Lists Cloud PCs with a filterable picker.
3. Lists service plans with a filterable picker.
4. Shows a resize preview.
5. Lets you run `-WhatIf` first or submit the resize after typing `RESIZE`.

Use maintenance windows:

```powershell
Invoke-W365Resize -UseMaintenanceWindow
```

## Validate

```powershell
Invoke-Pester C:\Git\GitHub\W365-CLI\Tests
```
