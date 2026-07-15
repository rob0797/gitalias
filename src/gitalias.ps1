# ============================================================
#  GitAlias  -  GUI WinForms
#  Cambia user.name / user.email (globale o locale) con 1 click.
#  Preferiti in %APPDATA%\GitAlias (o accanto all'exe se esiste
#  portable.flag). Nessun dato personale nel sorgente.
#  Il logo ($LogoB64) viene iniettato al build da build.ps1.
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# SendMessage per il placeholder nativo (EM_SETCUEBANNER). Facoltativo.
$script:CueOk = $false
try {
    Add-Type -Namespace Native -Name Edit -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet=System.Runtime.InteropServices.CharSet.Unicode)]
public static extern System.IntPtr SendMessage(System.IntPtr hWnd, int msg, System.IntPtr wParam, string lParam);
'@
    $script:CueOk = $true
} catch { }

# ---------- Posizione dati (modello VS Code) ----------
function Resolve-BaseDir {
    if ($PSCommandPath) { return (Split-Path -Parent $PSCommandPath) }
    try { return (Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)) } catch { }
    return (Get-Location).Path
}
$ExeDir = Resolve-BaseDir
if (Test-Path (Join-Path $ExeDir 'portable.flag')) { $DataDir = $ExeDir }
else { $DataDir = Join-Path $env:APPDATA 'GitAlias' }
if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir -Force | Out-Null }
$FavFile = Join-Path $DataDir 'favorites.json'

# ---------- Preferiti di default (esempio; nessun dato personale) ----------
$DefaultFavorites = @(
    [pscustomobject]@{ label = 'Personale'; name = 'Mario Rossi'; email = 'you@example.com' }
    [pscustomobject]@{ label = 'Lavoro';    name = 'Mario Rossi'; email = 'you@company.com' }
)
function Load-Favorites {
    if (Test-Path $FavFile) {
        try { $data = Get-Content $FavFile -Raw -Encoding UTF8 | ConvertFrom-Json; if ($data) { return @($data) } } catch { }
    }
    Save-Favorites $DefaultFavorites
    return $DefaultFavorites
}
function Save-Favorites($favs) { $favs | ConvertTo-Json -Depth 5 | Out-File -FilePath $FavFile -Encoding UTF8 }

# ---------- Git helpers ----------
function Get-GitScopeArgs {
    if ($script:ScopeLocal -and $script:RepoPath) { return @('-C', $script:RepoPath, 'config', '--local') }
    else { return @('config', '--global') }
}
function Get-CurrentIdentity {
    $a = Get-GitScopeArgs
    $name  = (& git @a 'user.name')  2>$null
    $email = (& git @a 'user.email') 2>$null
    return [pscustomobject]@{
        Name  = if ($name)  { ($name  | Select-Object -First 1).Trim() } else { '' }
        Email = if ($email) { ($email | Select-Object -First 1).Trim() } else { '' }
    }
}
function Set-Identity($name, $email) {
    if (-not $script:GitOk) { [System.Windows.Forms.MessageBox]::Show("git non trovato nel PATH. Installa Git e riprova.",'git assente','OK','Error') | Out-Null; return $false }
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($email)) {
        [System.Windows.Forms.MessageBox]::Show('Nome ed email non possono essere vuoti.','Attenzione','OK','Warning') | Out-Null; return $false
    }
    if ($script:ScopeLocal) {
        if (-not $script:RepoPath -or -not (Test-Path (Join-Path $script:RepoPath '.git'))) {
            [System.Windows.Forms.MessageBox]::Show("La cartella selezionata non e' un repo git:`n$script:RepoPath",'Repo non valido','OK','Warning') | Out-Null; return $false
        }
    }
    $a = Get-GitScopeArgs
    & git @a 'user.name'  $name  2>$null | Out-Null; $ok1 = ($LASTEXITCODE -eq 0)
    & git @a 'user.email' $email 2>$null | Out-Null; $ok2 = ($LASTEXITCODE -eq 0)
    if (-not ($ok1 -and $ok2)) { [System.Windows.Forms.MessageBox]::Show("Il comando git e' fallito (exit code non zero).",'Errore git','OK','Error') | Out-Null; return $false }
    return $true
}

# ---------- Stato ----------
$script:ScopeLocal = $false
$script:RepoPath   = ''
$script:GitOk      = [bool](Get-Command git -ErrorAction SilentlyContinue)
$favorites = Load-Favorites

