# QR-TICKET-GATE - Technical Design

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                       QR-TICKET-GATE                              |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (event, ticket, validate, report)           |
|    - Interactive validation mode                                  |
|    - Output formatting (text, JSON, CSV)                          |
+------------------------------------------------------------------+
|  Business Logic Layer                                             |
|    - EVENT_MANAGER: Event CRUD, configuration                     |
|    - TICKET_GENERATOR: Ticket creation, QR generation             |
|    - VALIDATOR: Ticket validation, duplicate detection            |
|    - REPORTER: Statistics, analytics, exports                     |
+------------------------------------------------------------------+
|  Security Layer                                                   |
|    - SIGNATURE_ENGINE: HMAC-SHA256 signing/verification           |
|    - ID_GENERATOR: Cryptographic random IDs                       |
+------------------------------------------------------------------+
|  Data Layer                                                       |
|    - EVENT_REPOSITORY: Event persistence                          |
|    - TICKET_REPOSITORY: Ticket storage                            |
|    - CHECKIN_REPOSITORY: Check-in records                         |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_qr: QR code generation                                |
|    - simple_sql: SQLite database                                  |
|    - simple_hash: HMAC-SHA256 signatures                          |
|    - simple_csv: Import/export                                    |
|    - simple_json: Configuration, API output                       |
|    - simple_datetime: Event dates, check-in times                 |
|    - simple_uuid: Ticket IDs                                      |
|    - simple_encryption: Event secrets                             |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `QR_TICKET_CLI` | Command-line interface | parse_args, route, interactive_mode |
| `EVENT_MANAGER` | Event operations | create, update, delete, configure |
| `EVENT` | Event entity | id, name, date, venue, capacity, sessions |
| `TICKET_GENERATOR` | Ticket creation | generate_single, generate_batch, sign |
| `TICKET` | Ticket entity | id, event_id, attendee, type, signature |
| `VALIDATOR` | Ticket validation | validate, check_duplicate, record_checkin |
| `VALIDATION_RESULT` | Validation outcome | status, message, attendee_info |
| `SIGNATURE_ENGINE` | HMAC operations | sign, verify |
| `REPORTER` | Analytics | checkin_stats, attendance_report, export |
| `CONFIG` | Configuration | database, output settings |

### Command Structure

```bash
qr-ticket <command> [subcommand] [options] [arguments]

Commands:
  create-event    Create a new event
  list-events     List all events
  show-event      Show event details
  delete-event    Delete an event

  import          Import attendees from CSV
  add-ticket      Add single ticket
  list-tickets    List tickets for event
  cancel-ticket   Cancel a ticket
  generate        Generate QR codes for tickets

  validate        Validate tickets (interactive or single)
  check-in        Manual check-in by ticket ID

  report          Generate reports
  export          Export data (validation DB, check-ins)
  import-checkins Merge check-in data from stations

  config          Manage configuration

Examples:
  qr-ticket create-event "Annual Gala" --date 2026-06-15 --venue "Grand Hall"
  qr-ticket import attendees.csv --event EVT-abc123
  qr-ticket generate --event EVT-abc123 --output tickets/
  qr-ticket validate --event EVT-abc123 --mode interactive
  qr-ticket report --event EVT-abc123 --type attendance --output report.csv

Global Options:
  --database FILE   Database file (default: ~/.qr-ticket/tickets.db)
  --config FILE     Configuration file
  --quiet           Suppress non-essential output
  --verbose         Verbose output
  --help            Show help
```

### Data Flow

```
TICKET GENERATION:
                    +-------------+
                    |  CSV/Manual |
                    |   Input     |
                    +------+------+
                           |
                           v
                    +-------------+        +-------------+
                    |   TICKET    | <----- | SIGNATURE   |
                    |  GENERATOR  |        |   ENGINE    |
                    +------+------+        +-------------+
                           |
              +------------+------------+
              |                         |
              v                         v
       +-------------+           +-------------+
       |  simple_qr  |           |  DATABASE   |
       +------+------+           +-------------+
              |
              v
       +-------------+
       |  QR Image   |
       +-------------+


VALIDATION:
                    +-------------+
                    |  QR Scan    |
                    |  (input)    |
                    +------+------+
                           |
                           v
                    +-------------+
                    |  VALIDATOR  |
                    +------+------+
                           |
         +-----------------+-----------------+
         |                 |                 |
         v                 v                 v
  +-------------+   +-------------+   +-------------+
  |  SIGNATURE  |   |  Duplicate  |   |   Status    |
  |   Verify    |   |   Check     |   |   Check     |
  +------+------+   +------+------+   +------+------+
         |                 |                 |
         +-----------------+-----------------+
                           |
                           v
                    +-------------+
                    | VALIDATION  |
                    |   RESULT    |
                    +-------------+
                           |
                           v
                    +-------------+
                    | Record in   |
                    | CHECKIN_DB  |
                    +-------------+
```

### Database Schema

