# Security Policy

## Versioni supportate

Riceve correzioni di sicurezza solo l'ultima release pubblicata.

| Versione | Supportata |
|----------|:----------:|
| 2.x      | ✅         |
| < 2.0    | ❌         |

## Segnalare una vulnerabilità

**Non aprire una issue pubblica per problemi di sicurezza.**

Usa la segnalazione privata di GitHub:

1. Vai sulla tab **[Security](../../security)** del repository.
2. Clicca **Report a vulnerability**.
3. Descrivi il problema, come riprodurlo e l'impatto.

Riceverai un riscontro appena possibile. Una volta confermata e corretta la
vulnerabilità, verrà pubblicata una nuova release e un avviso.

## Ambito

GitAlias è un'applicazione **desktop locale per Windows**: non espone servizi di
rete, non raccoglie dati, non comunica con server esterni. Modifica solo la tua
configurazione `git` locale e salva i preferiti sul tuo PC.

Nota nota: i binari `.exe` distribuiti **non sono firmati** con un certificato
code-signing — Windows SmartScreen può quindi avvisare al primo avvio. Se ti serve
la massima fiducia, compila tu stesso i sorgenti con `build.ps1` (vedi README).
