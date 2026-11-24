# Leonardo + carte SD (1 Go) — inventaire des actions possibles

**Contexte :** clé #2, USB `2341:8036`, stack clavier AZERTY/UTF-8 (`keyboard_*.h`, `flash-leonardo.ps1`).  
**SD :** module type **carte microSD ~1 Go** sur broches **SPI** (CS, MOSI, MISO, SCK) — stockage **côté microcontrôleur**, distinct du disque USB vu par Windows.

> **Usage légal :** lab personnel, machines **dont tu es propriétaire ou mandataire**. Pas de déploiement sur des tiers sans autorisation écrite.

---

## 1. Architecture : ce que fait quoi

| Rôle | Composant | Visible sous Windows | Rôle dans un payload |
|------|-----------|----------------------|----------------------|
| **Injection** | HID clavier (`Keyboard.h`) | Périphérique clavier | Frappe Win+R, PowerShell, chemins, texte |
| **Stockage local** | Carte SD (SPI) | **Non** (sauf firmware MSC custom, rare) | Lire scripts / config ; journaliser côté MCU |
| **Debug** | CDC série (COMx) | Port série Arduino | Logs développement ; **pas** fiable en attaque réelle (déjà débranché) |
| **Souris** | `Mouse.h` (optionnel) | Souris HID | Clics, mouvement curseur — **non utilisé** aujourd’hui |

**Important :** la SD **ne remplace pas** le Hak5 Ducky Storage en “clé USB + fichier .txt sur le PC”. Ici le MCU **lit la SD lui-même** au démarrage (lib `SD` / `SdFat`), puis **tape** le contenu sur le PC.

---

## 2. Ce que la SD 1 Go permet (côté firmware)

| Action | Description | Intérêt |
|--------|-------------|---------|
| **Multi-payloads sans reflash** | Fichiers `payload/01-recon.txt`, `02-demo.duck`, etc. ; sélecteur par **fichier flag**, **nom de volume**, bouton, ou **n° série** lu une fois | Équivalent “plusieurs scripts sur microSD” |
| **Payload volumineux** | PowerShell encodé, longues commandes, blocs JSON — dépasser ~28 Ko de flash program | 1 Go = largement suffisant |
| **Chaînes / dictionnaires** | Listes de mots de passe *locales de test*, chemins, hôtes — génération ou itération depuis SD | Pentest lab contrôlé |
| **Config runtime** | `layout.txt`, `DELAY=50`, `LANG=fr`, URL de callback **interne** | Un seul firmware, comportements variables |
| **Journal SD (MCU)** | Horodatage + code étape (OK/KO) écrit par le sketch | Savoir *sans COM* si une phase a été tentée (pas si PowerShell a vraiment réussi) |
| **Mise à jour “data only”** | Retirer SD, éditer fichiers sur PC, rebrancher | Plus rapide que `arduino-cli upload` |
| **Staged exfil (hybride)** | Payload tape vers un fichier sur le **disque du PC** ; un second fichier SD contient le chemin / nom cible à utiliser | Exfil via machine victime, pas via USB MSC Leonardo |
| **Images / binaires** | Stocker une archive : le clavier **ne peut pas** la copier seul ; il sert à lancer une commande qui **lit un partage ou une URL** | SD = dépôt de référence hors ligne |

**Non (ou très difficile) avec SD seule :**

| Idée | Pourquoi |
|------|-----------|
| Windows voit la SD comme **lecteur E:** | Il faudrait composite **USB Mass Storage** + HID sur 32U4 — peu de place, drivers, signature |
| **Lire** le disque du PC sur la SD | Pas de lien direct ; il faut **commandes** sur l’hôte |
| Keylogger → SD **sans** code sur le PC | Le MCU n’entend pas les touches de l’utilisateur (clavier **émetteur** seulement) |

---

## 3. Actions HID seules (sans exploit SD — état actuel du projet)

Tout ce qui suit = **série de frappes** sur une session **déjà ouverte** (utilisateur connecté, clavier actif, bon layout).

### 3.1 Interface & navigation Windows

- Ouvrir Exécuter (`Win+R`), Boîte de dialogue, Paramètres, Gestionnaire des tâches (`Ctrl+Shift+Esc`)
- `Alt+Tab`, `Win+D`, `Win+L` (verrouille — **stoppe** souvent la suite du payload)
- Raccourcis Explorer : `Win+E`, barre d’adresse, chemins UNC/`\\serveur\share`
- Éditeurs : Notepad, `notepad.exe` chemin, Bloc-notes → coller texte long (via commande)
- Navigateur : `Win`, taper URL ou `ms-edge` / `chrome` selon installation
- Menu contextuel : rare sans souris ; `Shift+F10` sur focus préalable

### 3.2 Lancement d’interpréteurs

