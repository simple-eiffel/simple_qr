# Marketplace Research: simple_qr

**Generated:** 2026-01-24
**Library:** simple_qr
**Status:** Production Ready (64 tests passing)

---

## Library Profile

### Core Capabilities

| Capability | Description | Business Value |
|------------|-------------|----------------|
| QR Code Generation | Encode text/URLs to QR matrix | Enable machine-readable data on any medium |
| All 40 Versions | 21x21 to 177x177 modules | Support data from 7 chars to 4,296 bytes |
| Four EC Levels | L/M/Q/H (7-30% recovery) | Balance capacity vs. damage tolerance |
| Auto Mode Detection | Numeric, alphanumeric, byte | Optimal encoding without manual config |
| Auto Version Selection | Smallest version for data | Minimize QR size, maximize scannability |
| Reed-Solomon EC | GF(2^8) arithmetic | Industrial-grade error correction |
| ASCII Art Output | Terminal-friendly rendering | CLI tools, terminal displays |
| PBM Image Output | Portable bitmap format | Print-ready, convertible to PNG/PDF |

### API Surface

| Feature | Type | Use Case |
|---------|------|----------|
| `set_data` | Command | Set text/URL to encode |
| `set_error_correction` | Command | Choose L/M/Q/H level |
| `set_version` | Command | Force specific version (1-40) |
| `generate` | Command | Build QR matrix |
| `is_generated` | Query | Check generation success |
| `has_error` | Query | Check for errors |
| `module_count` | Query | Get QR size (21-177) |
| `is_dark_module` | Query | Read individual module |
| `to_ascii_art` | Query | Get terminal rendering |
| `to_pbm` | Query | Get image format |
| `save_pbm` | Command | Write to file |

### Existing Dependencies

| simple_* Library | Purpose in this library |
|------------------|------------------------|
| simple_file | File I/O for save_pbm |

### Integration Points

- **Input formats:** Plain text, URLs, any UTF-8 string
- **Output formats:** ASCII art (terminal), PBM image
- **Data flow:** Text -> Encoder -> EC Generator -> Matrix -> Mask -> Output

---

## Marketplace Analysis

### Industry Applications

| Industry | Application | Pain Point Solved |
|----------|-------------|-------------------|
| Logistics | Asset/inventory tracking | Manual data entry errors, slow lookup |
| Manufacturing | Product serialization | Counterfeit prevention, recall traceability |
| Healthcare | Patient wristbands, medication tracking | Wrong-patient errors, compliance |
| Events | Ticketing, access control | Fraud, slow check-in, no real-time data |
| Finance | Payment verification, 2FA | Phishing, credential theft |
| Retail | Product authentication | Counterfeits, gray market diversion |
| Document Management | Certificate verification | Forgery, manual verification burden |
| IT/DevOps | Server asset tracking | Lost equipment, audit failures |

### Commercial Products (Competitors/Inspirations)

