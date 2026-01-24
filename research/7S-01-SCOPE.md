# 7S-01-SCOPE: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Problem Statement

Eiffel applications need to generate QR codes for URLs, text, and data encoding. No pure-Eiffel QR code library exists with Design by Contract coverage.

## Target Users

1. **Mobile App Developers** - App linking, payment codes
2. **E-commerce Systems** - Product codes, receipts
3. **Authentication Systems** - 2FA setup codes
4. **Document Systems** - Embedded data links
5. **Inventory Systems** - Asset tracking

## Core Capabilities

1. **QR Code Generation** - Encode text to QR matrix
2. **All 40 Versions** - 21x21 to 177x177 modules
3. **Four EC Levels** - L/M/Q/H (7-30% recovery)
4. **Auto Mode Detection** - Numeric, alphanumeric, byte
5. **Auto Version Selection** - Smallest version for data
6. **Output Formats** - ASCII art, PBM image
7. **Reed-Solomon EC** - GF(2^8) arithmetic

## Out of Scope

- QR code reading/scanning
- Image format output (PNG, SVG)
- Micro QR codes
- Structured append (multi-code)
- Kanji mode
- Custom masking patterns

## Success Criteria

1. Generate valid QR codes scannable by standard readers
2. Support data up to version 40 capacity
3. 100+ contracts verifying mathematical correctness
4. Pure Eiffel (no external dependencies)
5. SCOOP compatible
