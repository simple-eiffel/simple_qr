# QR-ASSET-TRACKER - Technical Design

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                       QR-ASSET-TRACKER                            |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (command, subcommand, flags)                |
|    - Input validation                                             |
|    - Output formatting (text, JSON, CSV)                          |
+------------------------------------------------------------------+
|  Business Logic Layer                                             |
|    - ASSET_MANAGER: Asset CRUD operations                         |
|    - LABEL_GENERATOR: QR code batch generation                    |
|    - AUDIT_ENGINE: Verification and reporting                     |
|    - IMPORT_EXPORT: CSV/JSON data handling                        |
+------------------------------------------------------------------+
|  Data Layer                                                       |
|    - ASSET_REPOSITORY: SQLite persistence                         |
|    - LOCATION_TREE: Hierarchical locations                        |
|    - EVENT_LOG: Audit trail storage                               |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_qr: QR code generation                                |
|    - simple_sql: SQLite database                                  |
|    - simple_csv: CSV import/export                                |
|    - simple_json: JSON configuration and output                   |
|    - simple_file: File operations                                 |
|    - simple_uuid: Unique identifiers                              |
|    - simple_datetime: Timestamps                                  |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `QR_ASSET_CLI` | Command-line interface | parse_args, route_command, format_output |
| `ASSET_MANAGER` | Core asset operations | register, update, delete, find, assign |
| `ASSET` | Asset entity | id, name, type, location, owner, metadata |
| `LABEL_GENERATOR` | QR code production | generate_single, generate_batch, save_labels |
| `AUDIT_ENGINE` | Audit operations | start_audit, verify_asset, generate_report |
| `IMPORT_EXPORT` | Data transfer | import_csv, export_csv, export_json |
| `ASSET_REPOSITORY` | Database operations | save, load, query, delete |
| `LOCATION` | Location entity | id, name, parent, path |
| `ASSET_EVENT` | Audit event | asset_id, event_type, timestamp, details |
| `CONFIG` | Configuration | database_path, default_ec_level, output_dir |

### Command Structure

```bash
qr-asset <command> [subcommand] [options] [arguments]

Commands:
  register    Register a new asset
  import      Import assets from CSV
  list        List assets with filters
  show        Show asset details
  update      Update asset metadata
  delete      Delete an asset
  assign      Assign asset to owner
  transfer    Transfer asset to location
  labels      Generate QR code labels
  audit       Audit operations
  report      Generate reports
  log         Log asset event
  config      Manage configuration
  help        Show help

Examples:
  qr-asset register --name "Dell Laptop" --type laptop --serial XYZ123
  qr-asset import assets.csv --type equipment
  qr-asset list --type laptop --location "Building A"
  qr-asset labels --batch --type laptop --output labels/
  qr-asset audit start --location "Floor 2"
  qr-asset report inventory --format pdf --output report.pdf

Global Options:
  --config FILE      Configuration file (default: ~/.qr-asset/config.json)
  --database FILE    Database file (default: ~/.qr-asset/assets.db)
  --output FORMAT    Output format: text, json, csv (default: text)
  --quiet            Suppress non-essential output
  --verbose          Verbose output
  --help             Show help for command
  --version          Show version
```

### Data Flow

```
                    +-------------+
                    |   CSV/JSON  |
                    |   Import    |
                    +------+------+
                           |
                           v
+----------+        +-------------+        +-----------+
|  CLI     | -----> |   ASSET     | -----> | SQLite    |
|  Input   |        |   MANAGER   |        | Database  |
+----------+        +------+------+        +-----------+
                           |
                           v
                    +-------------+
                    |   LABEL     |
                    |   GENERATOR |
                    +------+------+
                           |
                           v
                    +-------------+
                    |  simple_qr  |
                    +------+------+
                           |
                           v
                    +-------------+
                    |  PBM/ASCII  |
                    |   Output    |
                    +-------------+
```

### Database Schema

