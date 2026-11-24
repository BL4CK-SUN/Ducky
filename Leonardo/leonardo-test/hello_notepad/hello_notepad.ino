// Test Leonardo — Bloc-notes, texte adapté QWERTY / AZERTY (layout_config.h).
#include "layout_config.h"
#include <Keyboard.h>

static const char CMD_NOTEPAD[] = "notepad";
static const char MSG_TEST[] = u8"Leonardo OK - 123 . ! @ café € œ «bon»";

void setup() {
  keyboardBegin(TARGET_LAYOUT);
  delay(5000);

  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(100);
  Keyboard.releaseAll();
  delay(600);

  typeString(CMD_NOTEPAD, TARGET_LAYOUT);
  delay(400);
  Keyboard.write(KEY_RETURN);
  delay(1200);

  typeString(MSG_TEST, TARGET_LAYOUT);
}

void loop() {}