#ifndef KEYBOARD_HID_H
#define KEYBOARD_HID_H

#include <Keyboard.h>
#include "KeyboardLayout.h"

// Usage HID (0x04..0x38) + 136 : scancode physique, indépendant de _asciimap.
inline void typeHidUsage(uint8_t usage, bool shift = false, bool altgr = false) {
  if (altgr) {
    Keyboard.releaseAll();
    delay(15);
  }
  if (shift) Keyboard.press(KEY_LEFT_SHIFT);
  if (altgr) {
    Keyboard.press(KEY_RIGHT_ALT);
    delay(25);
  }
  Keyboard.press((uint8_t)(usage + 136));
  delay(altgr ? 25 : 8);
  Keyboard.release((uint8_t)(usage + 136));
  if (altgr) {
    delay(15);
    Keyboard.release(KEY_RIGHT_ALT);
  }
  if (shift) Keyboard.release(KEY_LEFT_SHIFT);
  delay(10);
}

// ASCII 7 bits via table PROGMEM (fr_FR / en_US) — même règle que Keyboard.cpp (AltGr avant Shift).
inline void typeFromLayoutMap(uint8_t c, const uint8_t layoutMap[]) {
  if (c >= 128) return;
  uint8_t k = pgm_read_byte(layoutMap + c);
  if (!k) return;
  bool shift = false;
  bool altgr = false;
  if ((k & ALT_GR) == ALT_GR) {
    altgr = true;
    k &= 0x3F;
  } else if ((k & SHIFT) == SHIFT) {
    shift = true;
    k &= 0x7F;
  }
  if (k == ISO_REPLACEMENT) k = ISO_KEY;
  typeHidUsage(k, shift, altgr);
}

// Windows : Alt + chiffres du pavé numérique (CP1252 / Latin-1). Nécessite Verr. num. activé.
inline void typeKeypadDigit(uint8_t digit) {
  static const uint8_t kp[10] = {
    KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4,
    KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9,
  };
  if (digit > 9) return;
  Keyboard.press(kp[digit]);
  delay(12);
  Keyboard.release(kp[digit]);
  delay(12);
}

// CP1252 / Latin-1 : Alt+0xxx (4 chiffres pavé num.) — pas Alt+123 sans zéros initiaux.
inline void typeWindowsAltCp1252(uint8_t code) {
  Keyboard.releaseAll();
  delay(15);
  Keyboard.press(KEY_LEFT_ALT);
  delay(25);
  typeKeypadDigit(0);
  typeKeypadDigit((uint8_t)((code / 100) % 10));
  typeKeypadDigit((uint8_t)((code / 10) % 10));
  typeKeypadDigit((uint8_t)(code % 10));
  delay(25);
  Keyboard.release(KEY_LEFT_ALT);
  delay(20);
}

#endif