- **PowerShell** : `-NoProfile`, `-WindowStyle Hidden`, `-ExecutionPolicy Bypass`, `-Command`, `-EncodedCommand`
- **cmd.exe**, `wt` (Terminal), **python** / **node** s’ils sont dans PATH
- **Exécution one-liner** encodée Base64 (longueur limitée par stabilité des délais)
- Chaîne **WMIC** / **PowerShell** pour WMI/CIM (déprécié mais vu en démos)

### 3.3 Reconnaissance & inventaire (faible impact, bon pour lab)

- `whoami`, `whoami /priv`, `hostname`, `$env:USERDOMAIN`
- `ipconfig /all`, `Get-NetIPAddress`, `arp -a`, `route print`
- `systeminfo`, version OS, domaine joint ou non
- `Get-Process`, services (`Get-Service`), logiciels installés (registre — commandes longues)
- Heure locale, fuseau, langue clavier
- **Écriture** résultat : `Out-File`, `>`, `Tee-Object` vers `Documents`, `Temp`, `%USERPROFILE%`

### 3.4 Réseau & connectivité

- `Test-NetConnection`, `ping`, `nslookup`, `tracert`
- Export config Wi‑Fi : `netsh wlan show profiles`, clés avec `key=clear` (**démo classique** — données **déjà** sur la machine)
- Partages : `net share`, mappage lecteur `net use`
- Ouverture d’URL interne (intranet, sensibilisation)

### 3.5 Fichiers & transfert (via l’hôte)

- Copier : `Copy-Item`, `xcopy`, `robocopy`
- Téléchargement : `Invoke-WebRequest`, `curl`, `bitsadmin` (selon politique)
- Compresse : `Compress-Archive` vers un zip local puis copy vers share
- **Exfil indirect :** upload vers serveur **que tu contrôles** (lab), paste bin interne, email (compte configuré — rarement fiable en auto)

### 3.6 Persistance & privilèges (sensibilité haute — lab mandaté)

- Tâche planifiée (`schtasks`, `Register-ScheduledTask`)
- Clés Run / RunOnce, Startup folder
- Service installé (admin requis)
- WMI subscription, script au logon
- **UAC** : souvent **bloque** ou demande clic — payload “aveugle” échoue souvent

### 3.7 Secrets & credentials (pédagogie / audit — pas “magie USB”)

| Cible | Mécanisme réaliste | Freins |
|--------|-------------------|--------|
| Profils Wi‑Fi | `netsh` | Données locales, pas le domaine |
| **cmdkey** / Credential Manager | PowerShell / `cmdkey /list` | Peu de mots de passe en clair |
| Navigateurs | Profils Chrome/Edge verrouillés, master password | Très limité en keystroke pur |
| SAM / LSASS | Outils tiers tapés au clavier | Admin + EDR + **illégal** hors mandat |
| Coffres (KeePass, etc.) | Fichier **déjà ouvert** ou chemin connu | Cas très spécifiques |

Le Ducky **ne “récupère” pas** les passwords : il **tape** des commandes. La valeur pédagogique est “session ouverte = clavier = utilisateur”.

### 3.8 Social & formation

- Message Notepad / email brouillon
- Page de sensibilisation BadUSB
- Chronomètre visible (preuve de vitesse)
- **Ouverture + fermeture** de fenêtres pour vidéo formation

### 3.9 Automatisation IT (bénin)

- Ouvrir un outil interne, coller une commande standard
- Lancer un script signé déjà présent sur GPO
- Configuration répétitive (reg add, setx) — **tester sur VM**

### 3.10 Souris (à ajouter dans un sketch)

- Déplacer curseur, clic, double-clic, glisser
- Valider UAC sur “Oui” (coordonnées **résolution-dépendantes**)
- Jeux “impossibles” sans calibration par écran

---

## 4. Actions **SD + HID** (à implémenter — non fait aujourd’hui)

| # | Action | Flux |
|---|--------|------|
| 1 | **Boot → lire `active.txt`** sur SD → exécuter ligne par ligne (DuckyScript-like maison) | `setup()` : init SPI SD → parse → `typeString` |
| 2 | **Menu physique** (bouton / jumper) : choix payload A/B/C | GPIO + fichiers SD |
| 3 | **LED** (+ fichier `ok.log` sur SD) | Feedback sans série |
| 4 | **Délais dynamiques** depuis `config.json` sur SD | PC lent / rapide |
| 5 | **Layout override** : `FORCE_QWERTY` sur SD sans recompiler | Fichier 1 octet |
| 6 | **Segmentation** : PHASE1.ps1 sur SD lu par MCU et **tapé** par morceaux avec pauses | Contournement longueur buffer |
| 7 | **Plusieurs langues** : `strings_fr.dat` / `strings_en.dat` | Switch selon `Get-WinUserLanguageList` si payload détecte via fichier tapé |
| 8 | **Rollback** : copie sur SD du dernier payload exécuté (hash, date) | Audit personnel |

