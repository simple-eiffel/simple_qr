# simple_qr Extracted Specifications

## S01: Project Inventory

### ECF Configuration
- **File**: `simple_qr.ecf`
- **UUID**: `d3ca21a0-cf1c-4a8c-80e8-76263156d70d`
- **Library target**: `simple_qr`
- **Test target**: `simple_qr_tests`

### Dependencies
- `$ISE_LIBRARY/library/base/base.ecf`
- `$SIMPLE_EIFFEL/simple_file/simple_file.ecf`
- `$ISE_LIBRARY/library/testing/testing.ecf` (tests only)
- `$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf` (tests only)

### Capabilities
- Concurrency: SCOOP (support), thread (use)
- Void safety: all

### Clusters
- `src/` - 6 source classes
- `testing/` - 2 test files

---

## S02: Domain Model

### Problem Domain
QR (Quick Response) codes are 2D barcodes that encode data in a square matrix of dark/light modules.

### Domain Concepts
| Concept | Eiffel Class | Responsibility |
|---------|--------------|----------------|
| QR Code Generator | SIMPLE_QR | Facade for QR code creation |
| Data Encoder | QR_ENCODER | Converts text to bit stream |
| Module Matrix | QR_MATRIX | 2D dark/light grid representation |
| Version Calculator | QR_VERSION | Capacity tables and version selection |
| Error Correction | QR_ERROR_CORRECTION | Reed-Solomon codeword generation |
| Finite Field | QR_GALOIS | GF(2^8) arithmetic operations |

### Class Relationships
```
SIMPLE_QR (facade)
    ├── QR_ENCODER (encode data)
    ├── QR_VERSION (select version)
    ├── QR_ERROR_CORRECTION (generate EC)
    │       └── QR_GALOIS (field math)
    └── QR_MATRIX (place patterns, apply mask)
```

---

## S03: Class Specifications

### SIMPLE_QR (Facade)
**Purpose**: Simple API to generate QR codes from text data
**Creation**: `make`, `make_with_level(a_level: INTEGER)`

| Feature | Type | Specification |
|---------|------|---------------|
| `data` | STRING | Data to encode |
| `error_correction` | INTEGER | EC level (1=L, 2=M, 3=Q, 4=H) |
| `version` | INTEGER | QR version (0=auto, 1-40) |
| `matrix` | detachable QR_MATRIX | Generated matrix |
| `is_generated` | BOOLEAN | True if matrix exists |
| `generate` | command | Creates QR matrix from data |
| `to_ascii_art` | STRING | Render as ASCII |
| `to_pbm` | STRING | Render as PBM image |

**Invariant**:
- `error_correction_valid`: 1 ≤ error_correction ≤ 4
- `version_valid`: 0 ≤ version ≤ 40
- `generated_matrix_valid`: matrix implies 21 ≤ size ≤ 177

### QR_ENCODER
**Purpose**: Encode input data into QR code bit stream
**Modes**: Numeric (1), Alphanumeric (2), Byte (4)

| Feature | Type | Specification |
|---------|------|---------------|
| `mode` | INTEGER | Current encoding mode |
| `bits` | ARRAYED_LIST[BOOLEAN] | Encoded bit stream |
| `detect_mode(data)` | INTEGER | Optimal mode for data |
| `encode(data, version)` | command | Encode to bit stream |
| `to_codewords` | ARRAY[INTEGER] | Convert bits to bytes |

**Postcondition** (encode): `bits.count \\ 8 = 0` (byte-aligned)

### QR_MATRIX
**Purpose**: 2D matrix of dark/light modules with pattern placement
**Size**: 17 + (version * 4) per side

| Feature | Type | Specification |
|---------|------|---------------|
| `modules` | ARRAY2[BOOLEAN] | True=dark, False=light |
| `reserved` | ARRAY2[BOOLEAN] | Function pattern areas |
| `place_finder_patterns` | command | 7x7 at three corners |
| `place_alignment_patterns` | command | 5x5 at version positions |
| `place_timing_patterns` | command | Alternating row/col 7 |
| `place_data(codewords)` | command | Zigzag data placement |
| `apply_best_mask(ec)` | command | Select lowest penalty mask |

**Invariant**:
- `size = 17 + (version * 4)`
- `21 ≤ size ≤ 177`

### QR_VERSION
**Purpose**: Version utilities and capacity tables

| Feature | Type | Specification |
|---------|------|---------------|
| `module_count(v)` | INTEGER | 17 + v*4 |
| `character_capacity(v, mode, ec)` | INTEGER | Max chars |
| `minimum_version(data, mode, ec)` | INTEGER | Smallest fit |

**Ordering guarantees**:
- Capacity increases with version
- Numeric > Alphanumeric > Byte efficiency
- EC level L > M > Q > H capacity

### QR_ERROR_CORRECTION
**Purpose**: Generate Reed-Solomon error correction codewords

| Feature | Type | Specification |
|---------|------|---------------|
| `level` | INTEGER | EC level (1-4) |
| `generate_codewords(data, v)` | ARRAY[INTEGER] | EC codewords |
| `interleave_blocks(data, ec, v)` | ARRAY[INTEGER] | Final stream |
| `ec_codewords_per_block(v)` | INTEGER | EC count per block |

**Postcondition**: All codewords in range [0, 255]

### QR_GALOIS
**Purpose**: Galois Field GF(2^8) arithmetic for Reed-Solomon

| Feature | Type | Specification |
|---------|------|---------------|
| `add(x, y)` | INTEGER | XOR (bitwise) |
| `multiply(x, y)` | INTEGER | Log/antilog tables |
| `divide(x, y)` | INTEGER | x * inverse(y) |
| `inverse(x)` | INTEGER | Multiplicative inverse |
| `power(x, n)` | INTEGER | x^n in field |
| `exp(i)` | INTEGER | Alpha^i |
| `log(x)` | INTEGER | Log base alpha |

