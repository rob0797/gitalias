<#
    build.ps1 - Compila GitAlias in un solo comando.

    Legge i sorgenti da .\src\ e produce in .\dist\ :
      portable\GitAlias-<ver>-portable.zip   DELIVERABLE portable (exe + portable.flag + README)
      installer\Setup-GitAlias.exe           DELIVERABLE installer self-contained (app+uninstaller embedded)
      _work\                                 intermedi (GitAlias.exe, Uninstall.exe, scratch) - ignorabili

    Requisiti: modulo ps2exe  ->  Install-Module ps2exe -Scope CurrentUser
    Uso:       powershell -ExecutionPolicy Bypass -File .\build.ps1
               powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 2.1.0
#>
[CmdletBinding()]
param(
    [string]$Version = '2.0.0'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src  = Join-Path $Root 'src'

# Output: due cartelle di CONSEGNA (portable/ e installer/) + _work per gli intermedi.
$Dist    = Join-Path $Root 'dist'
$RelPort = Join-Path $Dist 'portable'    # -> GitAlias-<ver>-portable.zip (deliverable)
$RelInst = Join-Path $Dist 'installer'   # -> Setup-GitAlias.exe          (deliverable)
$Work    = Join-Path $Dist '_work'       # -> intermedi (app/uninstaller sciolti, scratch)

$Ico      = Join-Path $Src 'app-icon.ico'
$AppSrc   = Join-Path $Src 'gitalias.ps1'
$UninSrc  = Join-Path $Src 'installer\uninstall.ps1'
$InstTpl  = Join-Path $Src 'installer\install.template.ps1'

function Assert-Parse($file) {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file -Raw), [ref]$null)
}
function B64($file) {
    # Base64 su una singola riga: sicuro dentro una stringa single-quote (niente here-string).
    return [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($file))
}

Write-Host "== GitAlias - build v$Version ==" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    throw "Modulo ps2exe mancante. Esegui:  Install-Module ps2exe -Scope CurrentUser"
}
Import-Module ps2exe
if (-not (Test-Path $Ico)) { throw "Icona mancante: $Ico" }
foreach ($d in @($Dist, $RelPort, $RelInst, $Work)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$common = @{ iconFile = $Ico; noConsole = $true; product = 'GitAlias'; company = 'GitAlias'; version = $Version; noOutput = $true; noError = $true }

# Logo (base64) ricavato dall'icona: iniettato nell'header dell'app e nel banner dell'installer.
$logoPng = Join-Path $Work '_logo.png'
& magick ($Ico + '[0]') -resize 96x96 $logoPng
$LogoB64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPng))
Remove-Item $logoPng -Force

# 1) App (inietta il logo nel sorgente prima di compilare) -> intermedio in _work
Write-Host "-> GitAlias.exe" -ForegroundColor Yellow
Assert-Parse $AppSrc
$appFinal = Join-Path $Work '_gitalias.final.ps1'
(Get-Content $AppSrc -Raw).Replace('__LOGO__', $LogoB64) | Set-Content -Path $appFinal -Encoding UTF8
$AppExe = Join-Path $Work 'GitAlias.exe'
Invoke-ps2exe -inputFile $appFinal -outputFile $AppExe -title 'GitAlias' -description 'Cambia identita git con un click' @common
Remove-Item $appFinal -Force

# 2) Uninstaller -> intermedio in _work (finira' incorporato nell'installer)
Write-Host "-> Uninstall.exe" -ForegroundColor Yellow
Assert-Parse $UninSrc
$UninExe = Join-Path $Work 'Uninstall.exe'
Invoke-ps2exe -inputFile $UninSrc -outputFile $UninExe -title 'GitAlias - Uninstall' -description 'Disinstalla GitAlias' @common

# 3) Installer self-contained (inietta versione + payload app/uninstaller nel template) -> dist\installer\
Write-Host "-> Setup-GitAlias.exe" -ForegroundColor Yellow
$final = Join-Path $Work '_install.final.ps1'
$txt = (Get-Content $InstTpl -Raw).
    Replace('__VERSION__', $Version).
    Replace('__LOGO__', $LogoB64).
    Replace('__PAYLOAD_B64__', (B64 $AppExe)).
    Replace('__UNINSTALL_B64__', (B64 $UninExe))
Set-Content -Path $final -Value $txt -Encoding UTF8
Assert-Parse $final
$SetupExe = Join-Path $RelInst 'Setup-GitAlias.exe'
Invoke-ps2exe -inputFile $final -outputFile $SetupExe -title 'GitAlias - Setup' -description 'Installer GitAlias' @common
Remove-Item $final -Force

# 4) Portable (exe + marker + README): scratch in _work, zip finale in dist\portable\
Write-Host "-> portable + zip" -ForegroundColor Yellow
$Scratch = Join-Path $Work 'portable-scratch'
if (Test-Path $Scratch) { Remove-Item $Scratch -Recurse -Force }
New-Item -ItemType Directory -Path $Scratch -Force | Out-Null
Copy-Item $AppExe (Join-Path $Scratch 'GitAlias.exe') -Force
Set-Content -Path (Join-Path $Scratch 'portable.flag') -Value '' -Encoding ASCII   # marker: preferiti accanto all'exe
if (Test-Path (Join-Path $Root 'README.md')) { Copy-Item (Join-Path $Root 'README.md') $Scratch -Force }

$Zip = Join-Path $RelPort ("GitAlias-$Version-portable.zip")
if (Test-Path $Zip) { Remove-Item $Zip -Force }
Compress-Archive -Path (Join-Path $Scratch '*') -DestinationPath $Zip -CompressionLevel Optimal

Write-Host "== FATTO ==" -ForegroundColor Green
Write-Host ""
Write-Host "DELIVERABLE (da condividere):" -ForegroundColor Cyan
Write-Host "  Portable   -> $Zip"
Write-Host "  Installer  -> $SetupExe  (un solo file, uninstaller incluso)"
Write-Host "Intermedi in: $Work  (ignorabili)"
