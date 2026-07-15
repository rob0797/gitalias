# ============================================================
#  GitAlias - Setup (wizard, self-contained, per-utente, no admin)
#  Installa in %LOCALAPPDATA%\Programs\GitAlias.
#  Token iniettati al build: __VERSION__ __LOGO__ __PAYLOAD_B64__ __UNINSTALL_B64__
# ============================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$AppName = 'GitAlias'
$Version = '__VERSION__'

# Payload (base64, singola riga) iniettati in fase di build
$LogoB64       = '__LOGO__'
$payload       = '__PAYLOAD_B64__'
$payloadUninst = '__UNINSTALL_B64__'

# ---------- Palette / kit UI arrotondato ----------
function C($r,$g,$b){ [System.Drawing.Color]::FromArgb($r,$g,$b) }
function Pt($x,$y){ New-Object System.Drawing.Point([int]$x,[int]$y) }
function Sz($w,$h){ New-Object System.Drawing.Size([int]$w,[int]$h) }
function Fnt($n,$s,$st='Regular'){ New-Object System.Drawing.Font($n,$s,[System.Drawing.FontStyle]::$st) }
$Ink=C 30 30 32; $Muted=C 120 120 128; $Charco=C 34 34 38; $Gold=C 201 162 75; $GoldHi=C 214 176 92; $Line=C 223 223 228; $White=[System.Drawing.Color]::White
function RoundPath([int]$w,[int]$h,[int]$r){
    $d=$r*2; $gp=New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddArc(0,0,$d,$d,180,90); $gp.AddArc($w-$d-1,0,$d,$d,270,90)
    $gp.AddArc($w-$d-1,$h-$d-1,$d,$d,0,90); $gp.AddArc(0,$h-$d-1,$d,$d,90,90); $gp.CloseAllFigures(); return $gp
}
function Round-Button($b,$fill,$hover,$fg,$border){
    $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=0; $b.BackColor=$fill; $b.ForeColor=$fg; $b.Cursor='Hand'
    $b.Tag=@{ fill=$fill; hover=$hover; fg=$fg; border=$border; over=$false; r=9 }
    $b.Add_MouseEnter({ $this.Tag.over=$true; $this.Invalidate() })
    $b.Add_MouseLeave({ $this.Tag.over=$false; $this.Invalidate() })
    $b.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor); $gp=RoundPath $s.Width $s.Height $s.Tag.r
        $col= if($s.Tag.over){ $s.Tag.hover } else { $s.Tag.fill }
        $sb=New-Object System.Drawing.SolidBrush($col); $g.FillPath($sb,$gp); $sb.Dispose()
        if($s.Tag.border){ $pen=New-Object System.Drawing.Pen($s.Tag.border,1); $g.DrawPath($pen,$gp); $pen.Dispose() }
        $fl=[System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter
        [System.Windows.Forms.TextRenderer]::DrawText($g,$s.Text,$s.Font,$s.ClientRectangle,$s.Tag.fg,$fl); $gp.Dispose()
    })
}
function Style-Primary($b){ $b.Font=Fnt 'Segoe UI Semibold' 9 'Bold'; Round-Button $b $Gold $GoldHi $Ink $null }
function Style-Secondary($b){ Round-Button $b $White (C 245 245 246) $Ink $Line }
function Round-Panel($p,$fill,$border,[int]$r){
    $p.BackColor=$fill; $p.Tag=@{ fill=$fill; border=$border; r=$r }
    $p.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor); $gp=RoundPath $s.Width $s.Height $s.Tag.r
        $sb=New-Object System.Drawing.SolidBrush($s.Tag.fill); $g.FillPath($sb,$gp); $sb.Dispose()
        if($s.Tag.border){ $pen=New-Object System.Drawing.Pen($s.Tag.border,1); $g.DrawPath($pen,$gp); $pen.Dispose() }; $gp.Dispose()
    })
}
function Round-Check($cb){
    $cb.AutoSize=$false; $cb.Size=Sz 320 22; $cb.Cursor='Hand'; $cb.BackColor=$White; $cb.ForeColor=$Ink
    $cb.Add_CheckedChanged({ $this.Invalidate() })
    $cb.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor)
        $cy=[int](($s.Height-16)/2)
        $gp=RoundPath 16 16 4
        $st=$g.Save(); $g.TranslateTransform(1,$cy)
        if($s.Checked){
            $sb=New-Object System.Drawing.SolidBrush($script:Gold); $g.FillPath($sb,$gp); $sb.Dispose()
            $pen=New-Object System.Drawing.Pen($script:Ink,2)
            $pts=[System.Drawing.Point[]]@((New-Object System.Drawing.Point(4,8)),(New-Object System.Drawing.Point(7,11)),(New-Object System.Drawing.Point(12,4)))
            $g.DrawLines($pen,$pts)
            $pen.Dispose()
        } else {
            $pen=New-Object System.Drawing.Pen((C 172 172 180),2); $g.DrawPath($pen,$gp); $pen.Dispose()
        }
        $g.Restore($st); $gp.Dispose()
        $rect=New-Object System.Drawing.Rectangle(26,0,($s.Width-26),$s.Height)
        $fl=[System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter
        [System.Windows.Forms.TextRenderer]::DrawText($g,$s.Text,$s.Font,$rect,$script:Ink,$fl)
    })
}
function New-RoundInput($parent,$x,$y,$w,$h){
    $pan=New-Object System.Windows.Forms.Panel; $pan.Location=Pt $x $y; $pan.Size=Sz $w $h
    Round-Panel $pan $White $Line 7; $parent.Controls.Add($pan)
    $tb=New-Object System.Windows.Forms.TextBox; $tb.BorderStyle='None'; $tb.BackColor=$White; $tb.ForeColor=$Ink; $tb.Font=Fnt 'Segoe UI' 9.5
    $tb.Location=Pt 10 ([int](($h-16)/2)); $tb.Size=Sz ($w-20) 18; $pan.Controls.Add($tb); return $tb
}

