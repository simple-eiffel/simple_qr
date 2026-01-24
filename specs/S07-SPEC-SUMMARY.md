# S07-SPEC-SUMMARY: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Executive Summary

simple_qr provides pure-Eiffel QR code generation with mathematically verified contracts. 64 comprehensive tests validate Galois field arithmetic, Reed-Solomon encoding, and QR matrix construction.

## Key Specifications

### Architecture
- **Pattern**: Facade with internal components
- **Main Class**: SIMPLE_QR
- **Components**: QR_ENCODER, QR_ERROR_CORRECTION, QR_GALOIS, QR_MATRIX, QR_VERSION

### API Design
- **Simple Interface**: set_data, generate, output
- **EC Levels**: L/M/Q/H constants
- **Auto Selection**: Version and mode

### Features
1. All 40 QR versions
2. Four error correction levels
3. Three encoding modes (auto-detected)
4. Reed-Solomon error correction
5. All 8 mask patterns
6. ASCII art output
7. PBM image output
8. 100+ contracts

### Dependencies
- simple_file (for save_pbm)
- EiffelBase

### Platform Support
- All platforms (pure Eiffel)
- SCOOP compatible
- Void safe

## Contract Highlights

- GF(2^8) field axioms verified
- Module count formula proven
- EC level bounds enforced
- Matrix size invariants

## Performance Targets

| Version | Generation Time |
|---------|-----------------|
| 1 | <5ms |
| 10 | <50ms |
| 40 | <200ms |
