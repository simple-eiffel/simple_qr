# 7S-03-SOLUTIONS: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Alternative Solutions Considered

### 1. Wrap C Library (Rejected)
- **Approach**: Wrap libqrencode or similar
- **Pros**: Fast, proven implementation
- **Cons**: External dependency, C interop
- **Decision**: Rejected - want pure Eiffel

### 2. Call Web Service (Rejected)
- **Approach**: Use Google Charts API or similar
- **Pros**: No implementation effort
- **Cons**: Network dependency, latency
- **Decision**: Rejected - must work offline

### 3. Pure Eiffel Implementation (Chosen)
- **Approach**: Implement full QR spec in Eiffel
- **Pros**: Pure Eiffel, full DBC, educational
- **Cons**: Development effort
- **Decision**: Selected - best for ecosystem

### 4. Image Library Integration (Deferred)
- **Approach**: Output via simple_image
- **Pros**: PNG/SVG output
- **Cons**: Additional dependency
- **Decision**: Deferred - ASCII/PBM sufficient for v1

## Architecture Decisions

1. **SIMPLE_QR facade** - Single entry point
2. **QR_ENCODER** - Mode detection and encoding
3. **QR_ERROR_CORRECTION** - Reed-Solomon EC
4. **QR_GALOIS** - GF(2^8) field arithmetic
5. **QR_MATRIX** - Module placement and masking
6. **QR_VERSION** - Capacity calculations
