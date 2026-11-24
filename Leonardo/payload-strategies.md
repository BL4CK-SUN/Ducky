# Payloads Leonardo — formats, reflash, SD

## Sortie Wi‑Fi « utile seulement »

`scripts/wifi-extract.ps1` produit par profil :

```
SSID: …
Auth: …  Enc: …
Key:  …   (ou « ouverte / pas de clé »)
```

Source : XML `netsh wlan export` (parsing `[xml]`, indépendant de la langue netsh).

| Mode | Flash quand le script change ? | Frappe clavier |
|------|-------------------------------|----------------|
| **wifi_creds** (B64 embarqué) | Oui (`gen-wifi-b64.ps1` + `flash-wifi-creds.ps1`) | ~1 600 caractères |
| **wifi_pull** (IRM local) | Non (éditer `wifi-extract.ps1` sur le serveur) | ~120 caractères |
| **SD + runner** (à coder) | Non (fichiers sur carte) | 1 firmware fixe |

## Éviter de reflasher

| Approche | Layout AZERTY/QWERTY | Changer le script PowerShell |
|----------|----------------------|------------------------------|
| Re-détecter au **flash** sur la cible | `detect-keyboard-layout.ps1` | B64 : regen + flash |
| **wifi_pull** + HTTP lab | Même règle au flash du *lanceur* court | Modifier `wifi-extract.ps1` seulement |
| **Carte SD** (futur `payload_runner`) | Fichier `config.ini` sur SD | Remplacer `.ps1` / `.duck` sur SD |
| 2 hex en EEPROM / jumper | 1 flash, jumper QWERTY/AZERTY | — |

**Sans SD ni IRM :** un seul binaire ne devine pas le layout Windows ; il faut soit reflasher depuis la cible, soit matériel (jumper), soit contenu sur SD.

## wifi_pull (lab)

### GitHub (recommandé)

- Remote : `git@github.com:BL4CK-SUN/Ducky.git` (push SSH)
- Exécution : `https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/Leonardo/scripts/wifi-extract.ps1`
- Config firmware : `leonardo-test/wifi_pull/github_config.h`
- `test-github-payload.ps1` avant de brancher la clé
- Repo **public** pour `irm` sans jeton

### HTTP local (secours air-gapped / privé)

1. `serve-wifi-payload.ps1` (admin : URLACL `http://+:8765/` si besoin)
2. Changer `PAYLOAD_URL` dans `github_config.h` → IP locale
3. `flash-wifi-pull.ps1` sur le PC dont le clavier servira de référence

## Sécurité

Les exports contiennent des **mots de passe en clair**. Ne pas versionner `wifi-leonardo.txt` ; rotation si fuite.