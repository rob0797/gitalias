# GitAlias

**Cambia la tua identità git — `user.name` e `user.email` — con un click.**
Niente più `git config --global user.email "..."` copincollato sbagliato tra un
repo di lavoro e uno personale. Scegli un preferito, premi *Applica*, fatto.

![Platform](https://img.shields.io/badge/platform-Windows-0078D6)
![PowerShell](https://img.shields.io/badge/PowerShell-WinForms-5391FE)
![Admin](https://img.shields.io/badge/admin-non%20richiesto-brightgreen)
![Deps](https://img.shields.io/badge/runtime%20deps-solo%20git-lightgrey)

---

## Il problema

Lavori con più identità git sulla stessa macchina: quella aziendale, quella
personale, magari quella di un cliente. Ogni volta è la stessa storia:

```powershell
git config user.name "Nome Giusto"
git config user.email "email@giusta.tld"    # ...era globale o del repo? boh
```

Un errore e ti ritrovi i commit firmati con l'account sbagliato — su un repo
pubblico, per sempre nella cronologia.

**GitAlias** è una GUI che rende l'operazione un click: salvi le tue identità
come **preferiti**, le applichi a livello **globale** o **sul singolo repository**,
e vedi subito qual è attiva. Tutto **per l'utente corrente**, **senza diritti di
amministratore**.

---

## ⬇️ Download e uso

I programmi pronti (`.exe` e zip) **non stanno nel codice sorgente**: si scaricano
dalla pagina **[Releases](../../releases)**.

| | Cosa scarichi | Come si usa | Dove salva i preferiti |
|---|---|---|---|
| **Installabile** | **`Setup-GitAlias.exe`** — un solo file | Doppio click → wizard (Benvenuto → Opzioni → Avanzamento → Fine). Si installa da solo, crea i collegamenti su Desktop e menu Start, e include il proprio disinstallatore. | `%APPDATA%\GitAlias\favorites.json` |
| **Portable** | **`GitAlias-<versione>-portable.zip`** | Estrai dove vuoi (anche una chiavetta) → apri `GitAlias.exe`. Nessuna installazione. | Accanto all'exe (viaggiano con la chiavetta) |

> L'installer è **self-contained**: app e disinstallatore sono già dentro
> `Setup-GitAlias.exe`. Non serve scaricare altro.

> Al primo avvio, non essendo firmato, SmartScreen può mostrare *"Windows ha
> protetto il PC"* → **Ulteriori informazioni → Esegui comunque**.

Non vuoi scaricare un `.exe`? Puoi eseguire direttamente il sorgente:

```powershell
powershell -ExecutionPolicy Bypass -File .\src\gitalias.ps1
```

---

## 📁 Cosa c'è in questo repo

Qui vive solo il **sorgente** (il codice) e la "ricetta" per compilarlo. I file
pronti da distribuire vengono **generati** da `build.ps1` e finiscono in `dist\`,
che è volutamente **fuori dal repo** (`.gitignore`) perché rigenerabile.

```
gitalias/
├─ README.md            ← questo file
├─ LICENSE              ← MIT
├─ build.ps1            ← "tasto genera": compila i sorgenti e crea i deliverable
├─ .gitignore
└─ src/                 ← SORGENTI (si modificano qui)
   ├─ gitalias.ps1          il cuore dell'app: interfaccia + logica
   ├─ app-icon.ico          icona, usata dall'exe e per il logo header
   ├─ favorites.example.json esempio del formato preferiti (dati finti)
   └─ installer/
      ├─ install.template.ps1  modello del wizard di installazione
      └─ uninstall.ps1         sorgente del disinstallatore
```

---

## 🔧 Compilare da sorgente (`build.ps1`)

Serve il modulo [ps2exe](https://github.com/MScholtes/PS2EXE) (una volta sola) e
`magick` (ImageMagick) nel PATH per generare il logo:

```powershell
Install-Module ps2exe -Scope CurrentUser
```

Poi un solo comando:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
# versione custom:
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 2.1.0
```

`build.ps1` crea in locale la cartella `dist\` (non versionata) con:

- `dist\portable\GitAlias-<ver>-portable.zip` — la versione portable
- `dist\installer\Setup-GitAlias.exe` — l'installer self-contained
- `dist\_work\` — file intermedi, ignorabili

Sono esattamente i file che poi vengono allegati a una **Release**.

- **Per modificare l'app** → cambia `src\gitalias.ps1`, poi lancia `build.ps1`.
- **Per l'installer** → cambia `src\installer\install.template.ps1`, poi `build.ps1`.

---

## ❌ Disinstallazione

Impostazioni di Windows → App → **GitAlias** → Disinstalla (oppure `Uninstall.exe`
nella cartella d'installazione). Rimuove collegamenti, voce di registro e la
cartella del programma. **I preferiti in `%APPDATA%\GitAlias` NON vengono cancellati.**

---

## ℹ️ Note

- Solo **Windows** (usa WinForms + `git` nel PATH).
- Gli `.exe` non sono firmati con certificato (vedi nota SmartScreen sopra).
- Nessun dato personale nel sorgente: i preferiti reali vivono solo sul tuo PC.

---

## Licenza

Rilasciato con licenza **MIT** — vedi il file [`LICENSE`](LICENSE).
