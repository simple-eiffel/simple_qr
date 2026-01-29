# QR-TICKET-GATE - Ecosystem Integration

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_qr | QR code generation | TICKET_GENERATOR creates ticket QR codes |
| simple_sql | SQLite database | All repositories use SQLite |
| simple_hash | HMAC-SHA256 | SIGNATURE_ENGINE for ticket signing |
| simple_csv | Attendee import/export | IMPORT_EXPORT for bulk operations |
| simple_json | Configuration, reports | CONFIG, JSON output |
| simple_file | File operations | Ticket saving, config files |
| simple_uuid | Ticket/event IDs | ID_GENERATOR for unique IDs |
| simple_datetime | Timestamps | Event dates, check-in times |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_encryption | Secure event secrets | Enhanced security mode |
| simple_pdf | Ticket templates | Professional: printable tickets |
| simple_email | Ticket delivery | Enterprise: auto-send tickets |
| simple_validation | Input validation | Custom field validation |

---

## Integration Patterns

### simple_qr Integration

**Purpose:** Generate ticket QR codes

**Usage:**
```eiffel
class TICKET_GENERATOR

feature -- Generation

    generate_ticket_qr (a_ticket: TICKET; a_event: EVENT): STRING
            -- Generate QR code for ticket.
        local
            l_qr: SIMPLE_QR
            l_content: STRING
        do
            -- Build ticket content
            l_content := build_ticket_content (a_ticket, a_event)

            -- Generate QR with medium error correction
            create l_qr.make_with_level (l_qr.Level_m)
            l_qr.set_data (l_content)
            l_qr.generate

            if l_qr.is_generated then
                Result := l_qr.to_pbm
            else
                last_error := l_qr.last_error
            end
        end

    generate_batch (a_tickets: LIST [TICKET]; a_event: EVENT; a_output_dir: STRING)
            -- Generate QR codes for all tickets.
        local
            l_qr_content: STRING
            l_path: STRING
        do
            across a_tickets as ticket loop
                l_qr_content := generate_ticket_qr (ticket, a_event)
                if not l_qr_content.is_empty then
                    l_path := a_output_dir + "/" + ticket.id + ".pbm"
                    save_qr (l_qr_content, l_path)
                    generated_count := generated_count + 1
                end
            end
        end

feature {NONE} -- Implementation

    build_ticket_content (a_ticket: TICKET; a_event: EVENT): STRING
            -- Build QR content string.
        do
            -- Format: qr-ticket://v1/{event_id}/{ticket_id}|{signature}
            Result := "qr-ticket://v1/" +
                      a_event.id + "/" +
                      a_ticket.id + "|" +
                      a_ticket.signature
        ensure
            valid_format: Result.starts_with ("qr-ticket://v1/")
        end
```

**Data flow:**
```
TICKET + EVENT --> build_content --> SIMPLE_QR.generate --> PBM file
```

---

### simple_hash Integration

**Purpose:** HMAC-SHA256 signing and verification

**Usage:**
```eiffel
class SIGNATURE_ENGINE

feature -- Signing

    sign_ticket (a_ticket_id, a_event_secret: STRING): STRING
            -- Generate HMAC-SHA256 signature for ticket.
        local
            l_hash: SIMPLE_HASH
        do
            create l_hash.make_hmac_sha256 (a_event_secret)
            l_hash.update (a_ticket_id)

            -- Truncate to 16 chars for QR capacity
            Result := l_hash.to_hex.substring (1, 16)
        ensure
            correct_length: Result.count = 16
        end

    verify_signature (a_ticket_id, a_signature, a_event_secret: STRING): BOOLEAN
            -- Verify ticket signature.
        local
            l_expected: STRING
        do
            l_expected := sign_ticket (a_ticket_id, a_event_secret)
            Result := l_expected ~ a_signature
        end

feature -- Event secret generation

    generate_event_secret: STRING
            -- Generate cryptographically random event secret.
        local
            l_hash: SIMPLE_HASH
            l_uuid: SIMPLE_UUID
        do
            -- Use UUID + timestamp for entropy
            create l_uuid.make
            create l_hash.make_sha256
            l_hash.update (l_uuid.to_string + current_timestamp)
            Result := l_hash.to_hex
        ensure
            correct_length: Result.count = 64  -- SHA-256 hex
        end
```

