# QR-DOC-SIGNER - Technical Design

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                       QR-DOC-SIGNER                               |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (sign, verify, revoke, export)              |
|    - Input validation                                             |
|    - Output formatting (text, JSON)                               |
+------------------------------------------------------------------+
|  Business Logic Layer                                             |
|    - SIGNER: Hash computation, QR generation                      |
|    - VERIFIER: Hash comparison, status checks                     |
|    - REGISTRY_MANAGER: Document record management                 |
|    - PDF_EMBEDDER: QR placement in PDFs (Professional)            |
+------------------------------------------------------------------+
|  Cryptographic Layer                                              |
|    - HASH_ENGINE: SHA-256 computation                             |
|    - QR_GENERATOR: QR code creation                               |
|    - ID_GENERATOR: Unique document IDs                            |
+------------------------------------------------------------------+
|  Data Layer                                                       |
|    - DOCUMENT_REGISTRY: SQLite persistence                        |
|    - EXPORT_ENGINE: JSON/CSV export                               |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_qr: QR code generation                                |
|    - simple_hash: SHA-256 hashing                                 |
|    - simple_sql: SQLite database                                  |
|    - simple_json: Configuration and export                        |
|    - simple_file: File operations                                 |
|    - simple_uuid: Document IDs                                    |
|    - simple_datetime: Timestamps                                  |
|    - simple_pdf: PDF embedding (Professional)                     |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `QR_DOC_CLI` | Command-line interface | parse_args, route_command, format_output |
| `SIGNER` | Document signing | compute_hash, generate_qr, create_record |
| `VERIFIER` | Document verification | parse_qr, lookup, compare_hash, check_status |
| `REGISTRY_MANAGER` | Registry operations | add, revoke, query, export |
| `DOCUMENT_RECORD` | Document entity | id, hash, issuer, metadata, status |
| `HASH_ENGINE` | Hash computation | hash_file, hash_string, truncate |
| `QR_GENERATOR` | QR code creation | generate, save |
| `PDF_EMBEDDER` | PDF integration | embed_qr, batch_embed |
| `CONFIG` | Configuration | registry_path, qr_settings, defaults |

### Command Structure

```bash
qr-doc <command> [options] [arguments]

Commands:
  sign        Sign a document and generate verification QR
  verify      Verify a document using QR data
  revoke      Revoke a signed document
  list        List signed documents
  show        Show document details
  export      Export registry data
  import      Import registry data
  config      Manage configuration
  help        Show help

Subcommands (sign):
  qr-doc sign <file> [options]
    --type TYPE         Document type (certificate, diploma, contract, etc.)
    --issuer NAME       Issuing organization name
    --metadata KEY=VAL  Additional metadata (repeatable)
    --expires DATE      Expiration date (ISO 8601)
    --output FILE       Output QR code file (default: <file>.qr.pbm)
    --format FORMAT     QR output format (pbm, ascii)

Subcommands (verify):
  qr-doc verify <qr-data> [options]
    --registry PATH     Registry file to use
    --document FILE     Optional: re-hash document for comparison
    --output FORMAT     Output format (text, json)

Subcommands (revoke):
  qr-doc revoke <doc-id> [options]
    --reason REASON     Reason for revocation

Subcommands (export):
  qr-doc export [options]
    --format FORMAT     Export format (json, csv)
    --public            Export only public verification data
    --since DATE        Export documents since date
    --output FILE       Output file

Global Options:
  --registry FILE    Registry database (default: ~/.qr-doc/registry.db)
  --config FILE      Configuration file
  --quiet            Suppress non-essential output
  --verbose          Verbose output
  --help             Show help
```

### Data Flow

```
SIGNING:
                    +-------------+
                    |  Document   |
                    |    File     |
                    +------+------+
                           |
                           v
                    +-------------+
                    | HASH_ENGINE |
                    | (SHA-256)   |
                    +------+------+
                           |
                           v
                    +-------------+        +-------------+
                    |   SIGNER    | -----> | ID_GENERATOR|
                    +------+------+        +-------------+
                           |
              +------------+------------+
              |                         |
              v                         v
       +-------------+           +-------------+
       | QR_GENERATOR|           |  REGISTRY   |
       +------+------+           +-------------+
              |
              v
       +-------------+
       |  QR Code    |
       |  (PBM)      |
       +-------------+


VERIFICATION:
                    +-------------+
                    |  QR Data    |
                    | (scanned)   |
                    +------+------+
                           |
                           v
                    +-------------+
                    |  VERIFIER   |
                    +------+------+
                           |
              +------------+------------+
              |                         |
              v                         v
       +-------------+           +-------------+
       | Parse QR    |           |  REGISTRY   |
       | Extract ID  |           |  Lookup     |
       +------+------+           +------+------+
              |                         |
              +------------+------------+
                           |
                           v
                    +-------------+
                    | Compare     |
                    | Hashes      |
                    +------+------+
                           |
                           v
                    +-------------+
                    | VERIFIED or |
                    | FAILED      |
                    +-------------+
```

### Database Schema