# ============================================================
#  Palette + kit UI arrotondato
# ============================================================
function C($r,$g,$b){ [System.Drawing.Color]::FromArgb($r,$g,$b) }
function Pt($x,$y){ New-Object System.Drawing.Point([int]$x,[int]$y) }
function Sz($w,$h){ New-Object System.Drawing.Size([int]$w,[int]$h) }
function Fnt($n,$s,$st='Regular'){ New-Object System.Drawing.Font($n,$s,[System.Drawing.FontStyle]::$st) }

$Ink=C 30 30 32; $Muted=C 122 122 130; $Charco=C 34 34 38
$Gold=C 207 159 58; $GoldHi=C 222 177 82; $Card=C 248 248 249; $Line=C 223 223 228
$White=[System.Drawing.Color]::White
$FlagCenter = [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter
$FlagLeft   = [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter

function RoundPath([int]$w,[int]$h,[int]$r){
    $d=$r*2
    $gp=New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddArc(0,0,$d,$d,180,90); $gp.AddArc($w-$d-1,0,$d,$d,270,90)
    $gp.AddArc($w-$d-1,$h-$d-1,$d,$d,0,90); $gp.AddArc(0,$h-$d-1,$d,$d,90,90); $gp.CloseAllFigures()
    return $gp
}
function Round-Button($b,$fill,$hover,$fg,$border){
    $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=0; $b.BackColor=$fill; $b.ForeColor=$fg; $b.Cursor='Hand'
    $b.Tag=@{ fill=$fill; hover=$hover; fg=$fg; border=$border; over=$false; r=9 }
    $b.Add_MouseEnter({ $this.Tag.over=$true; $this.Invalidate() })
    $b.Add_MouseLeave({ $this.Tag.over=$false; $this.Invalidate() })
    $b.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor)
        $gp=RoundPath $s.Width $s.Height $s.Tag.r
        $col= if($s.Tag.over){ $s.Tag.hover } else { $s.Tag.fill }
        $sb=New-Object System.Drawing.SolidBrush($col); $g.FillPath($sb,$gp); $sb.Dispose()
        if($s.Tag.border){ $pen=New-Object System.Drawing.Pen($s.Tag.border,1); $g.DrawPath($pen,$gp); $pen.Dispose() }
        [System.Windows.Forms.TextRenderer]::DrawText($g,$s.Text,$s.Font,$s.ClientRectangle,$s.Tag.fg,$script:FlagCenter)
        $gp.Dispose()
    })
}
function Style-Primary($b){ $b.Font=Fnt 'Segoe UI Semibold' 9 'Bold'; Round-Button $b $Gold $GoldHi $Ink $null }
function Style-Secondary($b){ Round-Button $b $White (C 245 245 246) $Ink $Line }

