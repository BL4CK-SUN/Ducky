# Ducky — BadUSB lab (Digispark, Leonardo)

Projet **lab / machines autorisées** uniquement.

| Clé | Dossier |
|-----|---------|
| Leonardo | [Leonardo/](Leonardo/) |
| Digispark | [Digispark/](Digispark/) |

## Leonardo — payload Wi‑Fi via GitHub

1. Script hébergé : [Leonardo/scripts/wifi-extract.ps1](Leonardo/scripts/wifi-extract.ps1)  
   URL raw (pour `irm`) :
   `https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/Leonardo/scripts/wifi-extract.ps1`

2. **Git** : `git@github.com:BL4CK-SUN/Ducky.git` (push en SSH)  
   **PowerShell `irm`** : uniquement **HTTPS** raw — pas `git@`.

3. Flash clé : `Leonardo/scripts/flash-wifi-pull.ps1`  
   (détection AZERTY/QWERTY sur le PC utilisé pour le flash)

4. Tester l’URL avant branchement :  
   `Leonardo/scripts/test-github-payload.ps1`

> Repo **public** requis pour `irm` sans jeton. Si repo **privé**, il faut un PAT dans l’URL (déconseillé sur une clé flashée) ou un serveur lab local.
)