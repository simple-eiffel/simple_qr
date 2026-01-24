# S06-BOUNDARIES: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## System Boundaries

### Component Architecture

```
+-------------------+
|   Application     |
+--------+----------+
         |
         v
+--------+----------+
|    SIMPLE_QR      |
|     (Facade)      |
+--------+----------+
    |    |    |
    v    v    v
+-----+ +----+ +------+
|ENC  | |EC  | |MATRIX|
|(data)|(RS) | |(build)|
+--+--+ +--+-+ +--+---+
   |       |      |
   v       v      v
+------+ +------+ +------+
|Version| |Galois| |Mask  |
|(caps) | |(GF)  | |(pen) |
+------+ +------+ +------+
```

### Input Boundaries

| Input | Source | Validation |
|-------|--------|------------|
| Data | Caller | Non-empty string |
| EC Level | Caller | 1-4 |
| Version | Caller | 0-40 |
| Row/Col | Caller | 1 to module_count |

### Output Boundaries

| Output | Target | Format |
|--------|--------|--------|
| ASCII Art | Caller | STRING |
| PBM | Caller/File | STRING/File |
| is_generated | Caller | BOOLEAN |
| module_count | Caller | INTEGER |

## Dependency Boundaries

### Required
- simple_file (PBM output)
- EiffelBase (core types)

### None External
- Pure Eiffel implementation
- No C code
- No external libraries

## Trust Boundaries

### Trusted
- All internal calculations
- Galois field tables

### Untrusted
- Input data (size limits)
- Version selection (capacity)
