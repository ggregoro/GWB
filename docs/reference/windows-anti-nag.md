# Windows anti-nag settings (manual)

A set of Windows 11 settings that stop the prompts asking you to move to
the new Outlook, make Edge your default browser again, or "finish setting
up" Windows. **Deliberately not automated by `gwb restore`**, for the same
reasons as [IPBan](ipban-manual-install.md):

- Part of it **needs Administrator elevation** (machine-wide Edge
  policies under `HKLM`). `gwb.ps1` never requires that.
- None of it is about the terminal. It changes how Outlook, Edge and
  Windows itself behave, and one step **uninstalls an app**. GWB's scope
  is the terminal you already have (see
  [`../PHILOSOPHY.md`](../PHILOSOPHY.md)).
- Some machines that run `gwb restore` should never have their apps or
  defaults changed as a side effect. Running these by hand, on purpose,
  keeps that choice with you.

Tested on Windows 11 Pro 25H2 (build 26200) with Microsoft 365 Outlook
(classic) 16.0 and Edge 157. Not tested on Windows 10.

**Before you start:**

- `HKLM` policies apply to **every user on the machine**.
- On a work or school PC, Group Policy or Intune may set or override
  these. Ask your IT team first.
- Each block below prints the current values before changing anything.
  Note them down if you want an exact undo.
- **If you adapt these blocks, never run `New-Item -Force` on a registry
  key that already exists.** It recreates the key and silently deletes
  every value already in it. That's why each block creates a key only when
  `Test-Path` says it's missing.

## 1. Outlook: use classic, stop the migration prompts

`UseNewOutlook = 0` makes the Outlook toggle open classic Outlook.
`DoNewOutlookAutoMigration = 0` and `NewOutlookMigrationUserSetting = 0`
turn off the automatic and prompted moves to the new Outlook (both
documented on Microsoft Learn).

The first two are per-user. The third sits under `HKCU\Software\Policies`,
which a normal user can't write, so it's in the Administrator block in
section 3.

Normal (non-admin) PowerShell:

```powershell
$o = 'HKCU:\Software\Microsoft\Office\16.0\Outlook'
foreach ($p in @("$o\Preferences|UseNewOutlook", "$o\Options\General|DoNewOutlookAutoMigration")) {
    $path, $name = $p -split '\|'
    "before: $name = $((Get-ItemProperty $path -ErrorAction SilentlyContinue).$name)"
    if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
    New-ItemProperty $path -Name $name -Value 0 -PropertyType DWord -Force | Out-Null
}
```

### Uninstalling the new Outlook (optional)

**Only after classic Outlook has your mail accounts and is working.**
If you've only ever used the new Outlook, classic may have no profile at
all. Remove the new app first and you're left with no working mail
client. Check first:

```powershell
Get-ChildItem 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles' -ErrorAction SilentlyContinue |
    ForEach-Object PSChildName   # empty = classic has never been set up
```

Start classic from the Start menu entry **"Outlook (classic)"** (the new
app is the one called just "Outlook"), add your accounts, then:

```powershell
Get-AppxPackage -Name Microsoft.OutlookForWindows | Remove-AppxPackage
```

This removes it for the current user only. Windows updates may reinstall
it. To get it back, install "Outlook" from the Microsoft Store.

## 2. Windows tips and "finish setting up" screens

Per-user. These are the switches behind Settings > System > Notifications
> Additional settings ("Suggest ways to get the most out of Windows",
"Get tips and suggestions", "Show the Windows welcome experience"). The
"use Microsoft's recommended browser settings" prompts come through them.
The last line turns off Edge's own Windows notifications, which some of
its nags use instead of a banner inside the browser.

```powershell
$cv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion'
foreach ($p in @(
    "$cv\UserProfileEngagement|ScoobeSystemSettingEnabled",
    "$cv\ContentDeliveryManager|SubscribedContent-338389Enabled",
    "$cv\ContentDeliveryManager|SubscribedContent-310093Enabled",
    "$cv\Notifications\Settings\MSEdge|Enabled")) {
    $path, $name = $p -split '\|'
    "before: $name = $((Get-ItemProperty $path -ErrorAction SilentlyContinue).$name)"
    if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
    New-ItemProperty $path -Name $name -Value 0 -PropertyType DWord -Force | Out-Null
}
```

## 3. Edge policies (Administrator)

Edge stays installed. It can't be fully removed in most regions, and
WebView2 apps depend on it. These policies stop it asking to be the
default browser, showing first-run and promo tabs, and running its
"restore recommended settings" campaign. Check them afterwards at
`edge://policy` (Edge picks them up on its next start).

Run from an **Administrator** PowerShell prompt. It also sets the Outlook
migration policy from section 1, which needs admin too:

```powershell
$pol = @{
    'HKLM:\SOFTWARE\Policies\Microsoft\Edge' = [ordered]@{
        DefaultBrowserSettingEnabled          = 0
        DefaultBrowserSettingsCampaignEnabled = 0
        HideFirstRunExperience                = 1
        ShowRecommendationsEnabled            = 0
        PromotionalTabsEnabled                = 0
    }
    'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences' = [ordered]@{
        NewOutlookMigrationUserSetting = 0
    }
}
foreach ($path in $pol.Keys) {
    if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
    foreach ($name in $pol[$path].Keys) {
        "before: $name = $((Get-ItemProperty $path -ErrorAction SilentlyContinue).$name)"
        New-ItemProperty $path -Name $name -Value $pol[$path][$name] -PropertyType DWord -Force | Out-Null
    }
}
```

`HKCU` inside an elevated prompt is still your own user's hive, as long
as you elevate as yourself (the usual UAC "Yes"). It isn't, if you sign
in as a separate admin account.

## 4. Default browser (by hand only)

Windows 11 protects the default-app choice with a hash, so no supported
script can set it. Do it in **Settings > Apps > Default apps**: pick your
browser and click **Set default**. That covers http, https, .htm and
.html. `.pdf` is separate: change it on the same page.

To check the result from PowerShell, read **`UserChoiceLatest`**. On
recent Windows 11 builds the old `UserChoice` key can still name Edge
after you've switched, and Windows ignores it:

```powershell
$ua = 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations'
$fe = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts'
foreach ($p in 'http','https') { "$p = $((Get-ItemProperty "$ua\$p\UserChoiceLatest\ProgId" -ErrorAction SilentlyContinue).ProgId)" }
foreach ($e in '.htm','.html','.pdf') { "$e = $((Get-ItemProperty "$fe\$e\UserChoiceLatest\ProgId" -ErrorAction SilentlyContinue).ProgId)" }
```

`ftp` and the `microsoft-edge:` / `read:` link types stay on Edge. That's
expected: current browsers don't handle FTP, and Windows keeps its own
link types on Edge.

## Undo

- **Outlook:** set `UseNewOutlook` back to `1` to use the new Outlook
  again. Delete `DoNewOutlookAutoMigration` and
  `NewOutlookMigrationUserSetting` to bring the prompts back.
- **Windows tips:** set the section 2 values back to `1`, or flip the
  same switches in Settings > System > Notifications.
- **Edge:** delete the values you added (or the whole
  `HKLM:\SOFTWARE\Policies\Microsoft\Edge` key if it didn't exist
  before), from an Administrator prompt.

No restart is needed. Restart Outlook and Edge to pick up their changes.