function Round-Panel($p,$fill,$border,[int]$r){
    $p.BackColor=$fill; $p.Tag=@{ fill=$fill; border=$border; r=$r }
    $p.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor)
        $gp=RoundPath $s.Width $s.Height $s.Tag.r
        $sb=New-Object System.Drawing.SolidBrush($s.Tag.fill); $g.FillPath($sb,$gp); $sb.Dispose()
        if($s.Tag.border){ $pen=New-Object System.Drawing.Pen($s.Tag.border,1); $g.DrawPath($pen,$gp); $pen.Dispose() }
        $gp.Dispose()
    })
}
# Radio custom: cerchio grigio / oro quando selezionato
function Round-Radio($rb){
    $rb.AutoSize=$false; $rb.Size=Sz 410 24; $rb.BackColor=$Card; $rb.ForeColor=$Ink; $rb.Cursor='Hand'
    $rb.Add_CheckedChanged({ $this.Invalidate() })
    $rb.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor)
        $cy=[int](($s.Height-16)/2)
        $ring= if($s.Checked){ $Gold } else { C 172 172 180 }
        $pen=New-Object System.Drawing.Pen($ring,2); $g.DrawEllipse($pen,1,$cy,15,15); $pen.Dispose()
        if($s.Checked){ $br=New-Object System.Drawing.SolidBrush($Gold); $g.FillEllipse($br,5,($cy+4),8,8); $br.Dispose() }
        $rect=New-Object System.Drawing.Rectangle(26,0,($s.Width-26),$s.Height)
        [System.Windows.Forms.TextRenderer]::DrawText($g,$s.Text,$s.Font,$rect,$Ink,$script:FlagLeft)
    })
}
function New-Chip($parent,$x,$y){
    $c=New-Object System.Windows.Forms.Label
    $c.Location=Pt $x $y; $c.Size=Sz 72 18; $c.Text='GLOBALE'
    $c.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor)
        $gp=RoundPath $s.Width $s.Height 8
        $bg=New-Object System.Drawing.SolidBrush((C 246 238 218)); $g.FillPath($bg,$gp); $bg.Dispose()
        $pen=New-Object System.Drawing.Pen((C 216 192 136),1); $g.DrawPath($pen,$gp); $pen.Dispose()
        [System.Windows.Forms.TextRenderer]::DrawText($g,$s.Text,(Fnt 'Segoe UI Semibold' 7 'Bold'),$s.ClientRectangle,(C 146 110 38),$script:FlagCenter)
        $gp.Dispose()
    })
    $parent.Controls.Add($c); return $c
}
function New-Title($text,$x,$y){
    $l=New-Object System.Windows.Forms.Label
    $l.Text=$text.ToUpper(); $l.Font=Fnt 'Segoe UI Semibold' 7.5 'Bold'; $l.ForeColor=$Muted
    $l.Location=Pt $x $y; $l.AutoSize=$true; $form.Controls.Add($l); return $l
}
function New-Card($x,$y,$w,$h){
    $p=New-Object System.Windows.Forms.Panel; $p.Location=Pt $x $y; $p.Size=Sz $w $h
    Round-Panel $p $Card $Line 10; $form.Controls.Add($p); return $p
}
function New-RoundInput($parent,$x,$y,$w,$h,$placeholder='',[bool]$mono=$false){
    $pan=New-Object System.Windows.Forms.Panel; $pan.Location=Pt $x $y; $pan.Size=Sz $w $h; $pan.BackColor=$White
    $pan.Tag=@{ r=7 }
    $pan.Add_Paint({ param($s,$e)
        $g=$e.Graphics; $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear($s.Parent.BackColor)
        $gp=RoundPath $s.Width $s.Height $s.Tag.r
        $sb=New-Object System.Drawing.SolidBrush($script:White); $g.FillPath($sb,$gp); $sb.Dispose()
        $tbx=$s.Controls[0]
        $bcol= if($tbx.Focused){ $script:Gold } else { $script:Line }
        $bw = if($tbx.Focused){ 2 } else { 1 }
        $pen=New-Object System.Drawing.Pen($bcol,$bw); $g.DrawPath($pen,$gp); $pen.Dispose()
        $gp.Dispose()
    })
    $parent.Controls.Add($pan)
    $tb=New-Object System.Windows.Forms.TextBox; $tb.BorderStyle='None'; $tb.BackColor=$White; $tb.ForeColor=$Ink
    if($mono){ $tb.Font=Fnt 'Consolas' 9.5 } else { $tb.Font=Fnt 'Segoe UI' 9.5 }
    $tb.Location=Pt 10 ([int](($h-16)/2)); $tb.Size=Sz ($w-20) 18
    $pan.Controls.Add($tb)
    $tb.Add_GotFocus({ $this.Parent.Invalidate() })
    $tb.Add_LostFocus({ $this.Parent.Invalidate() })
    if($placeholder -and $script:CueOk){ try { [void][Native.Edit]::SendMessage($tb.Handle,0x1501,[System.IntPtr]1,$placeholder) } catch { } }
    $tb | Add-Member -NotePropertyName Wrap -NotePropertyValue $pan -Force
    return $tb
}
function New-RoundList($parent,$x,$y,$w,$h){
    $pan=New-Object System.Windows.Forms.Panel; $pan.Location=Pt $x $y; $pan.Size=Sz $w $h
    Round-Panel $pan $White $Line 8; $parent.Controls.Add($pan)
    $lb=New-Object System.Windows.Forms.ListBox; $lb.BorderStyle='None'; $lb.Location=Pt 9 9; $lb.Size=Sz ($w-18) ($h-18)
    $lb.Font=Fnt 'Segoe UI' 9; $lb.IntegralHeight=$false
    $pan.Controls.Add($lb); return $lb
}

# ============================================================
#  Finestra + header
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = 'GitAlias'; $form.ClientSize = Sz 468 652
$form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false; $form.Font = Fnt 'Segoe UI' 9; $form.BackColor = $White
$tip = New-Object System.Windows.Forms.ToolTip

$hdr = New-Object System.Windows.Forms.Panel
$hdr.Location = Pt 0 0; $hdr.Size = Sz 468 66; $hdr.BackColor = $Charco
$form.Controls.Add($hdr)

