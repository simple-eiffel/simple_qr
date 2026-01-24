# 7S-05-SECURITY: simple_qr

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_qr
**Status**: Production (64 tests passing)

## Threat Model

### Assets
1. Input data (may contain URLs, credentials)
2. Generated QR codes
3. Output files

### Threat Actors
1. Malicious data injection
2. QR code phishing
3. Resource exhaustion

## Security Considerations

### Data Handling
- **No validation** - Library encodes any string
- **Application responsibility** - Validate data before encoding
- **Sensitive data** - QR codes are easily read

### Resource Usage
- **Version 40** - 177x177 matrix
- **Memory** - O(n^2) for module storage
- **CPU** - Reed-Solomon is O(n^2)

### Output Security
- **PBM files** - No embedded metadata
- **ASCII art** - Text only
- **File permissions** - OS responsibility

## Recommendations

1. Validate input data at application level
2. Don't encode sensitive credentials in QR codes
3. Consider expiring URLs for security-sensitive uses
4. Use high EC level for important codes
5. Verify generated codes scan correctly

## Out of Scope
- Data encryption
- Digital signatures in QR
- Access control
- Code obfuscation