# ---------- Finestra ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "$AppName - Installazione"
$form.ClientSize = Sz 560 410
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false; $form.MinimizeBox = $false
$form.Font = Fnt 'Segoe UI' 9; $form.BackColor = $White
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch {}

# ---------- Sidebar (banner) ----------
$side = New-Object System.Windows.Forms.Panel
$side.Location = Pt 0 0; $side.Size = Sz 190 360; $side.BackColor = $Charco
$form.Controls.Add($side)

$pbLogo = New-Object System.Windows.Forms.PictureBox
$pbLogo.Location = Pt 57 46; $pbLogo.Size = Sz 76 76; $pbLogo.SizeMode='Zoom'; $pbLogo.BackColor=$Charco
try { $b=[System.Convert]::FromBase64String($LogoB64); $ms=New-Object System.IO.MemoryStream(,$b); $pbLogo.Image=[System.Drawing.Image]::FromStream($ms) } catch {}
$side.Controls.Add($pbLogo)

$sName = New-Object System.Windows.Forms.Label
$sName.Text=$AppName; $sName.Font=Fnt 'Segoe UI Semibold' 17 'Bold'; $sName.ForeColor=$Gold; $sName.BackColor=$Charco
$sName.TextAlign='MiddleCenter'; $sName.Location=Pt 0 132; $sName.Size=Sz 190 30
$side.Controls.Add($sName)
$sVer = New-Object System.Windows.Forms.Label
$sVer.Text="versione $Version"; $sVer.ForeColor=(C 150 150 156); $sVer.BackColor=$Charco
$sVer.TextAlign='MiddleCenter'; $sVer.Location=Pt 0 162; $sVer.Size=Sz 190 20
$side.Controls.Add($sVer)
$sTag = New-Object System.Windows.Forms.Label
$sTag.Text="Cambia identita git`ncon un click"; $sTag.ForeColor=(C 140 140 146); $sTag.BackColor=$Charco
$sTag.TextAlign='MiddleCenter'; $sTag.Location=Pt 0 300; $sTag.Size=Sz 190 40
$side.Controls.Add($sTag)

# ---------- Area contenuti (4 pannelli sovrapposti) ----------
$cx=206; $cw=336
function New-Step { $p=New-Object System.Windows.Forms.Panel; $p.Location=Pt 190 0; $p.Size=Sz 370 360; $p.BackColor=$White; $p.Visible=$false; $form.Controls.Add($p); return $p }

# -- Step 0: Benvenuto --
$st0 = New-Step
$t0 = New-Object System.Windows.Forms.Label; $t0.Text="Benvenuto"; $t0.Font=Fnt 'Segoe UI Semibold' 15 'Bold'; $t0.ForeColor=$Ink; $t0.Location=Pt 16 40; $t0.AutoSize=$true; $st0.Controls.Add($t0)
$d0 = New-Object System.Windows.Forms.Label; $d0.Text="Questa procedura installera $AppName sul tuo computer.`n`nGitAlias cambia l'identita git (user.name / user.email) globale o per singolo repository, con preferiti salvabili.`n`nL'installazione e' solo per l'utente corrente e non richiede diritti di amministratore.`n`nPremi Avanti per continuare."; $d0.Location=Pt 16 84; $d0.Size=Sz 340 220; $st0.Controls.Add($d0)