$LogoB64 = '__LOGO__'
$pbLogo = New-Object System.Windows.Forms.PictureBox
$pbLogo.Location = Pt 14 11; $pbLogo.Size = Sz 44 44; $pbLogo.SizeMode = 'Zoom'; $pbLogo.BackColor = $Charco
try {
    $bytes=[System.Convert]::FromBase64String($LogoB64); $ms=New-Object System.IO.MemoryStream(,$bytes)
    $pbLogo.Image=[System.Drawing.Image]::FromStream($ms)
    $form.Icon=[System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
} catch { }
$hdr.Controls.Add($pbLogo)

$lblBrand = New-Object System.Windows.Forms.Label
$lblBrand.Text='GitAlias'; $lblBrand.Font=Fnt 'Segoe UI Semibold' 15 'Bold'; $lblBrand.ForeColor=$Gold; $lblBrand.BackColor=$Charco
$lblBrand.Location=Pt 68 10; $lblBrand.AutoSize=$true; $hdr.Controls.Add($lblBrand)

$lblBrandSub = New-Object System.Windows.Forms.Label
$lblBrandSub.Text='Cambia identita git in un click'; $lblBrandSub.ForeColor=(C 170 170 176); $lblBrandSub.BackColor=$Charco
$lblBrandSub.Location=Pt 70 40; $lblBrandSub.AutoSize=$true; $hdr.Controls.Add($lblBrandSub)

$goldLine = New-Object System.Windows.Forms.Panel
$goldLine.Location=Pt 0 66; $goldLine.Size=Sz 468 2; $goldLine.BackColor=$Gold; $form.Controls.Add($goldLine)

# ---------- Ambito ----------
New-Title 'Ambito' 16 80 | Out-Null
$cardScope = New-Card 16 98 436 108
$rbGlobal = New-Object System.Windows.Forms.RadioButton
$rbGlobal.Text='Globale  -  tutti i repository (--global)'; $rbGlobal.Location=Pt 14 12; $rbGlobal.Checked=$true; Round-Radio $rbGlobal; $cardScope.Controls.Add($rbGlobal)
$rbLocal = New-Object System.Windows.Forms.RadioButton
$rbLocal.Text='Locale  -  solo questo repository (--local)'; $rbLocal.Location=Pt 14 38; Round-Radio $rbLocal; $cardScope.Controls.Add($rbLocal)
$txtRepo = New-RoundInput $cardScope 14 70 322 28 'C:\percorso\del\repository'
$txtRepo.Enabled=$false
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text='Sfoglia'; $btnBrowse.Location=Pt 344 70; $btnBrowse.Size=Sz 78 28; $btnBrowse.Enabled=$false
Style-Secondary $btnBrowse; $cardScope.Controls.Add($btnBrowse)

# ---------- Identita attuale ----------
New-Title 'Identita attuale' 16 220 | Out-Null
$chipScope = New-Chip $form 150 218
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text=[char]0x21BB; $btnRefresh.Location=Pt 426 216; $btnRefresh.Size=Sz 26 22; $btnRefresh.Font=Fnt 'Segoe UI' 12
Style-Secondary $btnRefresh; $form.Controls.Add($btnRefresh); $tip.SetToolTip($btnRefresh,'Aggiorna identita')
$cardCur = New-Card 16 240 436 46
$lblCurrent = New-Object System.Windows.Forms.Label
$lblCurrent.Location=Pt 14 0; $lblCurrent.Size=Sz 408 46; $lblCurrent.TextAlign='MiddleLeft'
$lblCurrent.Font=Fnt 'Consolas' 10 'Bold'; $lblCurrent.BackColor=$Card; $cardCur.Controls.Add($lblCurrent)

# ---------- Preferiti ----------
New-Title 'Preferiti  (doppio click = applica)' 16 300 | Out-Null
$lstFav = New-RoundList $form 16 320 436 112
$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text='Applica'; $btnApply.Location=Pt 16 440; $btnApply.Size=Sz 132 34; Style-Primary $btnApply; $form.Controls.Add($btnApply)
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text='Aggiungi'; $btnAdd.Location=Pt 156 442; $btnAdd.Size=Sz 94 30; Style-Secondary $btnAdd; $form.Controls.Add($btnAdd)
$btnEdit = New-Object System.Windows.Forms.Button
$btnEdit.Text='Modifica'; $btnEdit.Location=Pt 254 442; $btnEdit.Size=Sz 94 30; Style-Secondary $btnEdit; $form.Controls.Add($btnEdit)
$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text='Rimuovi'; $btnRemove.Location=Pt 352 442; $btnRemove.Size=Sz 100 30; Style-Secondary $btnRemove; $form.Controls.Add($btnRemove)

# ---------- Imposta manualmente ----------
New-Title 'Imposta manualmente' 16 492 | Out-Null
$cardManual = New-Card 16 512 436 124
$lblName = New-Object System.Windows.Forms.Label
$lblName.Text='user.name'; $lblName.Location=Pt 16 18; $lblName.AutoSize=$true; $lblName.ForeColor=$Muted; $lblName.BackColor=$Card; $cardManual.Controls.Add($lblName)
$txtName = New-RoundInput $cardManual 92 13 330 28 'Mario Rossi'
$lblEmail = New-Object System.Windows.Forms.Label
$lblEmail.Text='user.email'; $lblEmail.Location=Pt 16 52; $lblEmail.AutoSize=$true; $lblEmail.ForeColor=$Muted; $lblEmail.BackColor=$Card; $cardManual.Controls.Add($lblEmail)
$txtEmail = New-RoundInput $cardManual 92 47 330 28 'tu@azienda.com'
$btnApplyCustom = New-Object System.Windows.Forms.Button
$btnApplyCustom.Text='Applica'; $btnApplyCustom.Location=Pt 14 84; $btnApplyCustom.Size=Sz 200 30; Style-Secondary $btnApplyCustom; $cardManual.Controls.Add($btnApplyCustom)
$btnSaveCustom = New-Object System.Windows.Forms.Button
$btnSaveCustom.Text='Salva come preferito'; $btnSaveCustom.Location=Pt 222 84; $btnSaveCustom.Size=Sz 200 30; Style-Secondary $btnSaveCustom; $cardManual.Controls.Add($btnSaveCustom)

# ============================================================
#  Logica
# ============================================================
function Refresh-FavList {
    $lstFav.Items.Clear()
    foreach ($f in $script:favorites) {
        $disp = if ($f.label -and $f.label -ne $f.name) { "{0}  -  {1} <{2}>" -f $f.label, $f.name, $f.email }
                else { "{0} <{1}>" -f $f.name, $f.email }
        $lstFav.Items.Add($disp) | Out-Null
    }
}
function Refresh-Current {
    if ($script:ScopeLocal -and (-not $script:RepoPath -or -not (Test-Path (Join-Path $script:RepoPath '.git')))) {
        $lblCurrent.Text = '  (seleziona un repo git valido)'; $lblCurrent.ForeColor=[System.Drawing.Color]::DarkOrange; return
    }
    $id = Get-CurrentIdentity
    if ($id.Name -or $id.Email) { $lblCurrent.Text = ("  {0}   <{1}>" -f $id.Name, $id.Email); $lblCurrent.ForeColor=$Ink }
    else { $lblCurrent.Text = '  (nessuna identita impostata)'; $lblCurrent.ForeColor=[System.Drawing.Color]::DarkOrange }
}
function Apply-Selected {
    $i = $lstFav.SelectedIndex
    if ($i -lt 0) { [System.Windows.Forms.MessageBox]::Show('Seleziona un preferito.','Info','OK','Information') | Out-Null; return }
    $f = $script:favorites[$i]
    if (Set-Identity $f.name $f.email) {
        Refresh-Current
        [System.Windows.Forms.MessageBox]::Show(("Identita impostata:`n{0} <{1}>" -f $f.name, $f.email),'Fatto','OK','Information') | Out-Null
    }
}
function Prompt-Favorite($title, $init) {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text=$title; $dlg.ClientSize=Sz 372 200; $dlg.StartPosition='CenterParent'
    $dlg.FormBorderStyle='FixedDialog'; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false; $dlg.Font=Fnt 'Segoe UI' 9; $dlg.BackColor=$White
    $l1=New-Object System.Windows.Forms.Label; $l1.Text='Etichetta'; $l1.Location=Pt 18 20; $l1.AutoSize=$true; $l1.ForeColor=$Muted
    $l2=New-Object System.Windows.Forms.Label; $l2.Text='user.name'; $l2.Location=Pt 18 56; $l2.AutoSize=$true; $l2.ForeColor=$Muted
    $l3=New-Object System.Windows.Forms.Label; $l3.Text='user.email'; $l3.Location=Pt 18 92; $l3.AutoSize=$true; $l3.ForeColor=$Muted
    $dlg.Controls.AddRange(@($l1,$l2,$l3))
    $t1=New-RoundInput $dlg 104 16 250 28 'es. Lavoro'; $t1.Text=$init.label
    $t2=New-RoundInput $dlg 104 52 250 28 'Mario Rossi'; $t2.Text=$init.name
    $t3=New-RoundInput $dlg 104 88 250 28 'tu@azienda.com'; $t3.Text=$init.email
    $ok=New-Object System.Windows.Forms.Button; $ok.Text='OK'; $ok.Location=Pt 104 134; $ok.Size=Sz 118 32; Style-Primary $ok; $ok.DialogResult=[System.Windows.Forms.DialogResult]::OK
    $cx=New-Object System.Windows.Forms.Button; $cx.Text='Annulla'; $cx.Location=Pt 236 134; $cx.Size=Sz 118 32; Style-Secondary $cx; $cx.DialogResult=[System.Windows.Forms.DialogResult]::Cancel
    $dlg.Controls.AddRange(@($ok,$cx)); $dlg.AcceptButton=$ok; $dlg.CancelButton=$cx
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $lbl = if ([string]::IsNullOrWhiteSpace($t1.Text)) { $t2.Text } else { $t1.Text }
        return [pscustomobject]@{ label=$lbl; name=$t2.Text.Trim(); email=$t3.Text.Trim() }
    }
    return $null
}

