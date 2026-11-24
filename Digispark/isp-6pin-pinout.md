# Connecteur ISP AVR — 6 broches (2×3)

Référence standard **Atmel / Microchip** (USBasp, Arduino ICSP, etc.). Vue sur le **connecteur femelle** câble, repère **pin 1** (triangle / fil rouge sur le ruban).

## Schéma (broche 1 en haut à gauche)

```text
  ┌─────────────────┐
  │ 1 MISO  2 VCC   │
  │ 3 SCK   4 MOSI  │
  │ 5 RST   6 GND   │
  └─────────────────┘
```

| Pin | Signal | Rôle |
|-----|--------|------|
| 1 | MISO | Données **AVR → programmateur** |
| 2 | VCC / VTG | Alimentation cible (**5 V** Digispark) |
| 3 | SCK | Horloge |
| 4 | MOSI | Données **programmateur → AVR** |
| 5 | RESET | Reset de la cible |
| 6 | GND | Masse |

## ATtiny85 (Digispark pads)

| ISP | Broche t85 |
|-----|------------|
| MISO | PB4 (phys. pin 3) |
| MOSI | PB3 (phys. pin 2) |
| SCK | PB2 (phys. pin 7) |
| RESET | PB5 (phys. pin 1) |
| VCC | pin 8 |
| GND | pin 4 |

## Liens utiles

- **Atmel AVR ISP User Guide** (PDF officiel, figure 6 et 10 broches) :  
  https://media.digikey.com/pdf/Data%20Sheets/Atmel%20PDFs/AVR%20ISP%20User%20Guide.pdf
- **Tableau 6 broches** (synthèse claire) :  
  https://www.raphnet.net/divers/documentation/avr_isp-pinouts.html
- **ISP 6 broches + Arduino** :  
  https://chirayilscitech.com/pinouts/avr-isp-6/
- **10 broches → 6 broches** : le câble USBasp 10 fils utilise un pinout STK ; adapter 6 broches fourni avec la plupart des kits.

## Attention

- **Pin 1** mal orienté = mauvais branchement (vérifie le **fil rouge** / marquage sur le câble plat).
- Ne pas alimenter le Digispark **USB PC** et **VCC ISP** en même temps.