# -- Step 1: Opzioni --
$st1 = New-Step
$t1 = New-Object System.Windows.Forms.Label; $t1.Text="Opzioni di installazione"; $t1.Font=Fnt 'Segoe UI Semibold' 15 'Bold'; $t1.ForeColor=$Ink; $t1.Location=Pt 16 34; $t1.AutoSize=$true; $st1.Controls.Add($t1)
$lp = New-Object System.Windows.Forms.Label; $lp.Text="CARTELLA DI INSTALLAZIONE"; $lp.Font=Fnt 'Segoe UI Semibold' 7.5 'Bold'; $lp.ForeColor=$Muted; $lp.Location=Pt 16 84; $lp.AutoSize=$true; $st1.Controls.Add($lp)
$txtPath = New-RoundInput $st1 16 102 250 28; $txtPath.Text=(Join-Path $env:LOCALAPPDATA 'Programs\GitAlias')
$btnPath = New-Object System.Windows.Forms.Button; $btnPath.Text='Sfoglia'; $btnPath.Location=Pt 272 102; $btnPath.Size=Sz 84 28; Style-Secondary $btnPath; $st1.Controls.Add($btnPath)
$chkDesktop = New-Object System.Windows.Forms.CheckBox; $chkDesktop.Text='Crea collegamento sul Desktop'; $chkDesktop.Location=Pt 16 152; $chkDesktop.Checked=$true; Round-Check $chkDesktop; $st1.Controls.Add($chkDesktop)
$chkStart = New-Object System.Windows.Forms.CheckBox; $chkStart.Text='Aggiungi al menu Start'; $chkStart.Location=Pt 16 182; $chkStart.Checked=$true; Round-Check $chkStart; $st1.Controls.Add($chkStart)

# -- Step 2: Avanzamento --
$st2 = New-Step
$t2 = New-Object System.Windows.Forms.Label; $t2.Text="Installazione in corso"; $t2.Font=Fnt 'Segoe UI Semibold' 15 'Bold'; $t2.ForeColor=$Ink; $t2.Location=Pt 16 40; $t2.AutoSize=$true; $st2.Controls.Add($t2)
$pb = New-Object System.Windows.Forms.ProgressBar; $pb.Location=Pt 16 110; $pb.Size=Sz 340 20; $pb.Style='Continuous'; $pb.Minimum=0; $pb.Maximum=100; $st2.Controls.Add($pb)
$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text=""; $lblStatus.ForeColor=$Muted; $lblStatus.Location=Pt 16 138; $lblStatus.Size=Sz 340 40; $st2.Controls.Add($lblStatus)

# -- Step 3: Fine --
$st3 = New-Step
$t3 = New-Object System.Windows.Forms.Label; $t3.Text="Installazione completata"; $t3.Font=Fnt 'Segoe UI Semibold' 15 'Bold'; $t3.ForeColor=$Ink; $t3.Location=Pt 16 40; $t3.AutoSize=$true; $st3.Controls.Add($t3)
$d3 = New-Object System.Windows.Forms.Label; $d3.Text="$AppName e' stato installato correttamente.`n`nTrovi i collegamenti creati sul Desktop e/o nel menu Start."; $d3.Location=Pt 16 84; $d3.Size=Sz 340 90; $st3.Controls.Add($d3)
$chkLaunch = New-Object System.Windows.Forms.CheckBox; $chkLaunch.Text="Avvia $AppName ora"; $chkLaunch.Location=Pt 16 180; $chkLaunch.Checked=$true; Round-Check $chkLaunch; $st3.Controls.Add($chkLaunch)

# ---------- Barra pulsanti ----------
$bar = New-Object System.Windows.Forms.Panel; $bar.Location=Pt 0 360; $bar.Size=Sz 560 50; $bar.BackColor=(C 245 245 246); $form.Controls.Add($bar)
$btnBack   = New-Object System.Windows.Forms.Button; $btnBack.Text='Indietro'; $btnBack.Location=Pt 280 9; $btnBack.Size=Sz 82 32; Style-Secondary $btnBack; $bar.Controls.Add($btnBack)
$btnNext   = New-Object System.Windows.Forms.Button; $btnNext.Text='Avanti';   $btnNext.Location=Pt 366 9; $btnNext.Size=Sz 90 32; Style-Primary $btnNext; $bar.Controls.Add($btnNext)
$btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text='Annulla'; $btnCancel.Location=Pt 462 9; $btnCancel.Size=Sz 84 32; Style-Secondary $btnCancel; $bar.Controls.Add($btnCancel)

