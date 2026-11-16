$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $taskRoot 'samsung_tv'
$target = Join-Path $taskRoot 'assets\tv'
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $taskRoot 'assets\branding\app_icon_all.png') -Destination (Join-Path $source 'icon.png')
$files = @('config.xml','index.html','style.css','receiver.js','app.js','icon.png','README.tr.md','README.en.md','package.ps1','licenses') | ForEach-Object { Join-Path $source $_ }
Compress-Archive -LiteralPath $files -DestinationPath (Join-Path $target 'samsung-receiver.zip') -Force
Write-Output (Join-Path $target 'samsung-receiver.zip')
