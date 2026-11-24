# Digispark — Arduino C++ (DigiKeyboard)

Documentation pour la clé **#1** (profil USB usurpé **Trust `VID 145F` / `PID 01C1`**, clavier HID étendu). Probable **Digispark / ATtiny85** avec firmware type BadUSB.

## Ce que fait le dongle

- Pas de lecteur disque : comportement = **clavier (et souris) USB** au branchement.
- Le programme est **flashé dans la puce**, pas copié comme un fichier sur une clé USB.
- **Reconnaissance Windows** : composite HID clavier + souris, nom bus **« 2.4G Speed Mouse »**.

## Langage retenu

| Choix | Pourquoi |
|-------|----------|
| **Arduino C++** (`DigiKeyboard.h`) | Chaîne officielle Digistump, pas de convertisseur DuckyScript, contrôle des délais et du VID/PID |
| DuckyScript | Utile en brouillon ; sur Digispark il faut une compilation tiers → non prioritaire |

Style de code : C++ Arduino minimal (`setup()` / `loop()`), souvent écrit comme du C.

## Prérequis Windows

1. **Arduino IDE 2** — [arduino.cc/software](https://www.arduino.cc/en/software) ou `winget install Arduino.ArduinoIDE`
2. **Cartes Digistump** — URL gestionnaire de cartes (**miroir GitHub**, le site digistump.com est souvent mort) :
   ```
   https://raw.githubusercontent.com/digistump/arduino-boards-index/master/package_digistump_index.json
   ```
   Puis : **Outils → Gestionnaire de cartes** → installer **Digistump AVR Boards**.
3. **Pilotes Micronucleus** (si le téléversement échoue) — wiki / drivers Digistump.

### Réglages IDE

- **Outils → Type de carte** → **Digispark (Default - 16.5mhz)**
- Téléverseur : laisser les options par défaut du core Digistump (Micronucleus).

## Sketch de test

Chemin :

```
Ducky\digispark-test\hello_notepad\hello_notepad.ino
```

Comportement attendu (session **déverrouillée**, bureau visible, **machine de test** de préférence) :

1. Attente ~3 s (énumération USB)
2. **Win+R** → `notepad` → **Entrée**
3. Ligne `Digispark test OK` (layout HID **US** → texte peut différer en **AZERTY**)

## Procédure de téléversement

1. **Débrancher** le Digispark (évite l’ancien firmware au mauvais moment).
2. Arduino : **Vérifier / Compiler** puis **Téléverser**.
3. À l’invite **« Plug in device now… »** (≈ 60 s) → **brancher** le Digispark.
4. Vérifier brièvement dans le Gestionnaire de périphériques : **`VID 16C0` / `PID 0753`** (bootloader Micronucleus).
5. Attendre **« Done uploading »** ; le module redémarre et exécute `setup()` une fois.

### Critère de succès

Le **Bloc-notes** s’ouvre **sans** que tu touches au clavier.

## Dépannage

| Symptôme | Piste |
|----------|--------|
| Pas de `16C0:0753` pendant l’upload | Brancher **pendant** la fenêtre ; autre port USB ; pilote Micronucleus |
| Rien ne s’ouvre après flash OK | Augmenter `DigiKeyboard.delay(3000)` ; session verrouillée ? |
| Texte bizarre dans Notepad | Normal en AZERTY (HID US) ; pour l’instant le test = ouverture de Notepad |
| Toujours `145F:01C1` sans upload | Mode payload actuel ; le flash passe par le bootloader court |

## Après le premier test

- Dupliquer `digispark-test\` pour chaque payload.
- Ajuster délais (lenteur Windows, GPO, antivirus).
- VID/PID : `usbconfig.h` dans la lib **DigisparkKeyboard** (paquet Digistump), si tu changes le déguisement USB.

## Clés suivantes

Inventaire prévu : **3 clés** type Rubber Ducky. Documenter chaque profil USB (VID/PID, stockage ou non, outil de flash) dans `duck.md` au fil des tests.

## Sécurité

Ne tester que sur des machines **autorisées** (VM, labo). Un HID au branchement peut exécuter des commandes au niveau de l’utilisateur connecté.

## Installation locale (automatisable)

| Composant | Emplacement / commande |
|-----------|------------------------|
| Arduino IDE **2.3.11** | `C:\Users\Laurent\AppData\Local\Programs\arduino-ide\Arduino IDE.exe` |
| Arduino CLI **1.6.0** | `C:\Program Files\Arduino CLI\arduino-cli.exe` |
| Index Digistump (IDE) | coller l’URL GitHub ci-dessus dans **Fichier → Préférences** |
| Core via CLI | `arduino-cli core install digistump:avr` → **digistump:avr 1.6.7** installé |
| Compile test | `arduino-cli compile --fqbn digistump:avr:digispark-tiny ...\digispark-test\hello_notepad` |
| Flash (CLI) | Débrancher → `arduino-cli upload --fqbn digistump:avr:digispark-tiny -p unknown ...\hello_notepad` → brancher à l’invite (comme l’IDE) |
| Compile OK | **2856 octets (47 %)** — validé sur cette machine |

Pilotes Windows : [DigistumpArduino / Drivers](https://github.com/digistump/DigistumpArduino) (archive ZIP si besoin).