# Digispark — récupération & flash (clé #1)

## Contexte

| Élément | Valeur |
|---------|--------|
| Profil USB actuel | `VID 145F` / `PID 01C1` — « 2.4G Speed Mouse » + clavier HID |
| Bootloader attendu | Micronucleus — `16D0:0753` ou parfois `16C0:0753` (5–6 s au boot) |
| Constat | Au branchement : **seulement** `145F:01C1`, **jamais** Micronucleus |
| Conséquence | `arduino-cli upload` / `flash-digispark.ps1` en **timeout** |

Le module est bien un **Digispark (ATtiny85)** côté forme, mais le **re-flash USB standard** est bloqué tant que Micronucleus n’apparaît pas.

## Option A — Dernières tentatives USB only (sans matériel)

1. **Port USB 2.0** direct sur le PC (éviter USB 3 / hubs).
2. Lancer l’upload **avant** de brancher :
   ```powershell
   & "C:\Program Files\Arduino CLI\arduino-cli.exe" upload --fqbn digistump:avr:digispark-tiny `
     "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\digispark-test\hello_notepad"
   ```
   ou :
   ```powershell
   E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\scripts\flash-digispark.ps1
   ```
3. À l’invite → **brancher** une seule fois.
### Pilotes Windows (assistant Digistump)

Résultat normal après `DPinst64.exe` / `Install Digistump Drivers.bat` :

| Pilote | Attendu |
|--------|---------|
| **libusb-win32 Digispark Bootloader** | **Prêt à l’emploi** — **indispensable** pour Micronucleus |
| **libusb-win32 DigiUSB** | **Prêt à l’emploi** — utile variantes USB Digistump |
| **Digistump LLC (usbser)** | **Échec fréquent** sur Win10/11 — **sans impact** pour clavier HID / `hello_notepad` |

4. **Pilotes** Digistump (déjà dans le paquet Arduino) :
   ```
   %LOCALAPPDATA%\Arduino15\packages\digistump\tools\micronucleus\2.0a4\
   ```
   Exécuter en admin si besoin : `Install Digistump Drivers.bat` ou `DPinst64.exe`
5. **Zadig** (si périphérique inconnu quelques secondes) : preset **Micronucleus** `16D0 0753`, driver **libusb-win32**.

**Succès** = apparition brève de `16D0:0753` / `16C0:0753` dans le Gestionnaire de périphériques.

## Option B — Restaurer Micronucleus (recommandé, durable)

**Matériel** : USBasp (~5–10 €) ou Arduino en **ArduinoISP**.

**Broches ATtiny85** (pads sous le Digispark) :

| ATtiny85 | USBasp / ISP |
|----------|----------------|
| PB3 (MOSI) | MOSI |
| PB4 (MISO) | MISO |
| PB2 (SCK) | SCK |
| PB5 (RESET) | RESET |
| VCC | 5 V |
| GND | GND |

**Bootloader** : [micronucleus/firmware/releases](https://github.com/micronucleus/micronucleus/tree/master/firmware/releases) — fichier `t85_default.hex`

Copie locale (si téléchargée) : `Ducky\firmware\t85_default.hex`

**Fuses** (horloge **16,5 MHz** requise pour V-USB — ne pas utiliser le profil 1 MHz Digispark) :

```text
avrdude -c usbasp -p t85 ^
  -U flash:w:t85_default.hex:i ^
  -U lfuse:w:0xE1:m -U hfuse:w:0xDD:m -U efuse:w:0xFE:m
```

Puis re-flash du sketch test via USB (Micronucleus visible).

Références : [derbaltasar/digispark-attiny85-command-line](https://github.com/derbaltasar/digispark-attiny85-command-line), [J-Rios/Digispark_Unbricking](https://github.com/J-Rios/Digispark_Unbricking)

## Option C — Flash ISP du sketch sans Micronucleus

Si le bootloader est mort mais **RESET ISP OK** : programmer directement `hello_notepad.ino.hex` sur la zone application (adresse selon taille du bootloader — souvent après `0x1800` pour t85_default, **vérifier** avec la doc du hex / fuse).

Outil : même **USBasp** + avrdude. À documenter une fois le layout flash confirmé.

## Option D — Haute tension (HV)

Si **ISP échoue** (« device not found ») : fusible **RSTDISBL** possible (Digispark d’origine). Il faut un programmateur **12 V HV** pour réactiver RESET, puis option **B**.

## Option E — Conserver le firmware actuel

Tant que le payload HID existant suffit, aucune action. Changement de script = **B** ou **C**.

## Option F — Remplacement

Nouveau Digispark + environnement déjà prêt sur ce PC (`digispark-arduino-setup.md`).

## Scripts locaux

| Script | Rôle |
|--------|------|
| `scripts\flash-digispark.ps1` | Attend `16D0`/`16C0:0753`, appelle `micronucleus --run` |

### Si `micronucleus.exe` plante au lancement (exit ~3221225595)

Sur certains Windows 11, l’exécutable direct **crash** (DLL). Utiliser de préférence **Arduino IDE → Téléverser** ou `arduino-cli upload` ; sinon essayer `launcher.exe` dans le même dossier que `micronucleus.exe`. Les **pilotes libusb Bootloader** installés restent nécessaires.
| `scripts\probe-usb-boot.ps1` | Journal des VID USB 100 ms pendant N secondes |

## Sketch & binaire

| Fichier | Rôle |
|---------|------|
| `digispark-test\hello_notepad\hello_notepad.ino` | Test Win+R → notepad |
| `digispark-test\hello_notepad\build\hello_notepad.ino.hex` | Binaire compilé (prêt si ISP ou upload OK) |

## Liens

- [digispark-arduino-setup.md](./digispark-arduino-setup.md) — IDE, compilation
- [duck.md](./duck.md) — inventaire des 3 clés