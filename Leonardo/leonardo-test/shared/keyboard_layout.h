#ifndef KEYBOARD_LAYOUT_H
#define KEYBOARD_LAYOUT_H

#include <Keyboard.h>

enum KeyboardLayout { LAYOUT_QWERTY = 0, LAYOUT_AZERTY = 1 };

// Table officielle Arduino (fr_FR / en_US) : lettres, chiffres, ponctuation, AltGr (@, #, …).
// Voir KeyboardLayout_fr_FR.cpp dans la lib Keyboard 1.0.x

inline void keyboardBegin(KeyboardLayout layout) {
  if (layout == LAYOUT_AZERTY) {
    Keyboard.begin(KeyboardLayout_fr_FR);
  } else {
    Keyboard.begin(KeyboardLayout_en_US);
  }
}

#include "keyboard_utf8.h"

// Chaîne UTF-8 (fichier .ino en UTF-8) : ASCII via fr_FR/en_US + Latin-1 étendu (é, €, œ, …).
inline void typeString(const char* s, KeyboardLayout layout) {
  typeStringUtf8(s, layout);
}

#endif