```sql
-- Assets table
CREATE TABLE assets (
    id TEXT PRIMARY KEY,           -- UUID
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    serial_number TEXT,
    location_id TEXT,
    owner TEXT,
    purchase_date TEXT,
    purchase_price REAL,
    warranty_expires TEXT,
    status TEXT DEFAULT 'active',  -- active, retired, lost, maintenance
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    metadata TEXT,                 -- JSON for custom fields
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

-- Locations table (hierarchical)
CREATE TABLE locations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id TEXT,
    path TEXT NOT NULL,            -- "Building A/Floor 2/Room 201"
    FOREIGN KEY (parent_id) REFERENCES locations(id)
);

-- Asset events (audit trail)
CREATE TABLE asset_events (
    id TEXT PRIMARY KEY,
    asset_id TEXT NOT NULL,
    event_type TEXT NOT NULL,      -- created, updated, assigned, transferred, verified, retired
    timestamp TEXT NOT NULL,
    actor TEXT,                    -- who performed action
    details TEXT,                  -- JSON with event-specific data
    FOREIGN KEY (asset_id) REFERENCES assets(id)
);

-- Audits table
CREATE TABLE audits (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location_id TEXT,
    started_at TEXT NOT NULL,
    completed_at TEXT,
    status TEXT DEFAULT 'in_progress',
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

-- Audit verifications
CREATE TABLE audit_verifications (
    audit_id TEXT NOT NULL,
    asset_id TEXT NOT NULL,
    verified_at TEXT NOT NULL,
    verified_by TEXT,
    notes TEXT,
    PRIMARY KEY (audit_id, asset_id),
    FOREIGN KEY (audit_id) REFERENCES audits(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id)
);

-- Indexes
CREATE INDEX idx_assets_type ON assets(type);
CREATE INDEX idx_assets_location ON assets(location_id);
CREATE INDEX idx_assets_owner ON assets(owner);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_events_asset ON asset_events(asset_id);
CREATE INDEX idx_events_type ON asset_events(event_type);
```

### Configuration Schema

```json
{
  "qr_asset": {
    "database": {
      "path": "~/.qr-asset/assets.db"
    },
    "labels": {
      "error_correction": "M",
      "output_format": "pbm",
      "output_directory": "./labels",
      "quiet_zone": 4,
      "scale": 10
    },
    "import": {
      "default_type": "equipment",
      "default_status": "active"
    },
    "export": {
      "date_format": "YYYY-MM-DD",
      "include_metadata": true
    },
    "audit": {
      "auto_create_events": true,
      "require_notes": false
    }
  }
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Asset not found | Return error code 1 | "Asset not found: {id}" |
| Duplicate serial | Reject, suggest update | "Serial number already exists on asset {id}" |
| Invalid CSV format | Skip row, report | "Row {n}: Invalid format - {details}" |
| Database error | Abort, preserve data | "Database error: {message}. No changes made." |
| QR generation failure | Report, continue batch | "Warning: Could not generate label for {id}" |
| Invalid location | Suggest similar | "Location not found. Did you mean: {suggestions}" |
| Permission denied | Check file access | "Cannot write to {path}. Check permissions." |

---

## GUI/TUI Future Path

**CLI foundation enables:**

### TUI Extension
- Asset browser with filtering and sorting
- QR preview in terminal (Unicode block characters)
- Interactive audit mode with scan simulation
- Dashboard with asset statistics

### GUI Extension
- Asset management interface with QR preview
- Drag-and-drop CSV import
- Label sheet designer for printing
- Floor plan visualization with asset positions
- Mobile companion app for scanning

### Shared Components
- All business logic in ASSET_MANAGER, LABEL_GENERATOR, AUDIT_ENGINE
- Database layer unchanged
- CLI becomes one of multiple frontends
- Same configuration and database files

---

## Security Considerations

1. **Data at Rest**
   - SQLite database in user directory
   - Optional encryption for sensitive metadata
   - Configurable database location

2. **Access Control**
   - Single-user by default
   - Enterprise: LDAP/AD integration planned
   - Audit trail records all changes

3. **QR Content**
   - Asset IDs only (not sensitive data)
   - Full metadata requires database access
   - Configurable QR content template

---

## Performance Requirements

| Operation | Target | Notes |
|-----------|--------|-------|
| Single asset registration | < 50ms | Including QR generation |
| Batch import (1000 rows) | < 5s | Without label generation |
| Batch labels (1000 assets) | < 30s | Parallel generation |
| Query (10K assets) | < 100ms | Indexed queries |
| Report generation | < 5s | 10K assets, PDF output |
| Database startup | < 200ms | Cold start |
