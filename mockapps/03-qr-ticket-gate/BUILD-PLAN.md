# QR-TICKET-GATE - Build Plan

**Mock App Design for simple_qr**
**Generated:** 2026-01-24

---

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 4-5 days | simple_qr, simple_sql, simple_hash, simple_uuid |
| Phase 2 | Full CLI | 4-5 days | Phase 1 + simple_csv, simple_json |
| Phase 3 | Polish | 2-3 days | Phase 2 complete |

**Total Estimated Effort:** 10-13 days

---

## Phase 1: MVP (Minimum Viable Product)

### Objective

Deliver a working CLI that can create events, generate tickets with cryptographic signatures, and validate tickets with duplicate detection. This proves the core value: secure offline ticketing.

### Deliverables

1. **EVENT class** - Event entity
2. **TICKET class** - Ticket entity
3. **SIGNATURE_ENGINE class** - HMAC signing
4. **EVENT_REPOSITORY class** - Event persistence
5. **TICKET_REPOSITORY class** - Ticket persistence
6. **TICKET_GENERATOR class** - Ticket creation with QR
7. **VALIDATOR class** - Ticket validation
8. **QR_TICKET_CLI class** - Basic CLI
9. **Commands:** create-event, add-ticket, generate, validate

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure | ECF compiles |
| T1.2 | Implement EVENT class | Entity with validation |
| T1.3 | Implement TICKET class | Entity with signature |
| T1.4 | Implement SIGNATURE_ENGINE | HMAC-SHA256 sign/verify |
| T1.5 | Implement EVENT_REPOSITORY | SQLite CRUD |
| T1.6 | Implement TICKET_REPOSITORY | SQLite CRUD + duplicate check |
| T1.7 | Implement TICKET_GENERATOR | Create ticket with QR |
| T1.8 | Implement VALIDATOR | Full validation logic |
| T1.9 | Implement CLI skeleton | Arg parsing, routing |
| T1.10 | Implement `create-event` | Creates event with secret |
| T1.11 | Implement `add-ticket` | Creates single ticket |
| T1.12 | Implement `generate` | Generates QR files |
| T1.13 | Implement `validate` | Single ticket validation |
| T1.14 | Write MVP tests | 80% coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Create event | `create-event "Gala" --date 2026-06-15` | Event created with ID |
| Add ticket | `add-ticket --event EVT-x --name "John"` | Ticket created with signature |
| Generate QR | `generate --ticket TKT-y` | PBM file created |
| Validate valid | Scan valid ticket | "VALID: Welcome, John" |
| Validate duplicate | Scan same ticket twice | "ALREADY CHECKED IN" |
| Validate invalid | Forged signature | "INVALID TICKET" |
| Validate unknown | Non-existent ticket | "UNKNOWN TICKET" |

### MVP Command Specification

```bash
# Create event
qr-ticket create-event "Annual Gala" --date 2026-06-15 --venue "Grand Hall"
# Output: Created event EVT-abc123
#         Secret: [stored securely]

# Add single ticket
qr-ticket add-ticket --event EVT-abc123 --name "John Smith" --email john@mail.com
# Output: Created ticket TKT-7f3d2a1b
#         Signature: x9y8z7w6v5u4t3s2

# Generate QR for ticket
qr-ticket generate --ticket TKT-7f3d2a1b --output ticket.pbm
# Output: Generated: ticket.pbm

# Validate ticket
qr-ticket validate "qr-ticket://v1/EVT-abc123/TKT-7f3d2a1b|x9y8z7w6v5u4t3s2"
# Output: VALID
#         Welcome, John Smith
#         Type: general
#         Checked in at: 2026-06-15T19:42:30Z
```

---

## Phase 2: Full Implementation

### Objective

Add batch operations, interactive validation mode, multi-session support, offline export/import, and reporting. This delivers production-ready event ticketing.

### Deliverables

1. **IMPORT_EXPORT class** - CSV import, data export
2. **REPORTER class** - Statistics and reports
3. **Interactive mode** - Real-time validation UI
4. **Multi-session support** - Session-specific validation
5. **Offline mode** - Export/import for stations
6. **Commands:** import, list-tickets, check-in, report, export, import-checkins

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement IMPORT_EXPORT | CSV import with validation |
| T2.2 | Implement `import` command | Bulk attendee import |
| T2.3 | Implement `list-events` | Show all events |
| T2.4 | Implement `show-event` | Event details with stats |
| T2.5 | Implement `list-tickets` | Tickets with filters |
| T2.6 | Implement `cancel-ticket` | Cancel with reason |
| T2.7 | Add multi-session to EVENT | Sessions configuration |
| T2.8 | Add session validation | Per-session check-in |
| T2.9 | Implement interactive mode | Real-time validation UI |
| T2.10 | Implement REPORTER | Check-in statistics |
| T2.11 | Implement `report` command | Various report types |
| T2.12 | Implement `export` command | Validation DB export |
| T2.13 | Implement `import-checkins` | Merge station data |
| T2.14 | Add station name tracking | Which entrance |
| T2.15 | Write comprehensive tests | 90% coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Import CSV | `import attendees.csv --event EVT-x` | "Imported 100 tickets" |
| Import invalid | Bad CSV | Error with row numbers |
| List events | `list-events` | All events with status |
| Show event | `show-event EVT-x` | Stats, ticket counts |
| List tickets | `list-tickets --event EVT-x` | All tickets |
| Cancel ticket | `cancel-ticket TKT-y --reason "Refund"` | Status changed |
| Validate cancelled | Cancelled ticket | "CANCELLED: Refund" |
| Multi-session create | `--sessions "Day1,Day2"` | Sessions configured |
| Validate session | Day2 pass on Day1 | "WRONG SESSION" |
| Interactive mode | `--mode interactive` | UI starts |
| Export validation | `export --event EVT-x` | Creates export.db |
| Offline validate | `--offline --db export.db` | Works without main DB |
| Report attendance | `report --type attendance` | Check-in statistics |

