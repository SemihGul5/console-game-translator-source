param(
    [Parameter(Mandatory = $true)][string]$CertificateProfile,
    [string]$TizenCli = 'C:\tizen-studio\tools\ide\bin\tizen.bat'
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $TizenCli)) { throw 'Tizen CLI bulunamadı. -TizenCli ile yolunu belirt.' }
Push-Location $PSScriptRoot
try {
    & $TizenCli build-web -- .
    if ($LASTEXITCODE -ne 0) { throw 'Tizen derlemesi başarısız.' }
    New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'output') -Force | Out-Null
    & $TizenCli package -t wgt -s $CertificateProfile -o (Join-Path $PSScriptRoot 'output') -- (Join-Path $PSScriptRoot '.buildResult')
    if ($LASTEXITCODE -ne 0) { throw 'Tizen imzalama başarısız.' }
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'output') -Filter '*.wgt'
} finally { Pop-Location }