**Lib Arduino typique :** `SD.h`, `SPI.h`, CS sur pin libre (souvent **D4** sur shield ; **vérifier ton câblage**).

---

## 5. Limites Leonardo (avec ou sans SD)

### Matériel / firmware

| Limite | Détail |
|--------|--------|
| Flash programme | ~28 Ko utiles — gros parseur Ducky + SD + HID → compter les octets |
| SRAM | ~2,5 Ko — buffers SD modestes |
| **Un seul USB** | Pas clavier + disque + serial tous stables sans composite élaboré |
| Vitesse frappe | Trop rapide → caractères perdus → `delay` |
| **Pas de Wi‑Fi / BT** sur Leonardo standard | Exfil toujours via **ce que tu tapes** |

### Clavier / locale (déjà partiellement résolu)

| Limite | Détail |
|--------|--------|
| AZERTY vs QWERTY | `layout_config.h` au **build** ; SD peut forcer plus tard |
| UTF-8 `œ` `«` `»` | **Verr. Num.** pour Alt+0xxx |
| Session **verrouillée** / login | Frappes dans le vide ou champ mot de passe |
| **Win+L** dans le payload | Auto-sabotage |

### Sécurité Windows

| Limite | Détail |
|--------|--------|
| **Defender / EDR** | PowerShell obscurci, encodé, fenêtre cachée → alertes |
| **AppLocker / WDAC** | Scripts non signés refusés |
| **UAC** | Clic ou échec sans souris calibrée |
| **Constrained Language Mode** | PowerShell bridé |
| **Historique** | Script Block Logging, Sysmon |
| GPO **installation périphériques** | USB bloqué ou restreint |

### Opérationnel

| Limite | Détail |
|--------|--------|
| Fenêtre focus | Notification, invite, autre app → mauvaise cible |
| Langue Windows UI | Chemins **Anglais** vs menus **FR** |
| Taille SD 1 Go | Irréaliste pour dumps disque ; **OK** pour texte/scripts |
| Cartes SD vieilles | Écritures lentes, corruption si retrait sans `sync` |

---

## 6. Matrice — faisabilité rapide

Légende : ✅ faisable (lab) · ⚠️ fragile · ❌ hors scope réaliste · 🔧 code à écrire

| Action | HID seul | + SD | Note |
|--------|----------|------|------|
| Texte / Notepad démo | ✅ | ✅ | **Fait** (`hello_notepad`) |
| Inventaire → fichier local | ✅ | ✅ | Bon 1er payload |
| Wi‑Fi profiles (netsh) | ✅ | ✅ | Démo sensible — **ta** machine |
| PowerShell hidden IWR | ⚠️ | ✅ | EDR |
| Exfil vers ta VM | ⚠️ | ✅ | Réseau |
| Multi-payload swap | ❌ | 🔧 | **SD requise** |
| Payload > flash sans SD | ❌ | 🔧 | Fichiers sur SD |
| Lire passwords sans commande | ❌ | ❌ | Mythe BadUSB |
| Clé USB disque pour Windows | ❌ | 🔧❌ | MSC custom lourd |
| Keylogger utilisateur → SD | ❌ | ❌ | Pas RX clavier |
| Clic UAC | ⚠️ | ⚠️ | `Mouse.h` + résolution |
| Avant login Windows | ❌ | ❌ | Besoin autre vecteur |

---

## 7. Idées de fichiers sur la SD (arborescence proposée)

```
/
├── config.ini          # DELAY_MS=80, LAYOUT=AZERTY
├── active              # nom du payload sans extension, ex: "recon"
├── payloads/
│   ├── recon.ps1.part  # morceaux tapés (option)
│   ├── recon.duck      # DSL maison : DELAY, STRING, ENTER
│   └── demo-notepad.txt
├── log/
│   └── last-run.txt    # écrit par le MCU
└── README.txt          # rappel légal / usage lab
```

---

## 8. Prochaines étapes projet WinAdmin

1. **Schéma câblage SD** (CS/MOSI/MISO/SCK) → noter dans `leonardo.md`
2. Sketch **`payload_runner`** : mount SD → lire `active` → exécuter
3. Réutiliser **`keyboard_utf8.h`** pour lignes `STRING` UTF-8
4. Payload lab **`recon-outfile`** sans SD puis version SD
5. (Optionnel) **`Mouse.h`** pour un scénario UAC sur VM résolution fixe

---

## 9. Liens projet

- [leonardo.md](./leonardo.md) — flash, layout, UTF-8  
- [duck.md](./duck.md) — index Leonardo  
- Inventaire global : [../Digispark/duck.md](../Digispark/duck.md)