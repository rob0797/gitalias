# ============================================================
#  GitAlias - Disinstallatore (per-utente, no admin)
#  Strategia: prova il pattern "rilancio da TEMP" (rimozione
#  pulita dell'intera cartella, evita l'avviso PCA di Windows).
#  Se la copia/avvio in TEMP fallisce (es. antivirus), esegue
#  un FALLBACK in-place affidabile (rmdir differito).
#  I dati utente in %APPDATA%\GitAlias NON vengono toccati.
# ============================================================
Add-Type -AssemblyName System.Windows.Forms

$AppName = 'GitAlias'
$Reg     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GitAlias'

function Resolve-BaseDir {
    if ($PSCommandPath) { return (Split-Path -Parent $PSCommandPath) }
    try { return (Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)) } catch { }
    return (Get-Location).Path
}
function Self-Path {
    try { return ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch { return $PSCommandPath }
}
function Remove-Common {
    Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) 'GitAlias.lnk') -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\GitAlias.lnk') -Force -ErrorAction SilentlyContinue
    Remove-Item $script:Reg -Recurse -Force -ErrorAction SilentlyContinue
}
function Show-Done { [System.Windows.Forms.MessageBox]::Show("$AppName rimosso.",$AppName,'OK','Information') | Out-Null }

# ------------------------------------------------------------
#  FASE 1 - avviato dalla cartella installata (via "App" di Windows)
# ------------------------------------------------------------
if ($env:GITALIAS_UNINST -ne '1') {
    $InstallDir = Resolve-BaseDir
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Rimuovere $AppName?`n`nVerranno eliminati i collegamenti, la voce in 'Installazione applicazioni' e la cartella del programma.`n`n(I preferiti in %APPDATA% NON vengono cancellati.)",
        $AppName, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    # Tentativo pulito: copia in TEMP e rilancia da li'
    $temp = Join-Path $env:TEMP 'GitAliasUninstall.exe'
    $ok = $false
    try {
        Copy-Item (Self-Path) $temp -Force -ErrorAction Stop
        $env:GITALIAS_UNINST = '1'
        $env:GITALIAS_DIR    = $InstallDir
        Start-Process $temp -ErrorAction Stop
        $ok = $true
    } catch { $ok = $false }
    if ($ok) { return }

    # FALLBACK in-place: rimozione diretta + rmdir differito dall'esterno
    $ErrorActionPreference = 'SilentlyContinue'
    Get-Process -Name 'GitAlias' | Stop-Process -Force
    Start-Sleep -Milliseconds 300
    Remove-Common
    Show-Done
    $cmd = 'ping 127.0.0.1 -n 3 >nul & rmdir /s /q "{0}"' -f $InstallDir
    Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c ' + $cmd) -WindowStyle Hidden
    return
}

# ------------------------------------------------------------
#  FASE 2 - avviato da %TEMP%: rimozione completa dell'intera cartella
# ------------------------------------------------------------
$ErrorActionPreference = 'SilentlyContinue'
$target = $env:GITALIAS_DIR

Start-Sleep -Milliseconds 500                       # attende l'uscita del processo originale
Get-Process -Name 'GitAlias' | Stop-Process -Force
Remove-Common
if ($target -and (Test-Path $target)) { Remove-Item $target -Recurse -Force }   # nessun file bloccato ora
Show-Done

# autoeliminazione della copia in TEMP (differita, dall'esterno)
$self = Self-Path
$cmd = 'ping 127.0.0.1 -n 2 >nul & del /f /q "{0}"' -f $self
Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c ' + $cmd) -WindowStyle Hidden
