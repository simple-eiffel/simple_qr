# S01-PROJECT-INVENTORY: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Project Structure

```
simple_qr/
├── src/
│   ├── simple_qr.e              # Main facade class
│   ├── qr_encoder.e             # Data encoding
│   ├── qr_error_correction.e    # Reed-Solomon EC
│   ├── qr_galois.e              # GF(2^8) arithmetic
│   ├── qr_matrix.e              # QR matrix construction
│   └── qr_version.e             # Version/capacity tables
├── bin/
│   └── [placeholder]
├── testing/
│   ├── test_app.e               # Test runner
│   └── lib_tests.e              # 64 comprehensive tests
├── docs/
│   └── index.html               # API documentation
├── audit/
│   └── [audit reports]
├── hardening/
│   └── [security hardening]
├── simple_qr.ecf                # Library configuration
├── README.md                    # User documentation
├── CHANGELOG.md                 # Version history
└── .gitignore
```

## ECF Configuration

- **Library Target**: simple_qr
- **Test Target**: simple_qr_tests
- **UUID**: Unique per library
- **Dependencies**: simple_file, EiffelBase

## Build Artifacts

- EIFGENs/simple_qr/ - Library compilation
- EIFGENs/simple_qr_tests/ - Test compilation
