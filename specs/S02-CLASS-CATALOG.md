# S02-CLASS-CATALOG: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Class Hierarchy

```
ANY
├── SIMPLE_QR                # Main facade
├── QR_ENCODER               # Data encoding
├── QR_ERROR_CORRECTION      # Reed-Solomon
├── QR_GALOIS                # Galois field math
├── QR_MATRIX                # QR construction
└── QR_VERSION               # Version tables
```

## Class Descriptions

### SIMPLE_QR (Facade)
Main entry point for QR code generation.
- **Creation**: `make`, `make_with_level`
- **Purpose**: Unified API for QR generation

### QR_ENCODER
Data encoding and mode detection.
- **Creation**: `make`
- **Purpose**: Convert text to bit stream

### QR_ERROR_CORRECTION
Reed-Solomon error correction.
- **Creation**: `make (level)`
- **Purpose**: Generate EC codewords

### QR_GALOIS
GF(2^8) finite field arithmetic.
- **Creation**: `make`
- **Purpose**: Field operations for Reed-Solomon

### QR_MATRIX
QR code matrix construction and masking.
- **Creation**: `make (version)`
- **Purpose**: Build visual QR pattern

### QR_VERSION
Version and capacity calculations.
- **Creation**: `make`
- **Purpose**: Determine version from data size
