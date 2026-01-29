# QR-ASSET-TRACKER - Build Plan

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 3-4 days | simple_qr, simple_sql, simple_uuid |
| Phase 2 | Full CLI | 3-4 days | Phase 1 + simple_csv, simple_json |
| Phase 3 | Polish | 2-3 days | Phase 2 complete |

**Total Estimated Effort:** 8-11 days

---

## Phase 1: MVP (Minimum Viable Product)

### Objective

Deliver a working CLI that can register assets, generate QR labels, and store data in SQLite. This proves the core value proposition: offline QR asset tracking.

### Deliverables

1. **ASSET class** - Asset entity with core attributes
2. **ASSET_REPOSITORY class** - SQLite persistence
3. **LABEL_GENERATOR class** - QR code generation
4. **QR_ASSET_CLI class** - Basic CLI interface
5. **Basic commands:** register, show, list, labels

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure | ECF compiles, directories exist |
| T1.2 | Implement ASSET class | Attributes, validation, contracts |
| T1.3 | Implement ASSET_REPOSITORY | SQLite schema, save/load/query |
| T1.4 | Implement LABEL_GENERATOR | Single and batch label generation |
| T1.5 | Implement CLI skeleton | Argument parsing, command routing |
| T1.6 | Implement `register` command | Creates asset, generates ID |
| T1.7 | Implement `show` command | Displays asset details |
| T1.8 | Implement `list` command | Lists assets with basic filter |
| T1.9 | Implement `labels` command | Generates PBM files |
| T1.10 | Write MVP tests | 80% code coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Register asset | `register --name "Laptop" --type laptop` | Success, shows asset ID |
| Show asset | `show ASSET-abc123` | Displays all asset fields |
| List by type | `list --type laptop` | Lists matching assets |
| Generate label | `labels ASSET-abc123` | Creates PBM file |
| Batch labels | `labels --batch --type laptop` | Creates multiple PBM files |
| Invalid ID | `show INVALID-ID` | Error: "Asset not found" |
| Empty database | `list` | "No assets found" |

### MVP Command Specification

```bash
# Register asset
qr-asset register --name "Dell Laptop" --type laptop [--serial XYZ123]
# Output: Created asset ASSET-7f3d2a1b

# Show asset
qr-asset show ASSET-7f3d2a1b
# Output: ID: ASSET-7f3d2a1b
#         Name: Dell Laptop
#         Type: laptop
#         Serial: XYZ123
#         Created: 2026-01-24T10:30:00Z

# List assets
qr-asset list [--type TYPE]
# Output: ASSET-7f3d2a1b  laptop    Dell Laptop
#         ASSET-8e4c3b2a  laptop    HP ProBook
#         2 assets found

# Generate label
qr-asset labels ASSET-7f3d2a1b [--output DIR]
# Output: Generated: labels/ASSET-7f3d2a1b.pbm

# Batch labels
qr-asset labels --batch --type laptop [--output DIR]
# Output: Generated 2 labels in labels/
```

---

## Phase 2: Full Implementation

### Objective

Add import/export, locations, owners, events, and auditing. This delivers the complete feature set for production use.

### Deliverables

1. **IMPORT_EXPORT class** - CSV import/export
2. **LOCATION class** - Hierarchical locations
3. **ASSET_EVENT class** - Audit trail events
4. **AUDIT_ENGINE class** - Audit operations
5. **CONFIG class** - JSON configuration
6. **Extended commands:** import, export, assign, transfer, log, audit, config

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement LOCATION class | Hierarchical structure, path |
| T2.2 | Add location to ASSET | Foreign key, queries |
| T2.3 | Implement IMPORT_EXPORT | CSV import with validation |
| T2.4 | Implement ASSET_EVENT | Event types, timestamps |
| T2.5 | Implement AUDIT_ENGINE | Start, verify, complete, report |
| T2.6 | Implement CONFIG | JSON loading, defaults |
| T2.7 | Implement `import` command | CSV to assets |
| T2.8 | Implement `export` command | Assets to CSV |
| T2.9 | Implement `assign` command | Set owner |
| T2.10 | Implement `transfer` command | Change location |
| T2.11 | Implement `log` command | Add event |
| T2.12 | Implement `audit` subcommands | start, verify, complete, report |
| T2.13 | Implement `config` command | View/set configuration |
| T2.14 | Add JSON output format | --output json |
| T2.15 | Write comprehensive tests | 90% coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Import CSV | `import assets.csv --type laptop` | "Imported 50 assets" |
| Import invalid | `import bad.csv` | Error with row numbers |
| Export CSV | `export --type laptop --output out.csv` | Creates valid CSV |
| Assign owner | `assign ASSET-x --owner jane@co.com` | Updates owner, logs event |
| Transfer location | `transfer ASSET-x --location "Floor 2"` | Updates location, logs event |
| Log event | `log ASSET-x --event maintenance` | Creates event record |
| Start audit | `audit start --location "Building A"` | Creates audit, shows ID |
| Verify asset | `audit verify ASSET-x --audit AUDIT-y` | Records verification |
| Audit report | `audit report AUDIT-y` | Shows verified/missing/unverified |

