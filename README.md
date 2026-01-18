<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.png" alt="simple_ library logo" width="400">
</p>

# simple_qr

**[Documentation](https://simple-eiffel.github.io/simple_qr/)** | **[GitHub](https://github.com/simple-eiffel/simple_qr)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![Tests](https://img.shields.io/badge/Tests-64%20passing-brightgreen.svg)]()
[![Built with simple_codegen](https://img.shields.io/badge/Built_with-simple__codegen-blueviolet.svg)](https://github.com/simple-eiffel/simple_code)

**Pure Eiffel QR code generation with mathematically verified contracts.**

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production Ready** - Comprehensive test coverage, full Design by Contract

## Overview

**simple_qr** generates QR codes from text data using pure Eiffel. It implements the complete QR code specification including:

- **All 40 QR versions** (21×21 to 177×177 modules)
- **Four error correction levels** (L/M/Q/H with 7-30% recovery)
- **Automatic mode detection** (numeric, alphanumeric, byte)
- **Reed-Solomon error correction** using GF(2^8) arithmetic
- **Output formats**: ASCII art, PBM image

What makes simple_qr special is its **aggressive use of Design by Contract**. Every mathematical property, every encoding rule, and every QR specification requirement is captured in executable contracts that prove correctness.

## Features

- **QR Code Generation** - Encode any text into scannable QR codes
- **Automatic Version Selection** - Finds smallest version that fits your data
- **Four EC Levels** - Balance data capacity vs. damage recovery
- **Design by Contract** - 100+ contracts verify mathematical correctness
- **64 Comprehensive Tests** - Prove every component works correctly
- **Void Safe** - Fully void-safe implementation
- **SCOOP Compatible** - Ready for concurrent use

## Installation

1. Set the ecosystem environment variable (one-time setup):
```bash
export SIMPLE_EIFFEL=D:\prod
```

2. Add to your ECF:
```xml
<library name="simple_qr" location="$SIMPLE_EIFFEL/simple_qr/simple_qr.ecf"/>
```

## Quick Start

```eiffel
local
    qr: SIMPLE_QR
do
    create qr.make
    qr.set_data ("Hello World")
    qr.generate

    if qr.is_generated then
        print (qr.to_ascii_art)
    end
end
```

### With Error Correction Level

```eiffel
local
    qr: SIMPLE_QR
do
    -- Use high error correction (30% recovery)
    create qr.make_with_level (4)  -- Level H
    qr.set_data ("https://example.com")
    qr.generate

    -- Save to PBM image file
    qr.save_pbm ("qrcode.pbm")
end
```

## API Reference

### SIMPLE_QR (Main Facade)

| Feature | Description |
|---------|-------------|
| `make` | Create with default settings (auto version, M correction) |
| `make_with_level (level)` | Create with specific EC level (1-4) |
| `set_data (text)` | Set data to encode |
| `set_error_correction (level)` | Set EC level: L=1, M=2, Q=3, H=4 |
| `generate` | Generate the QR code matrix |
| `is_generated` | Was generation successful? |
| `has_error` | Did an error occur? |
| `last_error` | Error message if generation failed |
| `module_count` | Size of generated QR (21-177) |
| `is_dark_module (row, col)` | Query individual module |
| `to_ascii_art` | Render as ASCII art string |
| `to_pbm` | Render as PBM image format |
| `save_pbm (path)` | Save to PBM file |

### Error Correction Levels

| Level | Constant | Recovery | Best For |
|-------|----------|----------|----------|
| L | `Level_l = 1` | ~7% | Maximum data capacity |
| M | `Level_m = 2` | ~15% | Balanced (default) |
| Q | `Level_q = 3` | ~25% | Higher reliability |
| H | `Level_h = 4` | ~30% | Maximum reliability |

## Design by Contract: Proven Correctness

simple_qr uses **aggressive Design by Contract** to guarantee correctness. Every class has contracts that capture the mathematical and logical specifications:

### Galois Field Arithmetic (QR_GALOIS)

Reed-Solomon error correction requires arithmetic in GF(2^8). Our contracts verify the field axioms:

```eiffel
add (a_x, a_y: INTEGER): INTEGER
    require
        x_in_field: a_x >= 0 and a_x <= 255
        y_in_field: a_y >= 0 and a_y <= 255
    ensure
        result_in_field: Result >= 0 and Result <= 255
        commutative: Result = a_y.bit_xor (a_x)
        additive_identity_x: a_y = 0 implies Result = a_x
        self_inverse: a_x = a_y implies Result = 0
```

### QR Matrix Construction (QR_MATRIX)

Contracts verify the QR specification is followed exactly:

```eiffel
make (a_version: INTEGER)
    require
        version_valid: a_version >= 1 and a_version <= 40
    ensure
        size_correct: size = 17 + (a_version * 4)
        all_modules_light: across 1 |..| size as r all
            across 1 |..| size as c all not modules.item (r, c) end end

place_finder_patterns
    ensure
        top_left_center_dark: modules.item (4, 4)
        top_right_center_dark: modules.item (4, size - 3)
        bottom_left_center_dark: modules.item (size - 3, 4)
```

### Class Invariants

Every class maintains invariants that can never be violated:

```eiffel
invariant
    -- SIMPLE_QR
    error_correction_valid: error_correction >= Level_l and error_correction <= Level_h
    version_valid: version >= 0 and version <= 40
    generated_matrix_valid: attached matrix as m implies (m.size >= 21 and m.size <= 177)

    -- QR_GALOIS
    exp_table_size: exp_table.count = 512
    log_table_size: log_table.count = 256
```

## Comprehensive Test Suite

64 tests verify every component of the library:

| Component | Tests | What's Verified |
|-----------|-------|-----------------|
| QR_GALOIS | 12 | Field axioms: identity, commutativity, inverse, exp/log |
| QR_VERSION | 8 | Module formula, capacity monotonicity, mode efficiency |
| QR_ENCODER | 8 | Mode detection, encoding correctness, codeword generation |
| QR_ERROR_CORRECTION | 5 | Generator polynomial, EC codewords, interleaving |
| QR_MATRIX | 9 | Finder patterns, timing, masks, data placement |
| SIMPLE_QR | 22 | Integration, edge cases, determinism, full pipeline |

### Run Tests

```bash
cd simple_qr
ec.exe -batch -config simple_qr.ecf -target simple_qr_tests -c_compile
./EIFGENs/simple_qr_tests/W_code/simple_qr.exe
```

Expected output:
```
simple_qr Comprehensive Test Suite
===================================
...
Results: 64 passed, 0 failed
Total:   64 tests

ALL TESTS PASSED
```

## Architecture

```
simple_qr/
├── src/
│   ├── simple_qr.e           -- Main facade (public API)
│   ├── qr_encoder.e          -- Data encoding (numeric/alphanumeric/byte)
│   ├── qr_error_correction.e -- Reed-Solomon EC generation
│   ├── qr_galois.e           -- GF(2^8) field arithmetic
│   ├── qr_matrix.e           -- QR matrix construction and masking
│   └── qr_version.e          -- Version/capacity calculations
├── testing/
│   ├── lib_tests.e           -- 64 comprehensive tests
│   └── test_app.e            -- Test runner
└── docs/
    └── index.html            -- API documentation
```

## Dependencies

- **simple_file** - File I/O for save_pbm
- EiffelBase (standard library)

## Why Design by Contract Matters

Traditional testing checks specific inputs and outputs. **Design by Contract goes further**:

1. **Specification as Code** - Contracts ARE the specification. Read `ensure` clauses to understand what a feature guarantees.

2. **Catches Edge Cases** - Contracts run on EVERY call, not just test cases. They catch bugs that tests miss.

3. **Self-Documenting** - `require` tells you what's valid input. `ensure` tells you what you can rely on.

4. **Mathematical Verification** - For algorithmic code like Reed-Solomon, contracts verify mathematical properties (commutativity, identity, inverse) not just sample outputs.

When you use simple_qr, you're not just trusting tests—you're trusting **executable specifications** that verify correctness on every operation.

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
