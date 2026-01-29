# QR-DOC-SIGNER - Build Plan

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 3-4 days | simple_qr, simple_hash, simple_sql |
| Phase 2 | Full CLI | 3-4 days | Phase 1 + simple_json, export |
| Phase 3 | Polish | 2-3 days | Phase 2 complete |

**Total Estimated Effort:** 8-11 days

---

## Phase 1: MVP (Minimum Viable Product)

### Objective

Deliver a working CLI that can sign documents (compute hash, generate QR), store in registry, and verify documents. This proves the core value: offline document verification.

### Deliverables

1. **HASH_ENGINE class** - SHA-256 hashing with truncation
2. **QR_GENERATOR class** - Verification QR creation
3. **DOCUMENT_RECORD class** - Document entity
4. **DOCUMENT_REGISTRY class** - SQLite persistence
5. **SIGNER class** - Signing orchestration
6. **VERIFIER class** - Verification logic
7. **QR_DOC_CLI class** - Basic CLI
8. **Basic commands:** sign, verify, show

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure | ECF compiles, directories exist |
| T1.2 | Implement HASH_ENGINE | SHA-256, truncation, contracts |
| T1.3 | Implement QR_GENERATOR | QR creation, PBM output |
| T1.4 | Implement DOCUMENT_RECORD | Entity with validation |
| T1.5 | Implement DOCUMENT_REGISTRY | SQLite schema, CRUD |
| T1.6 | Implement SIGNER | Hash + QR + register |
| T1.7 | Implement VERIFIER | Parse, lookup, compare |
| T1.8 | Implement CLI skeleton | Arg parsing, routing |
| T1.9 | Implement `sign` command | Full signing workflow |
| T1.10 | Implement `verify` command | Full verification workflow |
| T1.11 | Implement `show` command | Display document record |
| T1.12 | Write MVP tests | 80% code coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Sign document | `sign test.pdf --type cert` | Creates QR, shows DOC-ID |
| Verify valid | `verify "qr-doc://v1/DOC-x|hash"` | "VERIFIED" |
| Verify tampered | Modified document | "FAILED: Hash mismatch" |
| Verify unknown | Non-existent ID | "UNKNOWN: Not in registry" |
| Show document | `show DOC-abc123` | Displays all fields |
| Hash consistency | Same file twice | Same hash |
| QR format | Generated QR data | Matches spec |

### MVP Command Specification

```bash
# Sign document
qr-doc sign document.pdf --type certificate --issuer "ACME Corp"
# Output: Signed document.pdf
#         Document ID: DOC-7f3d2a1b
#         Hash: a1b2c3d4e5f67890a1b2c3d4e5f67890
#         QR saved to: document.pdf.qr.pbm

# Verify from QR data (scanned or copied)
qr-doc verify "qr-doc://v1/DOC-7f3d2a1b|a1b2c3d4e5f67890a1b2c3d4e5f67890"
# Output: VERIFIED
#         Type: certificate
#         Issuer: ACME Corp
#         Issued: 2026-01-24T10:30:00Z

# Show document details
qr-doc show DOC-7f3d2a1b
# Output: Document ID: DOC-7f3d2a1b
#         Type: certificate
#         Issuer: ACME Corp
#         Status: active
#         Issued: 2026-01-24T10:30:00Z
#         Hash: a1b2c3d4e5f67890a1b2c3d4e5f67890
```

---

## Phase 2: Full Implementation

### Objective

Add revocation, expiration, batch operations, export, and full registry management. This delivers production-ready features.

### Deliverables

1. **Revocation support** - Mark documents as revoked
2. **Expiration support** - Validity periods
3. **Batch signing** - Sign multiple documents
4. **Export/Import** - JSON registry export
5. **List command** - Query documents
6. **Config management** - JSON configuration

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Add revocation to registry | revoke command works |
| T2.2 | Add expiration checking | Expired docs detected |
| T2.3 | Implement `revoke` command | Marks doc as revoked |
| T2.4 | Implement `list` command | Filters by type/issuer/status |
| T2.5 | Implement EXPORT_ENGINE | JSON export |
| T2.6 | Implement `export` command | Full and public export |
| T2.7 | Implement `import` command | Import from JSON |
| T2.8 | Implement batch signing | Directory processing |
| T2.9 | Implement CONFIG class | JSON config loading |
| T2.10 | Implement `config` command | View/set config |
| T2.11 | Add metadata support | Custom fields |
| T2.12 | Verification logging | Track all verifications |
| T2.13 | Write comprehensive tests | 90% coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Revoke document | `revoke DOC-x --reason "Error"` | Status changed |
| Verify revoked | Revoked doc QR | "REVOKED: Error" |
| Set expiration | `sign doc --expires 2027-01-01` | Expires field set |
| Verify expired | Expired doc QR | "EXPIRED" |
| List by type | `list --type diploma` | Matching docs |
| Export JSON | `export --output reg.json` | Valid JSON file |
| Export public | `export --public` | Limited fields |
| Import registry | `import backup.json` | Records imported |
| Batch sign | `sign docs/ --type cert` | All docs signed |
| Custom metadata | `sign doc --metadata employee=John` | Metadata stored |