# ---------- Logica installazione ----------
function Do-Install {
    $InstallDir = $txtPath.Text.Trim()
    $ExePath    = Join-Path $InstallDir 'GitAlias.exe'
    $UninstExe  = Join-Path $InstallDir 'Uninstall.exe'
    try {
        $lblStatus.Text = 'Preparazione...'; $pb.Value = 5; [System.Windows.Forms.Application]::DoEvents()
        Get-Process -Name 'GitAlias' -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Milliseconds 300
        if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }

        $lblStatus.Text = 'Copia dell''applicazione...'; $pb.Value = 30; [System.Windows.Forms.Application]::DoEvents()
        [System.IO.File]::WriteAllBytes($ExePath, [System.Convert]::FromBase64String(($payload -replace '\s','')))
        [System.IO.File]::WriteAllBytes($UninstExe, [System.Convert]::FromBase64String(($payloadUninst -replace '\s','')))
        Remove-Item (Join-Path $InstallDir 'uninstall.ps1') -Force -ErrorAction SilentlyContinue

        $lblStatus.Text = 'Creazione collegamenti...'; $pb.Value = 65; [System.Windows.Forms.Application]::DoEvents()
        $ws = New-Object -ComObject WScript.Shell
        $targets = @()
        if ($chkDesktop.Checked) { $targets += [Environment]::GetFolderPath('Desktop') }
        if ($chkStart.Checked)   { $targets += (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs') }
        foreach ($dir in $targets) {
            $sc = $ws.CreateShortcut((Join-Path $dir 'GitAlias.lnk'))
            $sc.TargetPath = $ExePath; $sc.WorkingDirectory = $InstallDir
            $sc.Description = 'Cambia identita git (user.name/user.email) con un click'
            $sc.IconLocation = "$ExePath,0"; $sc.Save()
        }

        $lblStatus.Text = 'Registrazione...'; $pb.Value = 85; [System.Windows.Forms.Application]::DoEvents()
        $reg = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GitAlias'
        New-Item -Path $reg -Force | Out-Null
        New-ItemProperty -Path $reg -Name DisplayName     -Value $AppName    -Force | Out-Null
        New-ItemProperty -Path $reg -Name DisplayVersion  -Value $Version    -Force | Out-Null
        New-ItemProperty -Path $reg -Name Publisher       -Value 'GitAlias'  -Force | Out-Null
        New-ItemProperty -Path $reg -Name InstallLocation -Value $InstallDir -Force | Out-Null
        New-ItemProperty -Path $reg -Name DisplayIcon     -Value $ExePath    -Force | Out-Null
        New-ItemProperty -Path $reg -Name UninstallString -Value ("`"$UninstExe`"") -Force | Out-Null
        New-ItemProperty -Path $reg -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $reg -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null

        $script:InstalledExe = $ExePath
        $lblStatus.Text = 'Completato.'; $pb.Value = 100; [System.Windows.Forms.Application]::DoEvents()
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore durante l'installazione:`n$($_.Exception.Message)",$AppName,'OK','Error') | Out-Null
        return $false
    }
}

# ---------- Navigazione wizard ----------
$script:step = 0
$script:InstalledExe = $null
$panels = @($st0,$st1,$st2,$st3)
function Show-Step($n) {
    $script:step = $n
    for ($i=0; $i -lt $panels.Count; $i++) { $panels[$i].Visible = ($i -eq $n) }
    switch ($n) {
        0 { $btnBack.Enabled=$false; $btnNext.Enabled=$true; $btnNext.Text='Avanti';  $btnCancel.Visible=$true }
        1 { $btnBack.Enabled=$true;  $btnNext.Enabled=$true; $btnNext.Text='Installa'; $btnCancel.Visible=$true }
        2 { $btnBack.Enabled=$false; $btnNext.Enabled=$false; $btnCancel.Enabled=$false }
        3 { $btnBack.Visible=$false; $btnNext.Enabled=$true; $btnNext.Text='Fine'; $btnCancel.Visible=$false }
    }
}
$btnNext.Add_Click({
    switch ($script:step) {
        0 { Show-Step 1 }
        1 { Show-Step 2; if (Do-Install) { Show-Step 3 } else { $btnCancel.Enabled=$true; Show-Step 1 } }
        3 { if ($chkLaunch.Checked -and $script:InstalledExe) { Start-Process $script:InstalledExe }; $form.Close() }
    }
})
$btnBack.Add_Click({ if ($script:step -eq 1) { Show-Step 0 } })
$btnCancel.Add_Click({ $form.Close() })
$btnPath.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    if (Test-Path $txtPath.Text) { $fb.SelectedPath = $txtPath.Text }
    if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = (Join-Path $fb.SelectedPath 'GitAlias') }
})

Show-Step 0
[void]$form.ShowDialog()