# ---- Event handlers ----
$rbLocal.Add_CheckedChanged({
    $script:ScopeLocal=$rbLocal.Checked
    $txtRepo.Enabled=$rbLocal.Checked; $btnBrowse.Enabled=$rbLocal.Checked
    $chipScope.Text = if($rbLocal.Checked){ 'LOCALE' } else { 'GLOBALE' }; $chipScope.Invalidate()
    Refresh-Current
})
$txtRepo.Add_TextChanged({ $script:RepoPath=$txtRepo.Text.Trim(); Refresh-Current })
$btnBrowse.Add_Click({
    $fb=New-Object System.Windows.Forms.FolderBrowserDialog
    if ($script:RepoPath -and (Test-Path $script:RepoPath)) { $fb.SelectedPath=$script:RepoPath }
    if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtRepo.Text=$fb.SelectedPath }
})
$btnApply.Add_Click({ Apply-Selected })
$lstFav.Add_DoubleClick({ Apply-Selected })
$btnAdd.Add_Click({
    $r=Prompt-Favorite 'Nuovo preferito' ([pscustomobject]@{label='';name='';email=''})
    if ($r) { $script:favorites=@($script:favorites)+$r; Save-Favorites $script:favorites; Refresh-FavList }
})
$btnEdit.Add_Click({
    $i=$lstFav.SelectedIndex; if ($i -lt 0) { return }
    $r=Prompt-Favorite 'Modifica preferito' $script:favorites[$i]
    if ($r) { $script:favorites[$i]=$r; Save-Favorites $script:favorites; Refresh-FavList; $lstFav.SelectedIndex=$i }
})
$btnRemove.Add_Click({
    $i=$lstFav.SelectedIndex; if ($i -lt 0) { return }
    $f=$script:favorites[$i]
    if ([System.Windows.Forms.MessageBox]::Show(("Rimuovere '{0}'?" -f $f.label),'Conferma','YesNo','Question') -eq 'Yes') {
        $script:favorites=@($script:favorites | Where-Object { $_ -ne $f }); Save-Favorites $script:favorites; Refresh-FavList
    }
})
$btnRefresh.Add_Click({ Refresh-Current })
$btnApplyCustom.Add_Click({
    if (Set-Identity $txtName.Text.Trim() $txtEmail.Text.Trim()) {
        Refresh-Current; [System.Windows.Forms.MessageBox]::Show('Identita personalizzata applicata.','Fatto','OK','Information') | Out-Null
    }
})
$btnSaveCustom.Add_Click({
    $r=Prompt-Favorite 'Salva come preferito' ([pscustomobject]@{ label=''; name=$txtName.Text.Trim(); email=$txtEmail.Text.Trim() })
    if ($r) { $script:favorites=@($script:favorites)+$r; Save-Favorites $script:favorites; Refresh-FavList }
})

# ---- Init ----
Refresh-FavList
Refresh-Current
if (-not $script:GitOk) {
    [System.Windows.Forms.MessageBox]::Show("git non e' stato trovato nel PATH.`nL'app funziona ma non potra' leggere/scrivere l'identita finche' Git non e' installato.",'git assente','OK','Warning') | Out-Null
}
[void]$form.ShowDialog()