### Revocation Workflow

```bash
# Revoke document
qr-doc revoke DOC-7f3d2a1b --reason "Issued in error"
# Output: Revoked DOC-7f3d2a1b
#         Reason: Issued in error
#         Revoked at: 2026-01-24T14:30:00Z

# Subsequent verification
qr-doc verify "qr-doc://v1/DOC-7f3d2a1b|..."
# Output: REVOKED
#         Reason: Issued in error
#         Revoked: 2026-01-24T14:30:00Z
```

---

## Phase 3: Production Polish

### Objective

Harden for production with error handling, performance, documentation, and Professional features preview.

### Deliverables

1. **Error handling** - All edge cases covered
2. **Performance optimization** - Large files, batches
3. **Help system** - Built-in help
4. **Documentation** - User guide
5. **Professional preview** - PDF embedding stub

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Comprehensive error messages | Clear guidance |
| T3.2 | Large file handling | Stream hashing |
| T3.3 | Batch performance | 100 docs in 10s |
| T3.4 | Built-in help | All commands |
| T3.5 | README with examples | Quick start |
| T3.6 | Finalize contracts | 100% coverage |
| T3.7 | Integration tests | E2E scenarios |
| T3.8 | PDF embedding stub | For Professional |
| T3.9 | Release build | Finalized binary |
| T3.10 | Security review | Hash, storage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Large file (100MB) | Sign large file | Completes < 5s |
| Batch (100 files) | Sign directory | Completes < 15s |
| Unicode filename | Non-ASCII path | Handles correctly |
| Empty file | Sign empty file | Valid hash |
| Binary file | Sign binary | Valid hash |
| Concurrent verify | Parallel requests | All succeed |
| Registry corruption | Damaged DB | Graceful error |

---

## ECF Target Structure

```xml
<!-- Library target -->
<target name="qr_doc_signer">
    <root class="QR_DOC_CLI" feature="make"/>
    <cluster name="src" location="./src/" recursive="true"/>
    <!-- Libraries -->
</target>

<!-- CLI executable -->
<target name="qr_doc_signer_cli" extends="qr_doc_signer">
    <root class="QR_DOC_CLI" feature="make"/>
    <setting name="executable_name" value="qr-doc"/>
</target>

<!-- Tests -->
<target name="qr_doc_signer_tests" extends="qr_doc_signer">
    <root class="TEST_APP" feature="make"/>
    <cluster name="testing" location="./testing/"/>
    <library name="simple_testing" location="..."/>
</target>
```

---

## Build Commands

```bash
# Set environment
export SIMPLE_EIFFEL=/d/prod

# Compile CLI
/d/prod/ec.sh -batch -config qr_doc_signer.ecf -target qr_doc_signer_cli -c_compile

# Run CLI
./EIFGENs/qr_doc_signer_cli/W_code/qr-doc.exe --help

# Run tests
/d/prod/ec.sh -batch -config qr_doc_signer.ecf -target qr_doc_signer_tests -c_compile
./EIFGENs/qr_doc_signer_tests/W_code/qr-doc.exe

# Production build
/d/prod/ec.sh -batch -config qr_doc_signer.ecf -target qr_doc_signer_cli -finalize -c_compile
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Hash correctness | SHA-256 verification | Matches OpenSSL |
| Performance | 100 docs batch | < 15 seconds |
| Documentation | README complete | Yes |
| Security | Hash truncation | 128-bit security |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| simple_hash API | Low | Medium | Check API first |
| Large file memory | Medium | Medium | Stream hashing |
| QR capacity limit | Low | Low | Truncation designed for this |
| PDF integration | High | Medium | Defer to Professional |

---

## Post-Launch Roadmap

### Version 1.1
- Verification statistics dashboard
- Multi-issuer support
- API mode for integration

### Version 1.2 (Professional)
- PDF embedding
- Batch PDF processing
- Template-based embedding

### Version 2.0 (Enterprise)
- Multi-signature support
- HSM integration
- PKI digital signatures
