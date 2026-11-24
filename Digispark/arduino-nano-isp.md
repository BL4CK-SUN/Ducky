# Digispark — programmation avec Arduino Nano (ISP)

Ton **Arduino Nano** = **matériel** programmateur. Le PC envoie les commandes via le port **COM** du Nano avec **avrdude** (fourni par la toolchain Arduino AVR).

## Étape 0 — Ce qu’il te faut

| Item | Détail |
|------|--------|
| Arduino Nano | USB branché sur le PC |
| Fils dupont | 5–6 courts |
| Digispark | **Débranché du PC** pendant l’ISP (alimenté par le Nano) |
| Fichiers | `Ducky\firmware\t85_default.hex` (bootloader), `...\build\hello_notepad.ino.hex` (sketch test) |

Optionnel : condensateur **10 µF** entre **RST** et **GND** du Nano (évite l’auto-reset pendant le flash).

---

## Étape 1 — Préparer le Nano (Arduino as ISP)

1. IDE → carte **Arduino Nano** (bon processeur / bootloader selon ta carte).
2. **Fichier → Exemples → ArduinoISP → ArduinoISP**.
3. **Téléverser** sur le Nano.
4. Noter le port **COM** : `Outils → Port` ou PowerShell :
   ```powershell
   Get-CimInstance Win32_SerialPort | Where-Object { $_.Name -match 'Arduino|CH340|USB' } | Select Name, DeviceID
   ```

Le Nano **ne sert plus** à autre chose tant qu’il joue le rôle d’ISP : ne pas re-téléverser un autre sketch avant d’avoir fini le Digispark.

---

## Étape 2 — Câblage Nano → Digispark (pads ATtiny85)

Repères sur le **Nano** (broches numérotées sur la carte) :

| Nano | Rôle ISP | → Digispark (ATtiny85) |
|------|----------|-------------------------|
| **D13** | SCK | **PB2** (pad SCK / pin 7) |
| **D11** | MOSI | **PB3** (pad MOSI / pin 2) |
| **D12** | MISO | **PB4** (pad MISO / pin 3) |
| **D10** | RESET cible | **PB5** (pad RESET / pin 1) |
| **5V** | Alimentation | **VCC** |
| **GND** | Masse | **GND** |

Les **pads** sont souvent **sous** le petit PCB USB du Digispark (souder ou pinces crocodiles fines).

Schéma ATtiny85 (pin 1 = RESET en haut, sens horaire) :

```text
        ┌─── u ───┐
   RST 1│         │8  VCC  ← 5V Nano
   PB3 2│ ATtiny85│7  PB2  ← D13 SCK
   PB4 3│   t85   │6  PB1
   GND 4│         │5  PB0
        └─────────┘
  MOSI = D11 → pin 2    MISO = D12 → pin 3    GND pin 4
```

**Ne pas** brancher le Digispark en USB PC en même temps que le 5V Nano (une seule alimentation).

---

## Étape 3 — `avrdude` sur Windows

Après installation du core **arduino:avr** (Gestionnaire de cartes), `avrdude` est ici (version peut varier) :

```text
%LOCALAPPDATA%\Arduino15\packages\arduino\tools\avrdude\6.x.x-arduinoN\bin\avrdude.exe
```

Télécharger le core si besoin :

```powershell
& "C:\Program Files\Arduino CLI\arduino-cli.exe" core install arduino:avr
```

Commande type (remplacer `COM5` et les chemins) :

```powershell
$avdude = Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\arduino\tools\avrdude" -Recurse -Filter avrdude.exe | Select-Object -First 1 -ExpandProperty FullName
$conf   = Split-Path $avdude | Join-Path -ChildPath "avrdude.conf"
$port   = "COM5"   # ton Nano

& $avdude -C $conf -p t85 -c stk500v1 -P $port -b 19200 `
  -U flash:w:"E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\firmware\t85_default.hex":i `
  -U lfuse:w:0xE1:m -U hfuse:w:0xDD:m -U efuse:w:0xFE:m
```

`stk500v1` + `19200` = protocole standard du sketch **ArduinoISP**.

---

## Étape 4 — Après bootloader restauré

1. **Déconnecter** les fils ; brancher le **Digispark seul** sur USB 2.
2. Au boot : **6 s** avec **`16D0:0753`** / Micronucleus possible.
3. Flash USB du sketch :
   ```powershell
   & "C:\Program Files\Arduino CLI\arduino-cli.exe" upload --fqbn digistump:avr:digispark-tiny `
     "E:\DiscoE_LAURENT\DEV\WinAdmin\Ducky\digispark-test\hello_notepad"
   ```
   (débrancher → lancer upload → brancher à l’invite.)

---

## Dépannage

| Problème | Piste |
|----------|--------|
| `not in sync` / `programmer not responding` | Fils, mauvais port COM, condensateur 10 µF sur RST Nano, Digispark encore sur USB PC |
| `device initialization failed` | RST vers D10, alimentation 5 V |
| `Yikes! Invalid device signature` | Pas de contact sur MISO/MOSI/SCK, ou mauvaise puce |
| ISP échoue toujours | Fusible **RSTDISBL** sur certaines cartes Digistump d’origine → HV (voir `digispark-recovery.md` option D) |

---

## Liens

- [digispark-recovery.md](./digispark-recovery.md) — vue d’ensemble
- [digispark-arduino-setup.md](./digispark-arduino-setup.md) — usage quotidien après récupération