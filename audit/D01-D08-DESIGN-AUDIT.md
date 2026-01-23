# simple_qr Design Audit (OOSC2 Compliance)

## D01: Single Choice Principle

**Principle**: Whenever a software system must support a set of alternatives, one and only one module in the system should know their exhaustive list.

### Assessment

| Decision | Location | Status |
|----------|----------|--------|
| EC levels (L/M/Q/H) | SIMPLE_QR constants | ✓ COMPLIANT |
| Encoding modes | QR_ENCODER constants | ✓ COMPLIANT |
| Mask patterns | QR_MATRIX.should_mask | ✓ COMPLIANT |
| Version limits | QR_VERSION constants | ✓ COMPLIANT |

**Finding**: All alternatives centralized in single class.

---

## D02: Open/Closed Principle

**Principle**: Software entities should be open for extension but closed for modification.

### Assessment

| Class | Extensibility | Status |
|-------|---------------|--------|
| SIMPLE_QR | Features can override | ✓ COMPLIANT |
| QR_ENCODER | encode_* methods separate | ✓ COMPLIANT |
| QR_MATRIX | Pattern placement modular | ✓ COMPLIANT |
| QR_GALOIS | Operations complete | ✓ COMPLIANT |

**Finding**: Classes use feature separation, no inspect/when on type.

---

## D03: Command/Query Separation

**Principle**: A feature should either be a command (changes state) or a query (returns value), never both.

### Assessment

| Feature | Type | Returns | Modifies | Status |
|---------|------|---------|----------|--------|
| SIMPLE_QR.generate | Command | - | matrix | ✓ COMPLIANT |
| SIMPLE_QR.is_generated | Query | BOOLEAN | - | ✓ COMPLIANT |
| SIMPLE_QR.to_ascii_art | Query | STRING | - | ✓ COMPLIANT |
| SIMPLE_QR.set_data | Command | - | data | ✓ COMPLIANT |
| QR_ENCODER.encode | Command | - | bits | ✓ COMPLIANT |
| QR_ENCODER.detect_mode | Query | INTEGER | - | ✓ COMPLIANT |
| QR_GALOIS.multiply | Query | INTEGER | - | ✓ COMPLIANT |
| QR_MATRIX.apply_mask | Command | - | modules | ✓ COMPLIANT |
| QR_MATRIX.is_dark | Query | BOOLEAN | - | ✓ COMPLIANT |

**Finding**: All features properly separated.

---

## D04: Uniform Access Principle

**Principle**: All services offered by a module should be available through a uniform notation.

### Assessment

| Class | Access Pattern | Status |
|-------|----------------|--------|
| SIMPLE_QR | data (attribute), is_generated (function) | ✓ COMPLIANT |
| QR_MATRIX | size (attribute), is_dark (function) | ✓ COMPLIANT |
| QR_ENCODER | mode (attribute), bit_count (function) | ✓ COMPLIANT |

**Finding**: Attributes and functions interchangeable from client view.

---

## D05: Design by Contract

**Principle**: Use preconditions, postconditions, and invariants.

### Assessment

| Class | Require | Ensure | Invariant | Status |
|-------|---------|--------|-----------|--------|
| SIMPLE_QR | 12 | 15 | 4 | ✓ STRONG |
| QR_ENCODER | 8 | 14 | 3 | ✓ STRONG |
| QR_MATRIX | 18 | 22 | 6 | ✓ STRONG |
| QR_VERSION | 8 | 10 | 4 | ✓ STRONG |
| QR_ERROR_CORRECTION | 10 | 12 | 3 | ✓ STRONG |
| QR_GALOIS | 12 | 20 | 4 | ✓ STRONG |

**Finding**: Comprehensive contracts throughout. Mathematical properties verified.

### Contract Examples

**QR_GALOIS.add** - Postconditions verify field axioms:
```eiffel
ensure
    result_in_field: Result >= 0 and Result <= 255
    commutative: Result = a_y.bit_xor (a_x)
    additive_identity_x: a_y = 0 implies Result = a_x
    additive_identity_y: a_x = 0 implies Result = a_y
    self_inverse: a_x = a_y implies Result = 0
```

---

## D06: Information Hiding

**Principle**: Module should reveal only necessary information.

### Assessment

| Class | Public | Private | Status |
|-------|--------|---------|--------|
| SIMPLE_QR | 15 | 0 | ⚠ All public |
| QR_ENCODER | 12 | 6 | ✓ COMPLIANT |
| QR_MATRIX | 15 | 12 | ✓ COMPLIANT |
| QR_VERSION | 8 | 4 | ✓ COMPLIANT |
| QR_ERROR_CORRECTION | 8 | 3 | ✓ COMPLIANT |
| QR_GALOIS | 10 | 2 | ✓ COMPLIANT |

**Finding**: Most classes properly hide implementation. SIMPLE_QR is facade (all public expected).

---

## D07: Genericity

**Principle**: Use type parameterization where appropriate.

### Assessment

| Usage | Class | Status |
|-------|-------|--------|
| ARRAY2[BOOLEAN] | QR_MATRIX.modules | ✓ USES STDLIB |
| ARRAYED_LIST[BOOLEAN] | QR_ENCODER.bits | ✓ USES STDLIB |
| ARRAY[INTEGER] | Various | ✓ USES STDLIB |

**Finding**: Uses standard library generics appropriately. No custom generic classes needed.

---

## D08: Audit Summary

### OOSC2 Compliance Score

| Principle | Score | Notes |
|-----------|-------|-------|
| Single Choice | 5/5 | All decisions centralized |
| Open/Closed | 5/5 | Extensible design |
| Command/Query | 5/5 | Perfect separation |
| Uniform Access | 5/5 | Transparent |
| Design by Contract | 5/5 | Comprehensive |
| Information Hiding | 4/5 | SIMPLE_QR all public (facade) |
| Genericity | 5/5 | Uses stdlib generics |

**Overall**: 34/35 (97%) - Excellent OOSC2 compliance

### Design Strengths

1. **Mathematical Correctness**: QR_GALOIS contracts verify field axioms
2. **Facade Pattern**: SIMPLE_QR provides simple API
3. **Separation of Concerns**: Each class has single responsibility
4. **Strong Contracts**: All boundaries protected

### Design Recommendations

1. **None critical** - Design is sound
2. **Optional**: Add feature export clauses to SIMPLE_QR for non-client access control

### Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                    CLIENT                        │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│              SIMPLE_QR (Facade)                 │
│  - Simple API                                   │
│  - Orchestrates generation                      │
└─────────────────────────────────────────────────┘
           │              │              │
           ▼              ▼              ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ QR_VERSION  │  │ QR_ENCODER  │  │ QR_MATRIX   │
│ - Capacity  │  │ - Bit stream│  │ - Patterns  │
│ - Selection │  │ - Modes     │  │ - Masking   │
└─────────────┘  └─────────────┘  └─────────────┘
                        │              │
                        ▼              │
              ┌─────────────────┐      │
              │ QR_ERROR_       │      │
              │ CORRECTION      │◄─────┘
              │ - Reed-Solomon  │
              └─────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │   QR_GALOIS     │
              │ - GF(2^8) math  │
              └─────────────────┘
```

---

*Audit completed: 2026-01-18*
*Standard: OOSC2 (Object-Oriented Software Construction 2nd Ed)*