### Interactive Mode Specification

```
qr-ticket validate --event EVT-abc123 --mode interactive

[Interactive UI appears]

Scan or enter ticket: qr-ticket://v1/EVT-abc123/TKT-7f3d2a1b|x9y8z7w6v5u4t3s2

╔══════════════════════════════════════╗
║  VALID                               ║
║  Welcome, John Smith                 ║
║  Type: general                       ║
║  Checked in at 19:42:30              ║
╚══════════════════════════════════════╝

Checked In: 148/200  |  VIP: 23/30  |  General: 125/170
```

### CSV Format Specification

```csv
name,email,ticket_type,sessions
"John Smith","john@mail.com","general",""
"Jane Doe","jane@mail.com","vip",""
"Bob Wilson","bob@mail.com","day","Day1"
"Alice Brown","alice@mail.com","full","Day1,Day2,Day3"
```

---

## Phase 3: Production Polish

### Objective

Harden for production with comprehensive error handling, performance optimization, documentation, and release packaging.

### Deliverables

1. **Error handling** - All edge cases
2. **Performance** - Large events (5K+ attendees)
3. **Help system** - Built-in help
4. **Documentation** - User guide
5. **Release package** - Installer/binary

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Comprehensive errors | Clear messages |
| T3.2 | Input validation | All inputs checked |
| T3.3 | Performance: 5K tickets | Generate < 60s |
| T3.4 | Performance: 10K checkins | Report < 10s |
| T3.5 | Database indexes | Queries < 100ms |
| T3.6 | Built-in help | All commands |
| T3.7 | README with examples | Quick start |
| T3.8 | Event guide | Full workflow doc |
| T3.9 | Finalize contracts | 100% coverage |
| T3.10 | Integration tests | E2E scenarios |
| T3.11 | Release build | Finalized binary |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Large import (5K) | 5000 row CSV | Completes < 60s |
| Large generate (5K) | 5000 tickets | Completes < 120s |
| Large report (10K) | 10000 checkins | Completes < 10s |
| Unicode names | Non-ASCII attendees | Handles correctly |
| Long event name | 200 char name | Stores correctly |
| Concurrent validate | Parallel requests | All succeed |
| Database recovery | Corrupted DB | Graceful error |
| Help | `--help` | Shows all commands |

---

## ECF Target Structure

```xml
<!-- Library target -->
<target name="qr_ticket_gate">
    <root class="QR_TICKET_CLI" feature="make"/>
    <cluster name="src" location="./src/" recursive="true"/>
</target>

<!-- CLI executable -->
<target name="qr_ticket_gate_cli" extends="qr_ticket_gate">
    <root class="QR_TICKET_CLI" feature="make"/>
    <setting name="executable_name" value="qr-ticket"/>
</target>

<!-- Tests -->
<target name="qr_ticket_gate_tests" extends="qr_ticket_gate">
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
/d/prod/ec.sh -batch -config qr_ticket_gate.ecf -target qr_ticket_gate_cli -c_compile

# Run CLI
./EIFGENs/qr_ticket_gate_cli/W_code/qr-ticket.exe --help

# Run tests
/d/prod/ec.sh -batch -config qr_ticket_gate.ecf -target qr_ticket_gate_tests -c_compile
./EIFGENs/qr_ticket_gate_tests/W_code/qr-ticket.exe

# Production build
/d/prod/ec.sh -batch -config qr_ticket_gate.ecf -target qr_ticket_gate_cli -finalize -c_compile
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Security | Signature verify | 100% |
| Duplicate detection | Accuracy | 100% |
| Performance | 5K tickets | < 2 min total |
| Documentation | README | Complete |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| HMAC API differences | Low | Medium | Check simple_hash docs |
| Large event memory | Medium | Medium | Streaming, chunking |
| Interactive mode complexity | Medium | Low | Start with basic |
| Multi-station sync | Low | Medium | Simple merge algorithm |

---

## Post-Launch Roadmap

### Version 1.1
- Re-entry support (time window)
- Ticket type capacity limits
- Entry time predictions

### Version 1.2 (Professional)
- PDF ticket templates
- Badge printing support
- Custom QR branding

### Version 2.0 (Enterprise)
- Multi-venue management
- Real-time sync (when online)
- Mobile scanner app
- Email ticket delivery
