# Changelog

Tutte le modifiche rilevanti a questo progetto vengono documentate qui.
Il formato segue [Keep a Changelog](https://keepachangelog.com/it/1.1.0/)
e il progetto adotta il [Semantic Versioning](https://semver.org/lang/it/).

## [Unreleased]

## [2.0.0] - 2026-07-15

Prima release pubblica.

### Added
- GUI (PowerShell/WinForms) per cambiare `git config user.name` / `user.email`
  a livello globale o per singolo repository.
- **Preferiti** salvabili per riapplicare velocemente le identità usate spesso.
- Due modalità di distribuzione:
  - **Installer** self-contained (`Setup-GitAlias.exe`) con collegamenti e
    disinstallatore incorporato.
  - **Portable** (`GitAlias-<ver>-portable.zip`) che salva i preferiti accanto
    all'exe (modo chiavetta).
- `build.ps1`: compila i sorgenti e genera i deliverable con un solo comando.

[Unreleased]: https://github.com/rob0797/gitalias/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/rob0797/gitalias/releases/tag/v2.0.0
