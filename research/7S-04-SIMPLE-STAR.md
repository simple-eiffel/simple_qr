# 7S-04-SIMPLE-STAR: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Ecosystem Position

simple_qr is a FOUNDATION-level library for 2D barcode generation.

```
Barcode Libraries:
├── simple_qr     (QR codes - 2D)
└── [future: simple_barcode - 1D codes]
```

## Dependencies

| Library | Purpose | Required |
|---------|---------|----------|
| simple_file | PBM file output | Yes |
| EiffelBase | Core types | Yes |

## Integration Pattern

### ECF Configuration
```xml
<library name="simple_qr"
         location="$SIMPLE_EIFFEL/simple_qr/simple_qr.ecf"/>
```

### Basic Usage
```eiffel
local
    qr: SIMPLE_QR
do
    create qr.make
    qr.set_data ("https://example.com")
    qr.generate
    if qr.is_generated then
        print (qr.to_ascii_art)
        qr.save_pbm ("qrcode.pbm")
    end
end
```

### With Error Correction
```eiffel
create qr.make_with_level (qr.Level_h)  -- 30% recovery
```

## Ecosystem Conventions

1. **DBC emphasis** - 100+ contracts
2. **Mathematical proofs** - Galois field axioms verified
3. **Pure Eiffel** - No C code
4. **Void safe** - Complete
5. **SCOOP ready** - Compatible
