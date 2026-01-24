# S03-CONTRACTS: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## SIMPLE_QR Contracts

### make
```eiffel
make
    ensure
        default_correction: error_correction = Level_m
        auto_version: version = 0
        empty_data: data.is_empty
        no_error: last_error.is_empty
        not_generated: not is_generated
```

### make_with_level
```eiffel
make_with_level (a_level: INTEGER)
    require
        level_valid: a_level >= Level_l and a_level <= Level_h
    ensure
        correction_set: error_correction = a_level
        auto_version: version = 0
```

### set_data
```eiffel
set_data (a_data: STRING)
    require
        data_not_void: a_data /= Void
    ensure
        data_set: data = a_data
        matrix_cleared: matrix = Void
        error_cleared: last_error.is_empty
```

### generate
```eiffel
generate
    require
        has_data: not data.is_empty
    ensure
        generated_or_error: is_generated or has_error
        generated_has_valid_size: is_generated implies module_count >= 21
```

## QR_GALOIS Contracts (Mathematical Proofs)

### add
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

## Invariants

### SIMPLE_QR
```eiffel
invariant
    error_correction_valid: error_correction >= Level_l and error_correction <= Level_h
    version_valid: version >= 0 and version <= 40
    data_exists: data /= Void
    generated_matrix_valid: attached matrix as m implies
        (m.size >= 21 and m.size <= 177)
```

### QR_GALOIS
```eiffel
invariant
    exp_table_size: exp_table.count = 512
    log_table_size: log_table.count = 256
```