---

### simple_sql Integration

**Purpose:** SQLite persistence for all data

**Usage:**
```eiffel
class TICKET_REPOSITORY

feature -- Initialization

    make (a_database_path: STRING)
            -- Initialize repository.
        local
            l_db: SIMPLE_SQL
        do
            create l_db.make (a_database_path)
            if not l_db.table_exists ("tickets") then
                initialize_schema (l_db)
            end
            database := l_db
        end

feature -- Queries

    find_by_id (a_id: STRING): detachable TICKET
            -- Find ticket by ID.
        do
            database.query (
                "SELECT * FROM tickets WHERE id = ?",
                <<a_id>>
            )
            if database.has_result then
                Result := row_to_ticket (database.current_row)
            end
        end

    find_by_event (a_event_id: STRING): LIST [TICKET]
            -- Find all tickets for event.
        do
            create {ARRAYED_LIST [TICKET]} Result.make (100)
            database.query (
                "SELECT * FROM tickets WHERE event_id = ? ORDER BY attendee_name",
                <<a_event_id>>
            )
            across database.results as row loop
                Result.extend (row_to_ticket (row))
            end
        end

    is_checked_in (a_ticket_id: STRING): BOOLEAN
            -- Has ticket been checked in?
        do
            database.query (
                "SELECT 1 FROM checkins WHERE ticket_id = ? AND validation_result = 'valid' LIMIT 1",
                <<a_ticket_id>>
            )
            Result := database.has_result
        end

    get_checkin_time (a_ticket_id: STRING): detachable STRING
            -- Get check-in timestamp if checked in.
        do
            database.query (
                "SELECT checked_in_at FROM checkins WHERE ticket_id = ? AND validation_result = 'valid' LIMIT 1",
                <<a_ticket_id>>
            )
            if database.has_result then
                Result := database.current_row.string_item ("checked_in_at")
            end
        end

feature -- Commands

    record_checkin (a_ticket_id, a_event_id: STRING; a_result: STRING; a_station: STRING)
            -- Record check-in attempt.
        local
            l_now: SIMPLE_DATETIME
        do
            create l_now.make_now
            database.execute (
                "INSERT INTO checkins (ticket_id, event_id, checked_in_at, station, validation_result) " +
                "VALUES (?, ?, ?, ?, ?)",
                <<a_ticket_id, a_event_id, l_now.to_iso8601, a_station, a_result>>
            )
        end
```

---

### simple_csv Integration

**Purpose:** Bulk attendee import/export

**Usage:**
```eiffel
class IMPORT_EXPORT

feature -- Import

    import_attendees (a_path: STRING; a_event: EVENT): INTEGER
            -- Import attendees from CSV. Returns count imported.
        local
            l_csv: SIMPLE_CSV
            l_ticket: TICKET
        do
            create l_csv.make_from_file (a_path)

            -- Validate headers
            if not has_required_headers (l_csv.headers) then
                last_error := "Missing required columns: name"
            else
                across l_csv.rows as row loop
                    l_ticket := create_ticket_from_row (row, a_event)
                    if l_ticket.is_valid then
                        ticket_repository.save (l_ticket)
                        Result := Result + 1
                    else
                        skipped_rows.extend (row.index)
                    end
                end
            end
        end

feature -- Export

    export_attendees (a_event: EVENT; a_path: STRING)
            -- Export all attendees to CSV.
        local
            l_csv: SIMPLE_CSV
            l_tickets: LIST [TICKET]
        do
            l_tickets := ticket_repository.find_by_event (a_event.id)

            create l_csv.make_with_headers (<<"name", "email", "ticket_type", "status", "checked_in">>)
            across l_tickets as ticket loop
                l_csv.add_row (<<
                    ticket.attendee_name,
                    ticket.attendee_email,
                    ticket.ticket_type,
                    ticket.status,
                    if ticket_repository.is_checked_in (ticket.id) then "Yes" else "No" end
                >>)
            end
            l_csv.save (a_path)
        end
```

