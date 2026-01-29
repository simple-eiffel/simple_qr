# QR-DOC-SIGNER

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Executive Summary

QR-DOC-SIGNER is a command-line tool for embedding cryptographic verification QR codes into documents. It creates a chain of trust where any document can be verified as authentic by scanning the embedded QR code, which contains a hash of the document content and links to verification metadata.

The tool addresses the growing problem of document forgery in an increasingly digital world. Certificates, diplomas, contracts, and official documents are easily forged. QR-DOC-SIGNER provides a lightweight, offline-capable solution that doesn't require blockchain or cloud services.

Organizations can sign documents during issuance, and recipients or verifiers can confirm authenticity by scanning the QR code and comparing hashes. The verification database can be hosted locally, on an intranet, or published to a web server.

---

## Problem Statement

**The problem:** Document forgery is rampant. Fake diplomas, certificates, medical records, and official documents undermine trust. Traditional solutions (holograms, special paper) are expensive and still forgeable. Digital solutions often require complex PKI or cloud dependencies.

**Current solutions:**
- Holographic seals and watermarks - expensive, still forgeable
- PKI digital signatures - complex, requires technical expertise
- Blockchain verification - expensive, environmental concerns, overkill
- Cloud verification services - ongoing costs, vendor lock-in
- Manual verification calls - time-consuming, not scalable

**Our approach:** A simple cryptographic hash embedded in a QR code. The QR contains the document ID and content hash. Verification compares the scanned hash against a stored record. No blockchain, no cloud, no complexity. Just math.

---

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| **Primary: HR Department** | Issues employment letters, certificates | Batch signing, tamper detection |
| **Primary: Educational Institution** | Issues diplomas, transcripts | Mass issuance, public verification |
| **Secondary: Legal Department** | Contract verification | Audit trail, timestamping |
| **Secondary: Medical Records** | Patient record integrity | HIPAA compliance, chain of custody |
| **Secondary: Government Agency** | Official document issuance | High security, public verification |

---

## Value Proposition

**For** organizations that issue official documents
**Who** need to prevent forgery and enable verification
**This app** embeds cryptographic QR codes with offline verification
**Unlike** cloud services or blockchain solutions
**We** require no ongoing costs, internet, or vendor dependency

---

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| **Open Source Core** | Basic signing and verification | Free (MIT license) |
| **Professional License** | PDF integration, batch operations | $50/user/year or $500/org/year |
| **Enterprise License** | Multi-signature, HSM integration | $2,000-5,000/year |
| **Verification Portal** | Hosted public verification page | $100/month |

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Hash computation time | < 100ms per document | CLI timing |
| QR generation time | < 50ms per code | CLI timing |
| Verification time | < 200ms | CLI timing |
| Collision resistance | SHA-256 strength | Cryptographic guarantee |
| Batch signing (1000 docs) | < 60 seconds | CLI timing |

---

## Feature Set

### Core Features (Open Source)

1. **Document Signing**
   - Compute SHA-256 hash of document content
   - Generate unique document ID
   - Create QR code with ID + hash
   - Output QR as image for embedding

2. **Verification**
   - Scan/input QR data
   - Look up document in registry
   - Compare hashes
   - Report match/mismatch

3. **Registry Management**
   - SQLite database of signed documents
   - Metadata: issuer, date, document type
   - Export registry for backup/distribution

4. **Basic Reporting**
   - List signed documents
   - Verification history
   - Export to CSV

### Professional Features

5. **PDF Integration**
   - Embed QR directly into PDF
   - Configurable position and size
   - Batch PDF processing

6. **Batch Operations**
   - Sign directory of documents
   - Parallel processing
   - Progress reporting

7. **Advanced Metadata**
   - Custom fields per document type
   - Validity periods (expiration dates)
   - Revocation capability

### Enterprise Features

8. **Multi-Signature**
   - Multiple signers per document
   - Signature chains
   - Role-based signing

9. **HSM Integration**
   - Hardware Security Module support
   - Key protection
   - Audit logging

---

## Use Cases

### UC1: Sign Employment Letter

```
1. HR creates employment letter (PDF or other format)
2. Run: qr-doc sign letter.pdf --type employment --metadata "employee=John Smith"
3. Tool computes hash, generates QR, outputs qr-code.pbm
4. HR embeds QR into document footer
5. Record stored in local registry
```

### UC2: Verify Document

```
1. Recipient presents document with QR code
2. Verifier scans QR or inputs data manually
3. Run: qr-doc verify "DOC-abc123|sha256:7f3d..." [--registry path]
4. Tool looks up document, compares hash
5. Output: "VERIFIED: Employment Letter, John Smith, issued 2026-01-24"
   or: "FAILED: Hash mismatch - document may be altered"
```

### UC3: Batch Certificate Issuance

```
1. University prepares graduation data (CSV)
2. Run: qr-doc batch-sign certs/ --metadata-csv grads.csv --type diploma
3. Tool processes each document, generates QR codes
4. Run: qr-doc embed-pdf certs/ qr-codes/ --position bottom-right
5. 500 diplomas now have embedded verification QR codes
```

### UC4: Public Verification Portal

```
1. Organization exports verification data
2. Run: qr-doc export --format json --public > verify-data.json
3. Upload to web server or CDN
4. Public verification page fetches JSON, performs client-side verification
5. Anyone can verify documents without calling organization
```

### UC5: Document Revocation

```
1. Discover certificate was issued in error
2. Run: qr-doc revoke DOC-abc123 --reason "Issued in error"
3. Document marked as revoked in registry
4. Future verifications show: "REVOKED: Issued in error (2026-01-24)"
```

---

## Cryptographic Design

### Hash Computation

```
DOCUMENT CONTENT
      |
      v
  SHA-256 HASH (32 bytes / 64 hex chars)
      |
      v
  TRUNCATE TO 16 BYTES (32 hex chars) -- for QR capacity
      |
      v
  QR CONTENT: "qr-doc://DOC-{uuid}|{truncated-hash}"
```

### Verification Algorithm

```
1. Parse QR: Extract document_id and presented_hash
2. Look up document_id in registry
3. Retrieve stored_hash from registry
4. Compare:
   - If presented_hash == stored_hash: VERIFIED
   - If presented_hash != stored_hash: TAMPERED
   - If document_id not found: UNKNOWN
5. Check revocation status
6. Check expiration date (if applicable)
```

### Security Properties

| Property | Guarantee |
|----------|-----------|
| Collision resistance | SHA-256: 2^128 operations to find collision |
| Tamper detection | Any change produces different hash |
| Non-repudiation | Issuer signed document in registry |
| Offline verification | Only registry access needed |
| Forward secrecy | Past signatures remain valid if registry preserved |

---

## Trust Model

```
+-------------------+
|     ISSUER        |  Signs documents, maintains registry
+--------+----------+
         |
         | Signs
         v
+-------------------+
|    DOCUMENT       |  Contains QR code with hash
+--------+----------+
         |
         | Presented to
         v
+-------------------+
|    VERIFIER       |  Scans QR, queries registry
+--------+----------+
         |
         | Queries
         v
+-------------------+
|    REGISTRY       |  Stores document_id -> hash mapping
+-------------------+
```

The issuer is trusted to maintain registry integrity. Verifiers trust the registry to be accurate. Documents can be verified by anyone with registry access.
