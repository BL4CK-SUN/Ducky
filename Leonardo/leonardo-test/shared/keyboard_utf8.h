#ifndef KEYBOARD_UTF8_H
#define KEYBOARD_UTF8_H

#include "keyboard_layout.h"
#include "keyboard_hid.h"

inline const uint8_t* layoutMapFor(KeyboardLayout layout) {
  return (layout == LAYOUT_AZERTY) ? KeyboardLayout_fr_FR : KeyboardLayout_en_US;
}

// Décode un codepoint UTF-8 ; avance *p. Retourne 0 si fin ou erreur.
inline uint32_t utf8Next(const char** p) {
  const uint8_t* s = (const uint8_t*)*p;
  if (!*s) return 0;
  if (s[0] < 0x80) {
    (*p)++;
    return s[0];
  }
  if ((s[0] & 0xE0) == 0xC0 && s[1]) {
    uint32_t cp = ((s[0] & 0x1F) << 6) | (s[1] & 0x3F);
    *p += 2;
    return cp;
  }
  if ((s[0] & 0xF0) == 0xE0 && s[1] && s[2]) {
    uint32_t cp = ((s[0] & 0x0F) << 12) | ((s[1] & 0x3F) << 6) | (s[2] & 0x3F);
    *p += 3;
    return cp;
  }
  if ((s[0] & 0xF8) == 0xF0 && s[1] && s[2] && s[3]) {
    uint32_t cp = ((s[0] & 0x07) << 18) | ((s[1] & 0x3F) << 12) | ((s[2] & 0x3F) << 6) | (s[3] & 0x3F);
    *p += 4;
    return cp;
  }
  (*p)++;
  return 0xFFFD;
}

inline void typeFrCircumflexVowel(char vowel) {
  typeFromLayoutMap('^', KeyboardLayout_fr_FR);
  delay(80);
  typeFromLayoutMap((uint8_t)vowel, KeyboardLayout_fr_FR);
}

inline void typeFrDiaeresisVowel(char vowel) {
  typeFromLayoutMap('"', KeyboardLayout_fr_FR);
  delay(80);
  typeFromLayoutMap((uint8_t)vowel, KeyboardLayout_fr_FR);
}

inline bool typeCodepointAzerty(uint32_t cp) {
  switch (cp) {
    case 0x20AC: typeHidUsage(0x08, false, true); return true; // € AltGr+e
    // œ : AltGr+o absent sur certains FR ; Alt+0156 (CP1252 0x9C), Verr. num. requis.
    case 0x0153: typeWindowsAltCp1252(0x9C); return true;
    case 0x0152: typeWindowsAltCp1252(0x8C); return true;
    case 0x00E9: typeHidUsage(0x1F); return true; // é
    case 0x00C9: typeHidUsage(0x1F, true); return true;
    case 0x00E8: typeHidUsage(0x24); return true; // è
    case 0x00C8: typeHidUsage(0x24, true); return true;
    case 0x00E0: typeHidUsage(0x27); return true; // à
    case 0x00C0: typeHidUsage(0x27, true); return true;
    case 0x00E7: typeHidUsage(0x25); return true; // ç
    case 0x00C7: typeHidUsage(0x25, true); return true;
    case 0x00F9: typeHidUsage(0x36); return true; // ù
    case 0x00D9: typeHidUsage(0x36, true); return true;
    case 0x00EA: typeFrCircumflexVowel('e'); return true;
    case 0x00CA: typeFrCircumflexVowel('E'); return true;
    case 0x00E2: typeFrCircumflexVowel('a'); return true;
    case 0x00C2: typeFrCircumflexVowel('A'); return true;
    case 0x00EE: typeFrCircumflexVowel('i'); return true;
    case 0x00CE: typeFrCircumflexVowel('I'); return true;
    case 0x00F4: typeFrCircumflexVowel('o'); return true;
    case 0x00D4: typeFrCircumflexVowel('O'); return true;
    case 0x00FB: typeFrCircumflexVowel('u'); return true;
    case 0x00DB: typeFrCircumflexVowel('U'); return true;
    case 0x00EB: typeFrDiaeresisVowel('e'); return true;
    case 0x00CB: typeFrDiaeresisVowel('E'); return true;
    case 0x00EF: typeFrDiaeresisVowel('i'); return true;
    case 0x00CF: typeFrDiaeresisVowel('I'); return true;
    case 0x00FC: typeFrDiaeresisVowel('u'); return true;
    case 0x00DC: typeFrDiaeresisVowel('U'); return true;
    // Guillemets : Alt+0171 / 0187 (CP1252), Verr. num. — AltGr ISO variable selon clavier.
    case 0x00AB: typeWindowsAltCp1252(0xAB); return true;
    case 0x00BB: typeWindowsAltCp1252(0xBB); return true;
    case 0x2013: case 0x2014:
      typeFromLayoutMap('-', KeyboardLayout_fr_FR);
      return true;
    case 0x00A0:
      typeFromLayoutMap(' ', KeyboardLayout_fr_FR);
      return true;
    default: return false;
  }
}

inline void typeCodepointQwerty(uint32_t cp) {
  const uint8_t* map = KeyboardLayout_en_US;
  if (cp <= 0x7F) {
    typeFromLayoutMap((uint8_t)cp, map);
    return;
  }
  switch (cp) {
    case 0x20AC: typeFromLayoutMap('E', map); return;
    case 0xE9: case 0xC9: typeFromLayoutMap('e', map); return;
    case 0xE8: case 0xC8: typeFromLayoutMap('e', map); return;
    case 0xEA: case 0xCA: typeFromLayoutMap('e', map); return;
    case 0xE0: case 0xC0: typeFromLayoutMap('a', map); return;
    case 0xE7: case 0xC7: typeFromLayoutMap('c', map); return;
    default:
      typeFromLayoutMap('?', map);
  }
}

inline void typeCodepoint(uint32_t cp, KeyboardLayout layout) {
  const uint8_t* map = layoutMapFor(layout);
  if (cp <= 0x7F) {
    typeFromLayoutMap((uint8_t)cp, map);
    return;
  }
  if (layout == LAYOUT_AZERTY) {
    if (typeCodepointAzerty(cp)) return;
    typeFromLayoutMap('?', KeyboardLayout_fr_FR);
    return;
  }
  typeCodepointQwerty(cp);
}

inline void typeStringUtf8(const char* s, KeyboardLayout layout) {
  keyboardBegin(layout);
  const char* p = s;
  while (*p) {
    uint32_t cp = utf8Next(&p);
    if (cp == 0) break;
    typeCodepoint(cp, layout);
  }
}

// Chaîne longue en PROGMEM (payload EncodedCommand, etc.).
inline void typeStringPgm(const char* s, KeyboardLayout layout) {
  keyboardBegin(layout);
  for (;;) {
    char c = (char)pgm_read_byte(s++);
    if (!c) break;
    typeCodepoint((uint32_t)(uint8_t)c, layout);
  }
}

#endif