```sql
-- Events table
CREATE TABLE events (
    id TEXT PRIMARY KEY,              -- EVT-{uuid}
    name TEXT NOT NULL,
    event_date TEXT NOT NULL,         -- ISO 8601
    venue TEXT,
    capacity INTEGER,
    event_secret TEXT NOT NULL,       -- For HMAC signing
    sessions TEXT,                    -- JSON array of session names
    status TEXT DEFAULT 'active',     -- active, completed, cancelled
    created_at TEXT NOT NULL,
    metadata TEXT                     -- JSON for custom fields
);

-- Tickets table
CREATE TABLE tickets (
    id TEXT PRIMARY KEY,              -- TKT-{uuid}
    event_id TEXT NOT NULL,
    attendee_name TEXT NOT NULL,
    attendee_email TEXT,
    ticket_type TEXT DEFAULT 'general', -- general, vip, speaker, etc.
    valid_sessions TEXT,              -- JSON array, null = all sessions
    signature TEXT NOT NULL,          -- HMAC signature
    status TEXT DEFAULT 'active',     -- active, checked_in, cancelled
    created_at TEXT NOT NULL,
    cancelled_at TEXT,
    cancel_reason TEXT,
    metadata TEXT,                    -- JSON for custom fields
    FOREIGN KEY (event_id) REFERENCES events(id)
);

-- Check-ins table
CREATE TABLE checkins (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id TEXT NOT NULL,
    event_id TEXT NOT NULL,
    session TEXT,                     -- Which session (if multi-session)
    checked_in_at TEXT NOT NULL,      -- ISO 8601
    station TEXT,                     -- Which validation station
    validation_result TEXT NOT NULL,  -- valid, duplicate, invalid, etc.
    FOREIGN KEY (ticket_id) REFERENCES tickets(id),
    FOREIGN KEY (event_id) REFERENCES events(id)
);

-- Indexes
CREATE INDEX idx_tickets_event ON tickets(event_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_checkins_ticket ON checkins(ticket_id);
CREATE INDEX idx_checkins_event ON checkins(event_id);
CREATE INDEX idx_checkins_time ON checkins(checked_in_at);
```

### Configuration Schema

```json
{
  "qr_ticket": {
    "database": {
      "path": "~/.qr-ticket/tickets.db"
    },
    "validation": {
      "allow_reentry": false,
      "reentry_window_minutes": 30,
      "station_name": "Main Entrance"
    },
    "qr": {
      "error_correction": "M",
      "output_format": "pbm",
      "output_directory": "./tickets"
    },
    "export": {
      "date_format": "YYYY-MM-DD HH:mm:ss",
      "timezone": "local"
    }
  }
}
```

### Interactive Validation Mode

```
qr-ticket validate --event EVT-abc123 --mode interactive

╔═══════════════════════════════════════════════════════════════╗
║  QR-TICKET-GATE  |  Event: Annual Gala 2026                   ║
║  Station: Main Entrance                                       ║
╠═══════════════════════════════════════════════════════════════╣
║  Checked In: 147 / 200  |  Time: 19:42:15                     ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Scan ticket or enter code:  _                                ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Last: VALID - Welcome, John Smith (General)                  ║
╚═══════════════════════════════════════════════════════════════╝

Commands:
  [Enter QR data]  - Validate ticket
  /stats           - Show detailed statistics
  /search <name>   - Search attendee
  /manual <id>     - Manual check-in by ID
  /exit            - Exit validation mode
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Event not found | Abort | "Event not found: {id}" |
| Ticket not found | Report | "UNKNOWN TICKET: Not in database" |
| Invalid signature | Report | "INVALID TICKET: Signature mismatch" |
| Duplicate check-in | Report | "ALREADY CHECKED IN at {time}" |
| Wrong event | Report | "WRONG EVENT: Ticket for {event}" |
| Database error | Abort | "Database error: {message}" |
| CSV parse error | Skip row | "Row {n}: Parse error - {details}" |
| Capacity exceeded | Warn | "Warning: Event at capacity" |

---

## GUI/TUI Future Path

**CLI foundation enables:**

### TUI Extension
- Real-time check-in dashboard
- Attendee search with autocomplete
- Statistics display with charts
- Multi-station coordination view

### GUI Extension
- Visual ticket designer
- Drag-and-drop CSV import
- Check-in kiosk mode
- Badge printing integration
- Real-time attendance map

### Mobile App
- Scanner app for validation
- Attendee self-check-in
- Digital ticket wallet
- Push notifications

### Shared Components
- All validation logic in VALIDATOR
- Statistics in REPORTER
- Database schema unchanged
- Same ticket format across platforms

---

## Security Considerations

1. **Event Secret**
   - Generated using cryptographic random
   - Stored in database (protect database file)
   - Used for HMAC-SHA256 signing

2. **Ticket Forgery Prevention**
   - Signature verification on every scan
   - Cannot compute valid signature without secret
   - Truncated signature still provides 64-bit security

3. **Duplicate Detection**
   - All check-ins recorded in database
   - Real-time duplicate detection
   - Works across multiple stations (post-merge)

4. **Offline Security**
   - Validation DB contains only public ticket info
   - Event secret included for verification
   - Physical security of validation stations important

---

## Performance Requirements

| Operation | Target | Notes |
|-----------|--------|-------|
| Generate 1000 tickets | < 30s | Parallel generation |
| Validate single ticket | < 100ms | Including DB lookup |
| Interactive mode startup | < 500ms | Load event data |
| Check-in query (10K) | < 200ms | Indexed queries |
| Report generation | < 5s | 10K attendees |
| Database export | < 10s | Full event data |