| Product | Price Point | Key Features | Gap We Could Fill |
|---------|-------------|--------------|-------------------|
| [Uniqode](https://www.uniqode.com) | Enterprise pricing | CRM integration, bulk generation, analytics | CLI-first batch generation |
| [QR TIGER Enterprise](https://enterprise.qrcode-tiger.com/) | $50-200/mo | Dynamic QR, tracking, bulk export | Offline, local-first solution |
| [GoCodes](https://gocodes.com) | $1,000/year | Asset tracking, mobile scanning | Self-hosted, no cloud dependency |
| [QRBatch](https://qrbatch.com) | Free tier + credits | Bulk generation, multiple formats | Programmable CLI automation |
| [QR Factory](https://www.tunabellysoftware.com/qrfactory/) | $9.99 one-time | Mac/iPad, batch CSV, verification | Cross-platform CLI, Windows |
| [Scantrust](https://www.scantrust.com) | Enterprise | Serialization, anti-counterfeit | Self-contained, no cloud |
| [EZOfficeInventory](https://ezo.io) | $40-160/mo | Full asset management | Lightweight CLI generation only |

### Workflow Integration Points

| Workflow | Where simple_qr Fits | Value Added |
|----------|----------------------|-------------|
| CI/CD Pipeline | Auto-generate deployment QR codes | Link mobile testers to builds |
| Asset Onboarding | Batch generate asset labels | Eliminate manual label printing |
| Event Setup | Generate ticket batch from CSV | No cloud dependency, air-gapped |
| Document Signing | Embed verification QR | Offline verification capability |
| Manufacturing Line | Serialize production runs | Local generation, no network needed |
| Inventory Audit | Generate audit trail QR codes | Link physical to digital records |

### Target User Personas

| Persona | Role | Need | Willingness to Pay |
|---------|------|------|-------------------|
| **DevOps Dan** | SRE/DevOps Engineer | Generate QR codes in CI/CD, no cloud | HIGH - saves manual work |
| **Warehouse Wendy** | Inventory Manager | Batch label generation for assets | HIGH - reduces data entry |
| **Compliance Carl** | IT Compliance Officer | Audit-ready asset tracking | HIGH - avoids penalties |
| **Event Ella** | Event Coordinator | Ticket generation without SaaS | MEDIUM - cost savings |
| **Doc Diana** | Document Controller | Verification codes on certificates | HIGH - fraud prevention |
| **Manufacturing Mike** | Production Manager | Serialize product runs | HIGH - regulatory compliance |

---

## Mock App Candidates

### Candidate 1: QR-ASSET-TRACKER

**One-liner:** CLI tool for generating and managing QR code asset labels with batch processing and audit trail.

**Target market:** IT departments, facilities management, warehouse operations

**Revenue model:**
- Open source core + commercial support
- Enterprise license with extended features ($500-2000/year)

**Ecosystem leverage:**
- simple_qr (QR generation)
- simple_csv (batch import/export)
- simple_json (configuration, export)
- simple_file (file operations)
- simple_sql (SQLite asset database)
- simple_datetime (timestamps)
- simple_uuid (unique asset IDs)

**CLI-first value:**
- Script asset onboarding workflows
- Integrate with existing inventory systems
- Run headless on servers
- Pipe to label printers

**GUI/TUI potential:**
- Asset browser with QR preview
- Batch selection interface
- Print queue management

**Viability:** HIGH - Clear pain point, measurable ROI

---

### Candidate 2: QR-DOC-SIGNER

**One-liner:** CLI tool for embedding verification QR codes in documents with cryptographic signing.

**Target market:** Legal departments, HR, certificate issuers, educational institutions

**Revenue model:**
- Per-seat licensing ($50-100/user/year)
- Volume license for enterprises ($2000-5000/year)

**Ecosystem leverage:**
- simple_qr (QR generation)
- simple_hash (document hashing)
- simple_json (metadata)
- simple_file (document handling)
- simple_datetime (timestamps, validity periods)
- simple_uuid (document IDs)
- simple_pdf (PDF integration)

**CLI-first value:**
- Batch sign document directories
- Integrate with document management systems
- Automate certificate issuance
- Offline verification capability

**GUI/TUI potential:**
- Document preview with QR placement
- Signature verification dashboard
- Certificate template designer

**Viability:** HIGH - Strong compliance driver, growing demand for document authenticity

---

### Candidate 3: QR-TICKET-GATE

**One-liner:** CLI tool for generating, validating, and managing event tickets with QR codes and offline capability.

**Target market:** Event organizers, venues, conference managers, membership organizations

**Revenue model:**
- Per-event licensing ($100-500/event)
- Annual unlimited ($1000-3000/year)
- White-label/embedded licensing

**Ecosystem leverage:**
- simple_qr (QR generation)
- simple_sql (ticket database)
- simple_json (configuration, export)
- simple_csv (attendee import/export)
- simple_datetime (event times, validity)
- simple_uuid (ticket IDs)
- simple_hash (ticket integrity)
- simple_encryption (secure ticket data)

**CLI-first value:**
- Batch ticket generation from CSV
- Offline validation (air-gapped events)
- Integration with registration systems
- Real-time check-in statistics

**GUI/TUI potential:**
- Check-in kiosk interface
- Real-time attendance dashboard
- Ticket scanner mobile companion

**Viability:** HIGH - Events industry recovering, need for flexible solutions

---

## Selection Rationale

All three candidates were selected because they:

1. **Solve Real Business Problems** - Each addresses a documented pain point with measurable ROI
2. **Have Clear Market Value** - Commercial products exist in each space, proving demand
3. **Leverage Multiple Libraries** - Each uses 6+ simple_* libraries, showcasing ecosystem
4. **Are CLI-First Appropriate** - All workflows benefit from automation and scripting
5. **Support Future UI** - Each has natural GUI/TUI evolution path
6. **Differentiate on Architecture** - Local-first, no cloud dependency is unique positioning

The three apps cover different verticals (IT/operations, legal/compliance, events) while sharing common patterns (batch generation, validation, reporting) that could become shared components.

---

## Research Sources

### QR Code Business Tools
- [CaoLiao QR Code CLI](https://cli.im/en/)
- [Segno CLI Documentation](https://segno.readthedocs.io/en/latest/command-line.html)
- [qrencode CLI Tool](https://www.x-cmd.com/pkg/qrencode/)

### Enterprise Platforms
- [Uniqode Enterprise](https://www.uniqode.com)
- [QR TIGER Enterprise](https://enterprise.qrcode-tiger.com/)
- [Best Enterprise QR Code Generators 2026](https://northpennnow.com/news/2025/nov/26/best-qr-code-generators-with-crm-integration-enterprise-platforms-ranked-2026/)

### Asset Tracking
- [UpKeep QR Codes](https://upkeep.com/qr-codes/)
- [GoCodes Inventory Tracking](https://gocodes.com/solution/inventory-tracking/)
- [EZOfficeInventory QR Tracking](https://ezo.io/ezofficeinventory/solutions/qrcode-asset-tracking-software/)
- [QR Inventory Management Guide](https://www.qr-code-generator.com/blog/qr-code-inventory-management/)

### Batch Generation
- [QRBatch Bulk Generator](https://qrbatch.com/)
- [Uniqode Bulk QR API](https://www.uniqode.com/blog/qr-code-for-teams/batch-qr-code-api)
- [QR Factory for macOS](https://www.tunabellysoftware.com/qrfactory/)

### Document Authentication
- [Diplomasafe QR Verification](https://diplomasafe.com/qr-code-verification/)
- [QR Code Authentication Security](https://www.qrcode-tiger.com/qr-code-authentication)
- [Two-Factor Authentication with QR Codes (IEEE)](https://ieeexplore.ieee.org/document/6982784)

### Product Serialization
- [Scantrust Serialized QR Codes](https://www.scantrust.com/serialized-qr-codes/)
- [Securikett QR Serialization](https://www.securikett.com/qr-codes-and-serialization/)
- [QR Code Supply Chain Traceability](https://www.qrstuff.com/blog/general/traceability-qr-codes/)

### Event Ticketing
- [Magnetiq Event Tickets](https://www.magnetiq.io/en/tickets/)
- [QR Code Event Ticketing Guide](https://godreamcast.com/blog/solution/event-registration/qr-code-event-ticketing/)
- [QR Code Check-In Systems](https://passkit.com/blog/qr-code-check-in-system/)
