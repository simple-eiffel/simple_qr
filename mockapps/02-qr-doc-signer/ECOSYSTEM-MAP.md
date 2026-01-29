# QR-DOC-SIGNER - Ecosystem Integration

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_qr | QR code generation | QR_GENERATOR creates verification codes |
| simple_hash | SHA-256 hashing | HASH_ENGINE computes document hashes |
| simple_sql | SQLite database | DOCUMENT_REGISTRY persistence |
| simple_json | Configuration, export | CONFIG loading, JSON export |
| simple_file | File operations | Document reading, QR saving |
| simple_uuid | Document identifiers | ID_GENERATOR creates DOC-{uuid} |
| simple_datetime | Timestamps | Issued/revoked/verified timestamps |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_pdf | PDF embedding | Professional: embed QR in PDFs |
| simple_csv | CSV export | Alternative export format |
| simple_encryption | Registry encryption | Enterprise: encrypted at rest |
| simple_validation | Input validation | Custom metadata validation |

---

## Integration Patterns

### simple_qr Integration

**Purpose:** Generate verification QR codes

**Usage:**
```eiffel
class QR_GENERATOR

feature -- Generation

    generate_verification_qr (a_document_id, a_hash: STRING): STRING
            -- Generate QR code content for document verification.
        local
            l_qr: SIMPLE_QR
            l_content: STRING
        do
            -- Build QR content in standard format
            l_content := "qr-doc://v1/" + a_document_id + "|" + a_hash

            -- Generate QR code with high error correction
            create l_qr.make_with_level (l_qr.Level_m)
            l_qr.set_data (l_content)
            l_qr.generate

            if l_qr.is_generated then
                Result := l_qr.to_pbm
            else
                last_error := "QR generation failed: " + l_qr.last_error
            end
        ensure
            generated_or_error: not Result.is_empty or not last_error.is_empty
        end

    save_qr (a_pbm_content, a_path: STRING): BOOLEAN
            -- Save QR code to file.
        local
            l_file: SIMPLE_FILE
        do
            create l_file.make (a_path)
            Result := l_file.write_text (a_pbm_content)
        end

feature -- Access

    last_error: STRING
```

**Data flow:**
```
document_id + hash --> build content string --> SIMPLE_QR.generate --> PBM output
```

---

### simple_hash Integration

**Purpose:** Compute SHA-256 hash of document content

**Usage:**
```eiffel
class HASH_ENGINE

feature -- Hashing

    hash_file (a_path: STRING): STRING
            -- Compute SHA-256 hash of file content.
        local
            l_hash: SIMPLE_HASH
            l_file: SIMPLE_FILE
            l_content: STRING
        do
            create l_file.make (a_path)
            if l_file.exists then
                l_content := l_file.read_text
                create l_hash.make_sha256
                l_hash.update (l_content)
                full_hash := l_hash.to_hex

                -- Truncate for QR capacity
                Result := truncate_hash (full_hash, truncate_bytes)
            else
                last_error := "File not found: " + a_path
            end
        ensure
            result_length: Result.count = truncate_bytes * 2 or has_error
        end

    hash_string (a_content: STRING): STRING
            -- Compute SHA-256 hash of string content.
        local
            l_hash: SIMPLE_HASH
        do
            create l_hash.make_sha256
            l_hash.update (a_content)
            full_hash := l_hash.to_hex
            Result := truncate_hash (full_hash, truncate_bytes)
        end

feature {NONE} -- Implementation

    truncate_hash (a_hash: STRING; a_bytes: INTEGER): STRING
            -- Truncate hash to first N bytes (2N hex chars).
        require
            hash_long_enough: a_hash.count >= a_bytes * 2
        do
            Result := a_hash.substring (1, a_bytes * 2)
        ensure
            correct_length: Result.count = a_bytes * 2
        end

    truncate_bytes: INTEGER = 16
            -- Truncate to 16 bytes (32 hex chars) for QR capacity

feature -- Access

    full_hash: STRING
            -- Full hash before truncation

    last_error: STRING
```

---

### simple_sql Integration

**Purpose:** SQLite persistence for document registry

