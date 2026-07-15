# Contribuire a GitAlias

Grazie per l'interesse! Contributi, segnalazioni e idee sono benvenuti.

## Segnalazioni e proposte

- **Bug** o **richieste di funzionalità** → apri una [issue](../../issues) usando
  il template giusto.
- **Vulnerabilità di sicurezza** → NON aprire una issue pubblica, segui la
  [Security Policy](SECURITY.md).

## Ambiente di sviluppo

Serve **Windows** con `git` nel PATH, PowerShell, e per compilare gli `.exe`:

```powershell
Install-Module ps2exe -Scope CurrentUser   # una volta sola
```

e `magick` (ImageMagick) nel PATH per generare il logo.

## Dove si mettono le mani

- Tutto il codice sta in **`src/`** — è l'unica cartella che si modifica.
  - `src/gitalias.ps1` → interfaccia + logica dell'app.
  - `src/installer/install.template.ps1` → wizard di installazione.
  - `src/installer/uninstall.ps1` → disinstallatore.
- **`dist/` non si tocca e non si committa**: è output generato, escluso via
  `.gitignore`.

## Ciclo di lavoro

1. Fai un fork e crea un branch descrittivo (`fix-...`, `feat-...`).
2. Modifica i sorgenti in `src/`.
3. Ricompila e prova:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1
   ```
   oppure esegui il sorgente senza compilare:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\src\gitalias.ps1
   ```
4. Verifica che parta e che le funzioni toccate funzionino.
5. Apri una Pull Request compilando il template.

## Stile

- Mantieni lo stile del codice esistente (PowerShell/WinForms).
- Commit chiari e atomici, in italiano o inglese.
- Niente dati personali nei sorgenti o nei commit.

Rispettando queste poche regole, la PR sarà facile da revisionare. Grazie!
