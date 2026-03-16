class SegmentPatterns {
  // Segment Bit Definitions
  // Adapting standard 16-seg layout
  //     A1  A2
  //   F \  |  / B
  //   H  \ I / J
  //      G1  G2
  //   M  / L \ K
  //   E /  |  \ C
  //     D2  D1

  static const int A1 = 1 << 0; // Top Left Horiz
  static const int A2 = 1 << 1; // Top Right Horiz
  static const int B = 1 << 2; // Right Top Vert
  static const int C = 1 << 3; // Right Bottom Vert
  static const int D1 = 1 << 4; // Bottom Right Horiz
  static const int D2 = 1 << 5; // Bottom Left Horiz
  static const int E = 1 << 6; // Left Bottom Vert
  static const int F = 1 << 7; // Left Top Vert

  static const int G1 = 1 << 8; // Middle Left Horiz
  static const int G2 = 1 << 9; // Middle Right Horiz

  static const int H = 1 << 10; // Top Left Diag (inner)
  static const int I = 1 << 11; // Top Vert (inner)
  static const int J = 1 << 12; // Top Right Diag (inner)

  static const int K = 1 << 13; // Bottom Right Diag (inner)
  static const int L = 1 << 14; // Bottom Vert (inner)
  static const int M = 1 << 15; // Bottom Left Diag (inner)

  static const Map<int, int> _asciiMap = {
    // Special chars
    0x20: 0, // <blank>
    0x21: I | L, // !
    0x22: I | B, // "
    0x23: B | C | G1 | G2 | I | L | D1 | D2, // #
    0x24: A1 | A2 | F | G1 | G2 | C | D1 | D2 | I | L, // $
    0x25: F | I | A1 | G1 | G2 | C | D1 | L | M | J, // %
    0x26: A1 | I | H | G1 | E | K | D1 | D2, // &
    0x27: I, // '
    0x28: J | K, // (
    0x29: H | M, // )
    0x2A: H | J | K | M | G1 | G2 | I | L, // *
    0x2B: G1 | G2 | I | L, // +
    0x2C: M, // ,
    0x2D: G1 | G2, // -
    0x2E: D2, // .
    0x2F: M | J, // /
    // Numbers
    0x30: A1 | A2 | B | C | D1 | D2 | E | F | K | M, // 0 (diagonal slash)
    0x31: B | C, // 1
    0x32: A1 | A2 | B | G1 | G2 | E | D1 | D2, // 2
    0x33: A1 | A2 | B | C | D1 | D2 | G2, // 3
    0x34: F | G1 | G2 | B | C, // 4
    0x35: A1 | A2 | F | G1 | G2 | C | D1 | D2, // 5
    0x36: A1 | A2 | F | E | D1 | D2 | C | G1 | G2, // 6
    0x37: A1 | A2 | B | C, // 7
    0x38: A1 | A2 | B | C | D1 | D2 | E | F | G1 | G2, // 8
    0x39: A1 | A2 | B | C | D1 | D2 | F | G1 | G2, // 9
    0x3A: I | L, // |
    0x3B: M | I, // ;
    0x3C: G1 | J | K, // <
    0x3D: D1 | D2 | G1 | G2, // =
    0x3E: G2 | H | M, // >
    0x3F: A1 | A2 | B | G2 | L, // ?
    // Letters
    0x40: A1 | A2 | B | D1 | D2 | E | F | G2 | I, // @
    0x41: A1 | A2 | B | C | E | F | G1 | G2, // A
    0x42:
        A1 |
        A2 |
        B |
        C |
        D1 |
        D2 |
        I |
        L |
        G2, // B (Design 2: split middle vert)
    0x43: A1 | A2 | F | E | D1 | D2, // C
    0x44: A1 | A2 | B | C | D1 | D2 | I | L, // D
    0x45: A1 | A2 | F | E | D1 | D2 | G1 | G2, // E
    0x46: A1 | A2 | F | E | G1 | G2, // F
    0x47: A1 | A2 | F | E | D1 | D2 | C | G2, // G
    0x48: F | E | B | C | G1 | G2, // H
    0x49: A1 | A2 | D1 | D2 | I | L, // I
    0x4A: B | C | D1 | D2 | E, // J
    0x4B: F | E | G1 | J | K, // K
    0x4C: F | E | D1 | D2, // L
    0x4D: F | E | B | C | H | J, // M
    0x4E: F | E | B | C | H | K, // N
    0x4F: A1 | A2 | B | C | D1 | D2 | E | F, // O
    0x50: A1 | A2 | B | E | F | G1 | G2, // P
    0x51: A1 | A2 | B | C | D1 | D2 | E | F | K, // Q
    0x52: A1 | A2 | B | E | F | G1 | G2 | K, // R
    0x53: A1 | A2 | F | G1 | G2 | C | D1 | D2, // S
    0x54: A1 | A2 | I | L, // T
    0x55: B | C | D1 | D2 | E | F, // U
    0x56: F | E | M | J, // V
    0x57: F | E | B | C | M | K, // W
    0x58: H | J | K | M, // X
    0x59: B | C | D1 | D2 | F | G1 | G2, // Y
    0x5A: A1 | A2 | J | M | D1 | D2, // Z
    0x5B: I | L | A2 | D1, // [,
    0x5C: H | K, // \
    0x5D: I | L | A1 | D2, // ]
    0x5E: M | K, // ^
    0x5F: D1 | D2, // _
    0x60: H, // `
    0x61: D1 | D2 | E | L | G1, // a
    0x62: F | E | D2 | E | L | G1, // b
    0x63: D2 | G1 | E, // c
    0x64: D1 | B | C | L | D1 | G2, // d
    0x65: E | G1 | D2 | M, // e
    0x66: A2 | I | L | G1 | G2, // f
    0x67: F | A1 | I | L | D2 | G1, // g
    0x68: F | E | L | G1, // h
    0x69: L, // i
    0x6A: E | L | D2 | L | I, // j
    0x6B: I | L | J | K, // k
    0x6C: F | E, // l
    0x6D: E | G1 | G2 | L | C, // m
    0x6E: E | G1 | L, // n
    0x6F: G1 | L | D2 | E, // o
    0x70: A1 | I | F | G1 | E, // p
    0x71: A1 | I | F | G1 | L, // q
    0x72: E | G1, // r
    0x73: A1 | F | G1 | L | D2, // s
    0x74: F | E | D2 | G1, // t
    0x75: E | D2 | L, // u
    0x76: E | M, // v
    0x77: E | M | K | C, // w
    0x78: H | J | K | M, // x
    0x79: I | B | G2 | C | D1, // y
    0x7A: G1 | M | D2, // z
    0x7B: I | L | G1 | A2 | D1, // {
    0x7C: I | L, // |
    0x7D: I | L | A1 | D2 | G2, // }
    0x7E: G1 | G2 | M | J, // ~
    0x7F: 0, // DEL
  };

  static int getMask(int ascii) {
    return _asciiMap[ascii] ?? 0;
  }
}

class Segment7Patterns {
  // 7-Segment Bit Definitions
  //      A
  //    F   B
  //      G
  //    E   C
  //      D

  static const int A = 1 << 0;
  static const int B = 1 << 1;
  static const int C = 1 << 2;
  static const int D = 1 << 3;
  static const int E = 1 << 4;
  static const int F = 1 << 5;
  static const int G = 1 << 6;

  static const Map<int, int> _hexMap = {
    0x0: A | B | C | D | E | F,
    0x1: B | C,
    0x2: A | B | G | E | D,
    0x3: A | B | G | C | D,
    0x4: F | G | B | C,
    0x5: A | F | G | C | D,
    0x6: A | F | E | D | C | G,
    0x7: A | B | C,
    0x8: A | B | C | D | E | F | G,
    0x9: A | F | G | B | C | D,
    0xA: A | F | B | G | E | C,
    0xB: F | E | D | C | G,
    0xC: A | F | E | D,
    0xD: B | C | D | E | G,
    0xE: A | F | G | E | D,
    0xF: A | F | G | E,
  };

  static int getHexMask(int value) {
    return _hexMap[value & 0xF] ?? 0;
  }
}