**Usage:**
```eiffel
class DOCUMENT_REGISTRY

feature -- Initialization

    make (a_path: STRING)
            -- Initialize registry database.
        local
            l_db: SIMPLE_SQL
        do
            create l_db.make (a_path)
            if not l_db.table_exists ("documents") then
                initialize_schema (l_db)
            end
            database := l_db
        end

feature -- Commands

    register_document (a_record: DOCUMENT_RECORD)
            -- Add document to registry.
        do
            database.execute (
                "INSERT INTO documents " +
                "(id, content_hash, full_hash, document_type, issuer, " +
                "issued_at, expires_at, original_filename, file_size, metadata) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                <<a_record.id, a_record.content_hash, a_record.full_hash,
                  a_record.document_type, a_record.issuer,
                  a_record.issued_at, a_record.expires_at,
                  a_record.original_filename, a_record.file_size,
                  a_record.metadata_json>>
            )
        ensure
            registered: lookup (a_record.id) /= Void
        end

    revoke_document (a_id, a_reason: STRING)
            -- Revoke a document.
        local
            l_now: SIMPLE_DATETIME
        do
            create l_now.make_now
            database.execute (
                "UPDATE documents SET status = 'revoked', " +
                "revoked_at = ?, revocation_reason = ? WHERE id = ?",
                <<l_now.to_iso8601, a_reason, a_id>>
            )
        end

feature -- Queries

    lookup (a_id: STRING): detachable DOCUMENT_RECORD
            -- Find document by ID.
        do
            database.query (
                "SELECT * FROM documents WHERE id = ?",
                <<a_id>>
            )
            if database.has_result then
                Result := row_to_record (database.current_row)
            end
        end

    verify_hash (a_id, a_presented_hash: STRING): INTEGER
            -- Verify document hash. Returns status code.
        local
            l_record: detachable DOCUMENT_RECORD
        do
            l_record := lookup (a_id)
            if l_record = Void then
                Result := Status_unknown
            elseif l_record.status ~ "revoked" then
                Result := Status_revoked
            elseif l_record.is_expired then
                Result := Status_expired
            elseif l_record.content_hash ~ a_presented_hash then
                Result := Status_verified
            else
                Result := Status_failed
            end
            log_verification (a_id, Result)
        end

feature -- Status codes

    Status_verified: INTEGER = 1
    Status_failed: INTEGER = 2
    Status_revoked: INTEGER = 3
    Status_expired: INTEGER = 4
    Status_unknown: INTEGER = 5
```

---

### simple_json Integration

**Purpose:** Configuration and export

**Usage:**
```eiffel
class EXPORT_ENGINE

feature -- Export

    export_json (a_records: LIST [DOCUMENT_RECORD]; a_path: STRING; a_public: BOOLEAN)
            -- Export records to JSON file.
        local
            l_json: SIMPLE_JSON
            l_array: SIMPLE_JSON_ARRAY
            l_file: SIMPLE_FILE
        do
            create l_json.make
            create l_array.make

            across a_records as rec loop
                l_array.add (record_to_json (rec, a_public))
            end

            l_json.put_array ("documents", l_array)
            l_json.put_string ("exported_at", current_timestamp)
            l_json.put_integer ("count", a_records.count)

            create l_file.make (a_path)
            l_file.write_text (l_json.to_string)
        end

feature {NONE} -- Implementation

    record_to_json (a_record: DOCUMENT_RECORD; a_public: BOOLEAN): SIMPLE_JSON
            -- Convert record to JSON object.
        do
            create Result.make
            Result.put_string ("id", a_record.id)
            Result.put_string ("hash", a_record.content_hash)
            Result.put_string ("type", a_record.document_type)
            Result.put_string ("issuer", a_record.issuer)
            Result.put_string ("issued_at", a_record.issued_at)
            Result.put_string ("status", a_record.status)

            if not a_public then
                -- Include private fields only in full export
                Result.put_string ("filename", a_record.original_filename)
                Result.put_string ("full_hash", a_record.full_hash)
                if attached a_record.metadata_json as m then
                    Result.put_raw ("metadata", m)
                end
            end
        end
```

---

### simple_uuid Integration

**Purpose:** Generate unique document identifiers

**Usage:**
```eiffel
class ID_GENERATOR

feature -- Generation

    generate_document_id: STRING
            -- Generate unique document ID.
        local
            l_uuid: SIMPLE_UUID
        do
            create l_uuid.make
            -- Use short form for QR capacity: DOC-{8 chars}
            Result := "DOC-" + l_uuid.to_short_string
        ensure
            valid_format: Result.starts_with ("DOC-")
            correct_length: Result.count = 12  -- "DOC-" + 8 chars
        end
```

---

### simple_datetime Integration

