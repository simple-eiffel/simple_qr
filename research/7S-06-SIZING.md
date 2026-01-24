# 7S-06-SIZING: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Complexity Assessment

### Source Files
| File | Lines | Complexity |
|------|-------|------------|
| simple_qr.e | ~366 | Medium - Facade |
| qr_encoder.e | ~200 | Medium - Encoding |
| qr_error_correction.e | ~300 | High - Reed-Solomon |
| qr_galois.e | ~200 | High - GF(2^8) |
| qr_matrix.e | ~400 | High - Module placement |
| qr_version.e | ~150 | Medium - Capacity tables |

**Total**: ~1,616 lines of Eiffel code

### External Dependencies
- simple_file (for save_pbm)
- No C code

## Resource Usage

### Memory
- Version 1: 21x21 = 441 modules
- Version 40: 177x177 = 31,329 modules
- Plus EC codewords and temp buffers

### CPU
- Mode detection: O(n) string scan
- Encoding: O(n) bit operations
- Reed-Solomon: O(n^2) polynomial math
- Matrix: O(n^2) module placement
- Masking: O(n^2) pattern application

## Performance Estimates

| Operation | Version 1 | Version 40 |
|-----------|-----------|------------|
| Encode | <1ms | 5-10ms |
| Generate EC | <1ms | 50-100ms |
| Build Matrix | <1ms | 20-50ms |
| Apply Mask | <1ms | 10-20ms |
| **Total** | ~5ms | ~200ms |