### CSV Format Specification

```csv
name,serial_number,type,location,owner,purchase_date,purchase_price,notes
"Dell Laptop","XYZ123","laptop","IT Storage","","2026-01-15",1200.00,"New shipment"
"HP Monitor","ABC456","monitor","Floor 2/Room 201","jane@company.com","2025-06-01",350.00,""
```

---

## Phase 3: Production Polish

### Objective

Harden for production use with error handling, performance optimization, documentation, and release packaging.

### Deliverables

1. **Error handling hardening** - All edge cases covered
2. **Performance optimization** - Batch operations, indexes
3. **Help system** - Built-in help for all commands
4. **README and documentation** - User guide, examples
5. **Release packaging** - Finalized build, installer

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Comprehensive error messages | All errors have clear messages |
| T3.2 | Input validation | All inputs validated |
| T3.3 | Performance testing | 1000 labels in 30s |
| T3.4 | Database indexes | All queries < 100ms |
| T3.5 | Built-in help | `--help` for all commands |
| T3.6 | Man page / usage docs | Complete command reference |
| T3.7 | README with examples | Quick start guide |
| T3.8 | Finalize contracts | All features have contracts |
| T3.9 | Release build | Finalized binary |
| T3.10 | Integration tests | End-to-end scenarios |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Help command | `qr-asset --help` | Shows all commands |
| Command help | `qr-asset register --help` | Shows register options |
| Large import | 1000 row CSV | Completes in < 10s |
| Large batch | 1000 assets | Labels in < 30s |
| Unicode names | Asset with emoji/unicode | Handles correctly |
| Long serial | 100-char serial number | Stores and displays |
| Invalid EC level | `--ec-level X` | Error: "Invalid level" |

---

## ECF Target Structure

```xml
<!-- Library target (reusable) -->
<target name="qr_asset_tracker">
    <root class="QR_ASSET_CLI" feature="make"/>
    <cluster name="src" location="./src/" recursive="true"/>
    <!-- Libraries -->
</target>

<!-- CLI executable target -->
<target name="qr_asset_tracker_cli" extends="qr_asset_tracker">
    <root class="QR_ASSET_CLI" feature="make"/>
    <setting name="executable_name" value="qr-asset"/>
</target>

<!-- Test target -->
<target name="qr_asset_tracker_tests" extends="qr_asset_tracker">
    <root class="TEST_APP" feature="make"/>
    <cluster name="testing" location="./testing/" recursive="true"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
</target>
```

---

## Build Commands

```bash
# Set environment
export SIMPLE_EIFFEL=/d/prod

# Compile CLI (workbench mode for development)
/d/prod/ec.sh -batch -config qr_asset_tracker.ecf -target qr_asset_tracker_cli -c_compile

# Run CLI
./EIFGENs/qr_asset_tracker_cli/W_code/qr-asset.exe --help

# Compile and run tests
/d/prod/ec.sh -batch -config qr_asset_tracker.ecf -target qr_asset_tracker_tests -c_compile
./EIFGENs/qr_asset_tracker_tests/W_code/qr-asset.exe

# Finalized build (production)
/d/prod/ec.sh -batch -config qr_asset_tracker.ecf -target qr_asset_tracker_cli -finalize -c_compile
./EIFGENs/qr_asset_tracker_cli/F_code/qr-asset.exe --version
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors/warnings | 100% |
| Tests pass | All test cases | 100% |
| CLI works | All commands functional | 100% |
| Performance | 1000 labels generation | < 30 seconds |
| Documentation | README complete | Yes |
| Contracts | All public features | 100% coverage |
| Error handling | All error paths | Tested |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| simple_sql API differences | Low | Medium | Read simple_sql docs first |
| PBM to PNG conversion | Medium | Low | Document external tools (ImageMagick) |
| Large batch memory | Medium | Medium | Stream processing, chunking |
| Unicode in QR content | Low | Low | Test with various inputs |

---

## Post-Launch Roadmap

### Version 1.1
- PNG output via simple_image (when available)
- Label templates (custom sizes)
- Batch print sheets (multiple per page)

### Version 1.2
- Multi-database support
- Sync between databases
- Conflict resolution

### Version 2.0 (Professional)
- PDF reports
- Depreciation tracking
- Maintenance scheduling
- API mode for integration