**Purpose:** Timestamps for all operations

**Usage:**
```eiffel
class SIGNER

feature -- Signing

    sign_document (a_path: STRING; a_type, a_issuer: STRING): DOCUMENT_RECORD
            -- Sign document and create record.
        local
            l_hash: STRING
            l_id: STRING
            l_now: SIMPLE_DATETIME
        do
            -- Compute hash
            l_hash := hash_engine.hash_file (a_path)

            -- Generate ID
            l_id := id_generator.generate_document_id

            -- Get timestamp
            create l_now.make_now

            -- Create record
            create Result.make (l_id, l_hash, hash_engine.full_hash)
            Result.set_document_type (a_type)
            Result.set_issuer (a_issuer)
            Result.set_issued_at (l_now.to_iso8601)
            Result.set_original_filename (file_name_from_path (a_path))

            -- Register
            registry.register_document (Result)

            -- Generate QR
            qr_content := qr_generator.generate_verification_qr (l_id, l_hash)
        end
```

---

### simple_pdf Integration (Professional)

**Purpose:** Embed QR codes directly into PDF documents

**Usage:**
```eiffel
class PDF_EMBEDDER

feature -- Embedding

    embed_qr (a_pdf_path, a_qr_path, a_output_path: STRING)
            -- Embed QR code into PDF.
        local
            l_pdf: SIMPLE_PDF
            l_page_count: INTEGER
        do
            create l_pdf.make_from_file (a_pdf_path)
            l_page_count := l_pdf.page_count

            -- Add QR to last page (or configurable)
            l_pdf.go_to_page (l_page_count)
            l_pdf.add_image (a_qr_path, position_x, position_y, qr_size, qr_size)

            l_pdf.save (a_output_path)
        end

    batch_embed (a_pdf_dir, a_qr_dir, a_output_dir: STRING)
            -- Embed QR codes into all PDFs in directory.
        local
            l_files: LIST [STRING]
            l_qr_path, l_output_path: STRING
        do
            l_files := list_pdf_files (a_pdf_dir)
            across l_files as f loop
                l_qr_path := corresponding_qr (f, a_qr_dir)
                l_output_path := output_path (f, a_output_dir)
                embed_qr (f, l_qr_path, l_output_path)
            end
        end

feature -- Configuration

    position_x: INTEGER = 500    -- Points from left
    position_y: INTEGER = 50     -- Points from bottom
    qr_size: INTEGER = 100       -- Points (square)
```

---

## Dependency Graph

```
qr_doc_signer
    |
    +-- simple_qr (REQUIRED)
    |       |
    |       +-- simple_file
    |
    +-- simple_hash (REQUIRED)
    |
    +-- simple_sql (REQUIRED)
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
    +-- simple_csv (OPTIONAL)
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
        name="qr_doc_signer"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <description>QR Code Document Signing CLI Tool</description>

    <!-- Library target (reusable core) -->
    <target name="qr_doc_signer">
        <root class="QR_DOC_CLI" feature="make"/>

        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <cluster name="src" location="./src/" recursive="true"/>

        <!-- Required simple_* dependencies -->
        <library name="simple_qr" location="$SIMPLE_EIFFEL/simple_qr/simple_qr.ecf"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>

        <!-- ISE base -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
    </target>

    <!-- CLI executable -->
    <target name="qr_doc_signer_cli" extends="qr_doc_signer">
        <root class="QR_DOC_CLI" feature="make"/>
        <setting name="executable_name" value="qr-doc"/>
    </target>

    <!-- Test target -->
    <target name="qr_doc_signer_tests" extends="qr_doc_signer">
        <root class="TEST_APP" feature="make"/>
        <cluster name="testing" location="./testing/" recursive="true"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

    <!-- Professional edition (adds PDF) -->
    <target name="qr_doc_signer_pro" extends="qr_doc_signer">
        <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    </target>

</system>
```

---

## Library Version Requirements

| Library | Minimum Version | Notes |
|---------|-----------------|-------|
| simple_qr | 1.0.0 | Current production |
| simple_hash | 1.0.0 | SHA-256 support |
| simple_sql | 1.0.0 | SQLite |
| simple_json | 1.0.0 | Object building |
| simple_file | 1.0.0 | Basic ops |
| simple_uuid | 1.0.0 | UUID generation |
| simple_datetime | 1.0.0 | ISO8601 |
| simple_pdf | 1.0.0 | Optional |