```sql
-- Document records
CREATE TABLE documents (
    id TEXT PRIMARY KEY,              -- DOC-uuid
    content_hash TEXT NOT NULL,       -- SHA-256 hash (truncated)
    full_hash TEXT NOT NULL,          -- Full SHA-256 hash
    document_type TEXT NOT NULL,
    issuer TEXT NOT NULL,
    issued_at TEXT NOT NULL,          -- ISO 8601
    expires_at TEXT,                  -- ISO 8601, nullable
    status TEXT DEFAULT 'active',     -- active, revoked, expired
    revoked_at TEXT,
    revocation_reason TEXT,
    original_filename TEXT,
    file_size INTEGER,
    metadata TEXT,                    -- JSON for additional fields
    CONSTRAINT valid_status CHECK (status IN ('active', 'revoked', 'expired'))
);

-- Verification log
CREATE TABLE verifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id TEXT NOT NULL,
    verified_at TEXT NOT NULL,
    result TEXT NOT NULL,             -- verified, failed, revoked, expired, unknown
    verifier_ip TEXT,                 -- optional, for web verification
    notes TEXT,
    FOREIGN KEY (document_id) REFERENCES documents(id)
);

-- Issuers (for multi-issuer support)
CREATE TABLE issuers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    public_key TEXT,                  -- for future PKI support
    created_at TEXT NOT NULL,
    is_active INTEGER DEFAULT 1
);

-- Indexes
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_issuer ON documents(issuer);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_issued ON documents(issued_at);
CREATE INDEX idx_verifications_doc ON verifications(document_id);
```

### QR Code Content Format

```
qr-doc://v1/{document_id}|{truncated_hash}

Components:
- Scheme: qr-doc://
- Version: v1
- Document ID: DOC-{8-char-uuid-prefix}
- Separator: |
- Hash: First 32 hex chars of SHA-256 (16 bytes)

Example:
qr-doc://v1/DOC-7f3d2a1b|a1b2c3d4e5f67890a1b2c3d4e5f67890

Total length: ~60 characters (fits in Version 2 QR, EC level M)
```

### Configuration Schema

```json
{
  "qr_doc": {
    "registry": {
      "path": "~/.qr-doc/registry.db"
    },
    "signing": {
      "default_issuer": "My Organization",
      "default_type": "certificate",
      "hash_algorithm": "sha256",
      "hash_truncate_bytes": 16
    },
    "qr": {
      "error_correction": "M",
      "output_format": "pbm",
      "output_directory": "./qr-codes"
    },
    "verification": {
      "log_verifications": true,
      "check_expiration": true
    },
    "pdf": {
      "position": "bottom-right",
      "margin_x": 50,
      "margin_y": 50,
      "size": 100
    }
  }
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| File not found | Abort | "File not found: {path}" |
| File unreadable | Abort | "Cannot read file: {path}" |
| Hash computation failed | Abort | "Failed to compute hash: {details}" |
| QR generation failed | Abort | "Failed to generate QR code: {details}" |
| Document not in registry | Report | "Document not found in registry" |
| Hash mismatch | Report | "VERIFICATION FAILED: Document has been altered" |
| Document revoked | Report | "Document REVOKED: {reason} ({date})" |
| Document expired | Report | "Document EXPIRED: Valid until {date}" |
| Invalid QR format | Abort | "Invalid QR data format. Expected: qr-doc://v1/..." |
| Database error | Abort | "Registry error: {message}" |

---

## GUI/TUI Future Path

**CLI foundation enables:**

### TUI Extension
- Interactive document signing wizard
- Registry browser with search
- Verification result display with details
- Batch operation progress display

### GUI Extension
- Drag-and-drop document signing
- Visual QR placement on document preview
- Verification dashboard with statistics
- Registry management interface
- Mobile verification app (scan and verify)

### Web Extension
- Public verification portal
- API endpoint for programmatic verification
- Bulk verification interface
- Verification badge embedding

### Shared Components
- All cryptographic operations in HASH_ENGINE, SIGNER, VERIFIER
- Registry operations in REGISTRY_MANAGER
- QR generation in QR_GENERATOR
- Same database schema across all interfaces

---

## Security Considerations

1. **Hash Integrity**
   - SHA-256 for content hashing
   - Truncation preserves 128-bit security
   - No secret keys (transparency model)

2. **Registry Protection**
   - SQLite file permissions
   - Optional encryption at rest
   - Backup recommendations

3. **Revocation**
   - Immediate effect
   - Cannot un-revoke
   - Reason logged for audit

4. **Future: PKI Integration**
   - Issuer public keys in registry
   - Digital signatures on records
   - Certificate chain validation

---

## Performance Requirements

| Operation | Target | Notes |
|-----------|--------|-------|
| Hash 1MB file | < 50ms | SHA-256 is fast |
| Hash 100MB file | < 500ms | Streaming hash |
| QR generation | < 50ms | Per document |
| Registry lookup | < 10ms | Indexed query |
| Batch sign (100 docs) | < 10s | Parallel hashing |
| Export 10K records | < 5s | JSON streaming |
