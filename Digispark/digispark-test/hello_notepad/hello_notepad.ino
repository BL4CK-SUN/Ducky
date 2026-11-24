// Premier test Digispark : ouvre le Bloc-notes (sans payload agressif).
// Carte : Digispark (Digistump AVR). Lib : DigisparkKeyboard (DigiKeyboard.h)
//
// Avant flash : session Windows déverrouillée, bureau visible, idéalement machine de test.

#include "DigiKeyboard.h"

void setup() {
  // Laisser Windows terminer l'énumération USB clavier/souris.
  DigiKeyboard.delay(3000);

  DigiKeyboard.sendKeyStroke(KEY_R, MOD_GUI_LEFT); // Win + R
  DigiKeyboard.delay(400);
  DigiKeyboard.println("notepad");
  DigiKeyboard.delay(300);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);

  // Preuve visuelle optionnelle (layout clavier = US côté HID ; AZERTY peut afficher autre chose).
  DigiKeyboard.delay(800);
  DigiKeyboard.println("Digispark test OK");
}

void loop() {
  // Rien : le payload ne tourne qu'au branchement / reset.
}