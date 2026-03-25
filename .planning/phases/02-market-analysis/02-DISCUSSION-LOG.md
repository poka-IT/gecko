# Phase 2: Market Analysis - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-25
**Phase:** 02-market-analysis
**Areas discussed:** Date Range Selection, Contact Selection, Results Layout, Other Contacts Discovery, Export Format
**Mode:** Auto (--auto flag, all recommended defaults selected)

---

## Date Range Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Calendar range picker (`calendar_date_picker2`) | Single widget for start+end dates, validated by Ginkgo | ✓ |
| Two separate `showDatePicker` calls | Simpler, no new dependency, but worse UX | |
| Text input with date parsing | Keyboard-friendly but error-prone | |

**User's choice:** [auto] Calendar range picker with preset shortcuts (30d, 90d, 365d)
**Notes:** Ginkgo already uses and validated `calendar_date_picker2`. Includes 365-day max enforcement.

---

## Contact Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Multi-select checkboxes from favorites | Simple, leverages existing `allContactsProvider` | ✓ |
| Search-and-add flow | More flexible but more complex UX | |
| Analyze all favorites by default | Simplest but no control over selection | |

**User's choice:** [auto] Multi-select checkboxes from favorites with Select All toggle
**Notes:** At least one contact required. Shows avatar + name + address per row.

---

## Results Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Cards per contact + aggregate summary | Follows Ginkgo pattern, good mobile UX | ✓ |
| Table view | Compact but less visual | |
| Expandable list with transaction details | Rich but complex, scope creep risk | |

**User's choice:** [auto] Cards per contact with aggregate summary card at top
**Notes:** Amounts in G1 currency format. Card per contact shows sent/received/count.

---

## Other Contacts Discovery

| Option | Description | Selected |
|--------|-------------|----------|
| Separate section below selected contacts | Clear distinction selected vs discovered | ✓ |
| Inline with selected contacts (marked differently) | Compact but potentially confusing | |
| Hidden behind expandable toggle | Saves space but discoverable | |

**User's choice:** [auto] Separate section below selected contacts with name/address/totals
**Notes:** Names resolved via Cesium+ or Squid when available.

---

## Export Format

| Option | Description | Selected |
|--------|-------------|----------|
| Structured markdown (header, table, totals, other contacts) | Comprehensive and readable | ✓ |
| Simple bullet list | Easy to generate but less structured | |
| Raw CSV format | Machine-readable but not user-friendly for clipboard | |

**User's choice:** [auto] Structured markdown with header, per-contact table, aggregate totals, other contacts
**Notes:** Clipboard copy with snackbar confirmation. No file export.

---

## Claude's Discretion

- Provider architecture for analysis aggregation
- Exact UI layout and card styling
- Bottom sheet vs full screen for date/contact selection
- Loading state presentation
- Squid offline graceful degradation

## Deferred Ideas

None — discussion stayed within phase scope
