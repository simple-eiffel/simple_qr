# QR-ASSET-TRACKER - Ecosystem Integration

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_qr | QR code generation | LABEL_GENERATOR uses SIMPLE_QR.generate |
| simple_sql | SQLite database | ASSET_REPOSITORY for all persistence |
| simple_csv | CSV import/export | IMPORT_EXPORT for bulk operations |
| simple_json | Configuration, JSON output | CONFIG loading, report export |
| simple_file | File operations | Label saving, config files |
| simple_uuid | Asset identifiers | Generate unique asset IDs |
| simple_datetime | Timestamps | Event logging, audit trails |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_pdf | PDF report generation | Professional/Enterprise features |
| simple_cli | Enhanced argument parsing | If complex subcommand handling needed |
| simple_hash | Data integrity verification | Enterprise audit compliance |
| simple_encryption | Encrypted metadata storage | Sensitive asset data |
| simple_validation | Input validation rules | Custom field validation |

---

## Integration Patterns

### simple_qr Integration

**Purpose:** Generate QR code labels for assets

**Usage:**
```eiffel
class LABEL_GENERATOR

feature -- Generation

    generate_label (a_asset: ASSET): STRING
            -- Generate QR code label for asset.
        local
            l_qr: SIMPLE_QR
            l_content: STRING
        do
            -- Build QR content (asset ID and optional metadata)
            l_content := build_qr_content (a_asset)

            -- Generate QR code
            create l_qr.make_with_level (error_correction_level)
            l_qr.set_data (l_content)
            l_qr.generate

            if l_qr.is_generated then
                Result := l_qr.to_pbm
            else
                last_error := l_qr.last_error
            end
        ensure
            generated_or_error: not Result.is_empty or not last_error.is_empty
        end

    generate_batch (a_assets: LIST [ASSET]; a_output_dir: STRING)
            -- Generate labels for all assets in batch.
        local
            l_label: STRING
            l_path: STRING
        do
            across a_assets as asset loop
                l_label := generate_label (asset)
                if not l_label.is_empty then
                    l_path := a_output_dir + "/" + asset.id + ".pbm"
                    save_label (l_label, l_path)
                    generated_count := generated_count + 1
                else
                    failed_count := failed_count + 1
                end
            end
        end

feature {NONE} -- Implementation

    build_qr_content (a_asset: ASSET): STRING
            -- Build QR code content string.
        do
            -- Default: just asset ID for lookup
            -- Can be configured to include more data
            Result := "asset://" + a_asset.id
        end

    error_correction_level: INTEGER
            -- EC level from config (default M)
        do
            Result := config.labels_error_correction
        end
```

**Data flow:**
```
ASSET --> build_qr_content --> SIMPLE_QR.set_data
                               SIMPLE_QR.generate
                               SIMPLE_QR.to_pbm --> PBM file
```

---

### simple_sql Integration

**Purpose:** SQLite persistence for all asset data

**Usage:**
```eiffel
class ASSET_REPOSITORY

feature -- Initialization

    make (a_database_path: STRING)
            -- Initialize repository with database.
        local
            l_db: SIMPLE_SQL
        do
            create l_db.make (a_database_path)
            if not l_db.table_exists ("assets") then
                initialize_schema (l_db)
            end
            database := l_db
        end

feature -- Queries

    find_by_id (a_id: STRING): detachable ASSET
            -- Find asset by ID.
        do
            database.query ("SELECT * FROM assets WHERE id = ?", <<a_id>>)
            if database.has_result then
                Result := row_to_asset (database.current_row)
            end
        end

    find_by_type (a_type: STRING): LIST [ASSET]
            -- Find all assets of given type.
        do
            create {ARRAYED_LIST [ASSET]} Result.make (100)
            database.query ("SELECT * FROM assets WHERE type = ?", <<a_type>>)
            across database.results as row loop
                Result.extend (row_to_asset (row))
            end
        end

    find_by_location (a_location_id: STRING): LIST [ASSET]
            -- Find all assets at location (including sub-locations).
        do
            create {ARRAYED_LIST [ASSET]} Result.make (100)
            database.query ("SELECT a.* FROM assets a " +
                "JOIN locations l ON a.location_id = l.id " +
                "WHERE l.path LIKE ?", <<location_path + "%%">>)
            across database.results as row loop
                Result.extend (row_to_asset (row))
            end
        end

feature -- Commands

    save (a_asset: ASSET)
            -- Save asset (insert or update).
        do
            if exists (a_asset.id) then
                update (a_asset)
            else
                insert (a_asset)
            end
            log_event (a_asset.id, "saved")
        end
```

**Data flow:**
```
ASSET_MANAGER --> ASSET_REPOSITORY.save --> SIMPLE_SQL.execute
ASSET_MANAGER <-- ASSET_REPOSITORY.find --> SIMPLE_SQL.query
```

---

### simple_csv Integration

**Purpose:** Bulk import/export of asset data

