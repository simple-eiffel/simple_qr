# S04-FEATURE-SPECS: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## SIMPLE_QR Features

### Creation
| Feature | Signature | Description |
|---------|-----------|-------------|
| make | `make` | Create with defaults (M level) |
| make_with_level | `make_with_level (a_level: INTEGER)` | Create with EC level |

### Configuration
| Feature | Signature | Description |
|---------|-----------|-------------|
| set_data | `set_data (a_data: STRING)` | Set data to encode |
| set_error_correction | `set_error_correction (a_level: INTEGER)` | Set EC level |
| set_version | `set_version (a_version: INTEGER)` | Set explicit version |

### Generation
| Feature | Signature | Description |
|---------|-----------|-------------|
| generate | `generate` | Generate QR code matrix |
| save_pbm | `save_pbm (a_path: STRING)` | Save to PBM file |

### Status
| Feature | Signature | Description |
|---------|-----------|-------------|
| is_generated | `is_generated: BOOLEAN` | Generation successful? |
| has_error | `has_error: BOOLEAN` | Error occurred? |
| last_error | `last_error: STRING` | Error message |
| module_count | `module_count: INTEGER` | QR size (21-177) |

### Query
| Feature | Signature | Description |
|---------|-----------|-------------|
| is_dark_module | `is_dark_module (row, col): BOOLEAN` | Module color |
| to_ascii_art | `to_ascii_art: STRING` | ASCII rendering |
| to_pbm | `to_pbm: STRING` | PBM format |

### Constants
| Constant | Value | Description |
|----------|-------|-------------|
| Level_l | 1 | Low EC (7%) |
| Level_m | 2 | Medium EC (15%) |
| Level_q | 3 | Quartile EC (25%) |
| Level_h | 4 | High EC (30%) |

## QR_GALOIS Features (GF(2^8))

| Feature | Signature | Description |
|---------|-----------|-------------|
| add | `add (x, y): INTEGER` | XOR addition |
| multiply | `multiply (x, y): INTEGER` | Field multiplication |
| power | `power (x, n): INTEGER` | Exponentiation |
| inverse | `inverse (x): INTEGER` | Multiplicative inverse |
