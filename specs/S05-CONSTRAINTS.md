# S05-CONSTRAINTS: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Technical Constraints

### QR Code Limits
- **Version Range**: 1-40
- **Module Range**: 21x21 to 177x177
- **EC Levels**: L, M, Q, H (1-4)

### Data Capacity (Alphanumeric, Level L)
| Version | Capacity |
|---------|----------|
| 1 | 25 chars |
| 10 | 174 chars |
| 20 | 412 chars |
| 40 | 1,852 chars |

### Mode Efficiency
| Mode | Bits/Char |
|------|-----------|
| Numeric | 3.33 |
| Alphanumeric | 5.5 |
| Byte | 8 |

### Mathematical Constraints
- GF(2^8) elements: 0-255
- Primitive polynomial: 0x11D
- Generator polynomial: Per EC level

## API Constraints

### Data
- Non-empty string required
- Any printable characters
- UTF-8 encoded as byte mode

### Version
- 0 = auto-detect
- 1-40 = explicit version
- Must fit data capacity

### EC Level
- 1-4 valid range
- Default: Level_m (2)

## Invariants

### Field Arithmetic
- All operations stay in GF(2^8)
- exp_table has 512 entries
- log_table has 256 entries

### Matrix
- Size = 17 + (version * 4)
- Module values are BOOLEAN