**Usage:**
```eiffel
class IMPORT_EXPORT

feature -- Import

    import_csv (a_path: STRING; a_defaults: TUPLE [type: STRING; location: STRING])
            -- Import assets from CSV file.
        local
            l_csv: SIMPLE_CSV
            l_asset: ASSET
        do
            create l_csv.make_from_file (a_path)

            -- Validate headers
            if not valid_headers (l_csv.headers) then
                last_error := "Invalid CSV headers. Required: name, serial_number"
                has_error := True
            else
                across l_csv.rows as row loop
                    l_asset := row_to_asset (row, a_defaults)
                    if l_asset.is_valid then
                        repository.save (l_asset)
                        imported_count := imported_count + 1
                    else
                        skipped_count := skipped_count + 1
                        skipped_rows.extend (row.index)
                    end
                end
            end
        end

feature -- Export

    export_csv (a_assets: LIST [ASSET]; a_path: STRING)
            -- Export assets to CSV file.
        local
            l_csv: SIMPLE_CSV
        do
            create l_csv.make_with_headers (asset_headers)
            across a_assets as asset loop
                l_csv.add_row (asset_to_row (asset))
            end
            l_csv.save (a_path)
        end
```

---

### simple_json Integration

**Purpose:** Configuration and JSON output

**Usage:**
```eiffel
class CONFIG

feature -- Loading

    load (a_path: STRING)
            -- Load configuration from JSON file.
        local
            l_json: SIMPLE_JSON
            l_file: SIMPLE_FILE
        do
            create l_file.make (a_path)
            if l_file.exists then
                create l_json.make_from_string (l_file.read_text)
                parse_config (l_json)
            else
                set_defaults
            end
        end

feature -- Access

    database_path: STRING
    labels_error_correction: INTEGER
    labels_output_directory: STRING
    default_asset_type: STRING

feature {NONE} -- Parsing

    parse_config (a_json: SIMPLE_JSON)
        do
            if a_json.has ("qr_asset") then
                across a_json.object ("qr_asset") as section loop
                    parse_section (section.key, section.value)
                end
            end
        end
```

---

### simple_uuid Integration

**Purpose:** Generate unique asset identifiers

**Usage:**
```eiffel
class ASSET_MANAGER

feature -- Creation

    register_asset (a_name, a_type: STRING): ASSET
            -- Register new asset with auto-generated ID.
        local
            l_uuid: SIMPLE_UUID
            l_id: STRING
        do
            create l_uuid.make
            l_id := "ASSET-" + l_uuid.to_short_string  -- e.g., "ASSET-7f3d2a1b"

            create Result.make (l_id, a_name, a_type)
            Result.set_created_at (current_timestamp)

            repository.save (Result)
            log_event (Result.id, "created", "Asset registered")
        ensure
            result_saved: repository.exists (Result.id)
        end
```

---

### simple_datetime Integration

**Purpose:** Timestamps for events and auditing

**Usage:**
```eiffel
class ASSET_EVENT

feature -- Initialization

    make (a_asset_id, a_event_type: STRING)
            -- Create event with current timestamp.
        local
            l_dt: SIMPLE_DATETIME
        do
            asset_id := a_asset_id
            event_type := a_event_type
            create l_dt.make_now
            timestamp := l_dt.to_iso8601
        ensure
            timestamp_set: not timestamp.is_empty
        end

feature -- Access

    asset_id: STRING
    event_type: STRING
    timestamp: STRING
    actor: STRING
    details: STRING
```

---

## Dependency Graph

```
qr_asset_tracker
    |
    +-- simple_qr (REQUIRED)
    |       |
    |       +-- simple_file
    |
    +-- simple_sql (REQUIRED)
    |
    +-- simple_csv (REQUIRED)
    |
    +-- simple_json (REQUIRED)
    |
    +-- simple_file (REQUIRED)
    |
    +-- simple_uuid (REQUIRED)
    |
    +-- simple_datetime (REQUIRED)
    |
    +-- simple_pdf (OPTIONAL - Professional)
    |
    +-- simple_hash (OPTIONAL - Enterprise)
    |
    +-- simple_encryption (OPTIONAL - Enterprise)
    |
    +-- ISE base (REQUIRED)
```

---

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-22-0 http://www.eiffel.com/developers/xml/configuration-1-22-0.xsd"
        name="qr_asset_tracker"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <description>QR Code Asset Tracking CLI Tool</description>

    <!-- Library target (reusable core) -->
    <target name="qr_asset_tracker">
        <root class="QR_ASSET_CLI" feature="make"/>
        <version major="1" minor="0" release="0" build="1"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <!-- Source clusters -->
        <cluster name="src" location="./src/" recursive="true"/>

        <!-- simple_* dependencies -->
        <library name="simple_qr" location="$SIMPLE_EIFFEL/simple_qr/simple_qr.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>

        <!-- ISE libraries (only when no simple_* alternative) -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
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

    <!-- Professional edition (adds PDF) -->
    <target name="qr_asset_tracker_pro" extends="qr_asset_tracker">
        <variable name="EDITION" value="professional"/>
        <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    </target>

    <!-- Enterprise edition (adds encryption, hash) -->
    <target name="qr_asset_tracker_enterprise" extends="qr_asset_tracker_pro">
        <variable name="EDITION" value="enterprise"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_encryption" location="$SIMPLE_EIFFEL/simple_encryption/simple_encryption.ecf"/>
    </target>

</system>
```

---

## Library Version Requirements

| Library | Minimum Version | Notes |
|---------|-----------------|-------|
| simple_qr | 1.0.0 | Current production version |
| simple_sql | 1.0.0 | SQLite support required |
| simple_csv | 1.0.0 | Header support required |
| simple_json | 1.0.0 | Object navigation required |
| simple_file | 1.0.0 | Basic file operations |
| simple_uuid | 1.0.0 | UUID generation |
| simple_datetime | 1.0.0 | ISO8601 support |
| simple_pdf | 1.0.0 | Optional, for Professional |
