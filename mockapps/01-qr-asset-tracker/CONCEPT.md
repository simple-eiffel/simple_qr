# QR-ASSET-TRACKER

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Executive Summary

QR-ASSET-TRACKER is a command-line tool for generating, managing, and auditing QR code asset labels. It enables IT departments, facilities management, and warehouse operations to create batches of QR code labels from CSV data, track asset lifecycle events, and generate audit reports.

The tool operates entirely offline with a local SQLite database, making it suitable for air-gapped environments and organizations that cannot use cloud-based asset tracking services. Assets are identified by unique QR codes that link to comprehensive metadata including location, owner, purchase date, and maintenance history.

Unlike SaaS alternatives that charge per-asset or monthly fees, QR-ASSET-TRACKER is a one-time purchase with no ongoing costs. Organizations retain full control of their asset data with no vendor lock-in.

---

## Problem Statement

**The problem:** Organizations struggle to track physical assets accurately. Manual spreadsheets become outdated, asset labels get lost or damaged, and audits require significant manual effort. IT equipment, furniture, tools, and vehicles represent significant capital investments that are poorly tracked.

**Current solutions:**
- Enterprise asset management suites (ServiceNow, BMC) - expensive, complex
- Cloud SaaS (GoCodes, UpKeep) - ongoing costs, data sovereignty concerns
- Manual spreadsheets - error-prone, no physical linkage
- Generic barcode labels - limited data capacity, no error correction

**Our approach:** A self-contained CLI tool that generates QR code labels with embedded asset IDs, stores asset metadata locally in SQLite, and provides batch operations for onboarding, auditing, and reporting. QR codes provide high data density and error correction for damaged labels.

---

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| **Primary: IT Asset Manager** | Manages laptops, servers, monitors, phones | Batch label generation, assignment tracking, depreciation |
| **Primary: Facilities Manager** | Tracks furniture, HVAC, fixtures | Location-based tracking, maintenance scheduling |
| **Secondary: Warehouse Supervisor** | Inventory and equipment tracking | Bulk import, location zones, checkout/return |
| **Secondary: DevOps Engineer** | Server rack and hardware management | Scripted workflows, CI/CD integration |

---

## Value Proposition

**For** IT asset managers and facilities teams
**Who** need to track physical assets accurately
**This app** provides offline QR code label generation with local database
**Unlike** cloud SaaS tools or enterprise suites
**We** require no ongoing fees, internet connection, or vendor dependency

---

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| **Open Source Core** | Basic generation and tracking | Free (MIT license) |
| **Professional License** | Extended reporting, multi-location, export formats | $500/year |
| **Enterprise License** | API access, custom integrations, priority support | $2,000/year |
| **Support Contract** | Installation, training, customization | $150/hour |

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to generate 1000 labels | < 30 seconds | CLI timing |
| Label scan success rate | > 99% at all EC levels | Verification tests |
| Data import accuracy | 100% from valid CSV | Automated tests |
| Audit report generation | < 5 seconds for 10K assets | CLI timing |
| User onboarding time | < 1 hour to first batch | Documentation + trials |

---

## Feature Set

### Core Features (Open Source)

1. **Asset Registration**
   - Register assets with metadata (name, type, location, owner)
   - Auto-generate unique asset IDs (UUID)
   - Import assets from CSV

2. **QR Label Generation**
   - Generate individual or batch labels
   - Choose error correction level
   - Output to PBM, with conversion to PNG/PDF

3. **Asset Lookup**
   - Query by asset ID, type, location, owner
   - Display full asset metadata
   - Show asset history

4. **Basic Reporting**
   - Asset count by type/location
   - Recently added assets
   - Assets by owner

### Professional Features

5. **Advanced Reporting**
   - Depreciation tracking
   - Maintenance schedules
   - Checkout/return history
   - Export to CSV, JSON, PDF

6. **Multi-Location**
   - Hierarchical locations (building/floor/room)
   - Location-based queries
   - Transfer tracking

7. **Audit Trail**
   - Full history of all changes
   - Audit report generation
   - Compliance exports

### Enterprise Features

8. **API Mode**
   - JSON API for integration
   - Webhook notifications
   - Bulk operations

9. **Custom Fields**
   - User-defined metadata fields
   - Field validation rules
   - Custom report templates

---

## Use Cases

### UC1: Onboard New IT Equipment

```
1. Receive shipment of 50 laptops
2. Create CSV with serial numbers, models, purchase info
3. Run: qr-asset import laptops.csv --type laptop --location "IT Storage"
4. Run: qr-asset labels --batch --type laptop --output labels.pbm
5. Print labels, apply to laptops
6. Laptops now trackable in system
```

### UC2: Assign Asset to Employee

```
1. Scan laptop QR code or enter asset ID
2. Run: qr-asset assign ASSET-123 --owner "jane.doe@company.com"
3. Record checkout date, expected return (if applicable)
4. Asset now linked to employee
```

### UC3: Annual IT Audit

```
1. Run: qr-asset audit --location "Building A" --output audit-2026.csv
2. Walk through building with scanner
3. Scan each asset, system records verification
4. Run: qr-asset audit-report 2026 --format pdf
5. Report shows verified, missing, unverified assets
```

### UC4: Equipment Maintenance

```
1. Scan equipment QR code
2. Run: qr-asset log ASSET-456 --event maintenance --note "Replaced filter"
3. Maintenance event recorded with timestamp
4. Run: qr-asset next-maintenance --days 30
5. Shows assets due for maintenance in next 30 days
```
