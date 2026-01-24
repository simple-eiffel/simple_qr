# 7S-02-STANDARDS: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Applicable Standards

### QR Code Standard
- **ISO/IEC 18004:2015** - QR Code specification
- **JIS X 0510** - Japanese Industrial Standard

### Error Correction Levels
| Level | Recovery | Constant |
|-------|----------|----------|
| L | ~7% | Level_l = 1 |
| M | ~15% | Level_m = 2 |
| Q | ~25% | Level_q = 3 |
| H | ~30% | Level_h = 4 |

### Version Sizes
| Version | Modules | Data Capacity (L) |
|---------|---------|-------------------|
| 1 | 21x21 | 25 alphanumeric |
| 10 | 57x57 | 174 alphanumeric |
| 20 | 97x97 | 412 alphanumeric |
| 40 | 177x177 | 1,852 alphanumeric |

### Encoding Modes
- **Numeric**: 0-9 (3.33 bits/char)
- **Alphanumeric**: 0-9, A-Z, space, $%*+-./:
- **Byte**: ISO-8859-1 / UTF-8

### Reed-Solomon
- **Field**: GF(2^8)
- **Primitive Polynomial**: x^8 + x^4 + x^3 + x^2 + 1

## Output Formats

### ASCII Art
```
    ##  ##    ##
    ##  ##    ##
##  ##      ##
```

### PBM (Portable Bitmap)
```
P1
21 21
1 1 1 1 1 1 1 0 0 1 ...
```