**Mathematical properties** (verified by tests):
- Additive identity: a + 0 = a
- Additive inverse: a + a = 0
- Multiplicative identity: a * 1 = a
- Commutative: a ⊕ b = b ⊕ a, a * b = b * a
- Inverse: a * inverse(a) = 1

---

## S04: Feature Specifications (Key Features)

### SIMPLE_QR.generate
```
generate
    require
        has_data: not data.is_empty
    ensure
        generated_or_error: is_generated or has_error
        generated_has_valid_size: is_generated implies module_count >= 21
```

**Steps**:
1. Detect encoding mode (numeric/alphanumeric/byte)
2. Calculate minimum version if auto (version=0)
3. Encode data to bit stream
4. Generate error correction codewords
5. Interleave data and EC
6. Create and populate matrix
7. Apply optimal mask pattern

### QR_ENCODER.detect_mode
```
detect_mode (a_data: STRING): INTEGER
    require
        data_not_void: a_data /= Void
    ensure
        result_valid: Result = 1 or Result = 2 or Result = 4
        numeric_implies_all_digits: Result = 1 implies all digits
```

### QR_MATRIX.apply_best_mask
```
apply_best_mask (a_ec_level: INTEGER)
    require
        ec_level_valid: 1 <= a_ec_level <= 4
    ensure
        best_mask_applied: True
```

Evaluates all 8 mask patterns, selects one with lowest penalty score.

---

## S05: Constraint Specifications

### Preconditions (Require)

| Class | Feature | Precondition |
|-------|---------|--------------|
| SIMPLE_QR | make_with_level | `1 <= level <= 4` |
| SIMPLE_QR | generate | `not data.is_empty` |
| SIMPLE_QR | to_ascii_art | `is_generated` |
| SIMPLE_QR | is_dark_module | `is_generated`, valid row/col |
| QR_MATRIX | make | `1 <= version <= 40` |
| QR_ENCODER | encode | `not data.is_empty`, `1 <= version <= 40` |
| QR_GALOIS | divide | `y > 0` (no division by zero) |
| QR_GALOIS | inverse | `x > 0` (zero has no inverse) |

### Postconditions (Ensure)

| Class | Feature | Postcondition |
|-------|---------|---------------|
| QR_ENCODER | encode | `bits.count \\ 8 = 0` (byte-aligned) |
| QR_ENCODER | to_codewords | all in [0, 255] |
| QR_GALOIS | multiply | `Result in [0, 255]` |
| QR_GALOIS | multiply | `x = 0 implies Result = 0` |
| QR_EC | generate_codewords | correct count, all in [0, 255] |

### Class Invariants

| Class | Invariant |
|-------|-----------|
| SIMPLE_QR | `1 <= error_correction <= 4` |
| SIMPLE_QR | `0 <= version <= 40` |
| SIMPLE_QR | `matrix implies valid size` |
| QR_MATRIX | `size = 17 + version * 4` |
| QR_MATRIX | `21 <= size <= 177` |
| QR_VERSION | modes_distinct, ec_levels_ordered |
| QR_GALOIS | tables exist and correctly sized |

---

## S06: Boundary Specifications (From Tests)

### Tested Boundaries

| Test | Boundary | Result |
|------|----------|--------|
| test_version_module_count_boundaries | V1=21, V40=177 | PASS |
| test_version_minimum_version_boundary | V1 capacity = 34 numeric | PASS |
| test_version_data_too_large | >8000 chars | Returns 0 |
| test_matrix_v1_boundaries | V1 corners (1,1)-(21,21) | PASS |
| test_matrix_v40_boundaries | V40 corner (177,177) | PASS |
| test_qr_single_char | Single character | PASS |
| test_qr_max_v1_capacity | 30 numeric chars | V1 |
| test_galois_inverse_property | All 255 non-zero elements | PASS |

### Edge Cases Tested
- Empty strings: Rejected by precondition
- Single character: Works
- Maximum capacity: Version auto-scales
- Special characters: Byte mode handles
- URL encoding: Works
- vCard format: Works

---

## S07: Test Coverage Summary

| Class | Tests | Coverage Areas |
|-------|-------|----------------|
| QR_GALOIS | 12 | Field axioms, known values |
| QR_VERSION | 8 | Module count, capacity, minimum version |
| QR_ENCODER | 8 | Mode detection, encoding, codewords |
| QR_ERROR_CORRECTION | 5 | Generator poly, EC codewords, interleave |
| QR_MATRIX | 9 | Patterns, masks, boundaries |
| SIMPLE_QR | 22 | Integration, edge cases, pipeline |

**Total**: 64 tests, 100% pass rate

---

## S08: Specification Summary

### Library Purpose
Generate QR codes from text data with:
- Support for versions 1-40 (21x21 to 177x177 modules)
- Four error correction levels (L/M/Q/H)
- Three encoding modes (numeric/alphanumeric/byte)
- Output formats: ASCII art, PBM image

### Key Design Decisions
1. **Facade pattern**: SIMPLE_QR hides complexity
2. **Automatic version selection**: Based on data size
3. **Default EC level M**: 15% error recovery
4. **Simplified block interleaving**: Single-block for low versions
5. **Capacity extrapolation**: Linear for versions > 10

### Contract Summary
- **6 classes** with full DBC
- **Strong preconditions** prevent invalid states
- **Postconditions** guarantee valid outputs
- **Invariants** maintain consistency
- **64 tests** verify all contracts

---

*Extracted from actual source code on 2026-01-18*
*Source files: simple_qr.e, qr_encoder.e, qr_matrix.e, qr_version.e, qr_error_correction.e, qr_galois.e*