---

### simple_encryption Integration (Optional)

**Purpose:** Secure event secret storage

**Usage:**
```eiffel
class EVENT_MANAGER

feature -- Security

    store_event_secret (a_event: EVENT; a_secret: STRING)
            -- Store encrypted event secret.
        local
            l_enc: SIMPLE_ENCRYPTION
            l_encrypted: STRING
        do
            if config.encrypt_secrets then
                create l_enc.make_aes256
                l_enc.set_key (master_key)
                l_encrypted := l_enc.encrypt (a_secret)
                a_event.set_encrypted_secret (l_encrypted)
            else
                a_event.set_secret (a_secret)
            end
        end

    retrieve_event_secret (a_event: EVENT): STRING
            -- Retrieve decrypted event secret.
        local
            l_enc: SIMPLE_ENCRYPTION
        do
            if a_event.has_encrypted_secret then
                create l_enc.make_aes256
                l_enc.set_key (master_key)
                Result := l_enc.decrypt (a_event.encrypted_secret)
            else
                Result := a_event.secret
            end
        end
```

---

## Dependency Graph

```
qr_ticket_gate
    |
    +-- simple_qr (REQUIRED)
    |       |
    |       +-- simple_file
    |
    +-- simple_sql (REQUIRED)
    |
    +-- simple_hash (REQUIRED)
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
    +-- simple_encryption (OPTIONAL - Enterprise)
    |
    +-- simple_pdf (OPTIONAL - Professional)
    |
    +-- simple_email (OPTIONAL - Enterprise)
    |
    +-- ISE base (REQUIRED)
```

---

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        name="qr_ticket_gate"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <description>QR Code Event Ticketing CLI Tool</description>

    <!-- Library target (reusable core) -->
    <target name="qr_ticket_gate">
        <root class="QR_TICKET_CLI" feature="make"/>

        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <cluster name="src" location="./src/" recursive="true"/>

        <!-- Required simple_* dependencies -->
        <library name="simple_qr" location="$SIMPLE_EIFFEL/simple_qr/simple_qr.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>

        <!-- ISE base -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
    </target>

    <!-- CLI executable -->
    <target name="qr_ticket_gate_cli" extends="qr_ticket_gate">
        <root class="QR_TICKET_CLI" feature="make"/>
        <setting name="executable_name" value="qr-ticket"/>
    </target>

    <!-- Test target -->
    <target name="qr_ticket_gate_tests" extends="qr_ticket_gate">
        <root class="TEST_APP" feature="make"/>
        <cluster name="testing" location="./testing/" recursive="true"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

    <!-- Professional edition -->
    <target name="qr_ticket_gate_pro" extends="qr_ticket_gate">
        <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    </target>

    <!-- Enterprise edition -->
    <target name="qr_ticket_gate_enterprise" extends="qr_ticket_gate_pro">
        <library name="simple_encryption" location="$SIMPLE_EIFFEL/simple_encryption/simple_encryption.ecf"/>
        <library name="simple_email" location="$SIMPLE_EIFFEL/simple_email/simple_email.ecf"/>
    </target>

</system>
```

---

## Library Version Requirements

| Library | Minimum Version | Notes |
|---------|-----------------|-------|
| simple_qr | 1.0.0 | Current production |
| simple_sql | 1.0.0 | SQLite support |
| simple_hash | 1.0.0 | HMAC-SHA256 support |
| simple_csv | 1.0.0 | Header support |
| simple_json | 1.0.0 | Object building |
| simple_file | 1.0.0 | Basic ops |
| simple_uuid | 1.0.0 | UUID generation |
| simple_datetime | 1.0.0 | ISO8601 |
| simple_encryption | 1.0.0 | Optional - AES256 |
| simple_pdf | 1.0.0 | Optional - ticket templates |
