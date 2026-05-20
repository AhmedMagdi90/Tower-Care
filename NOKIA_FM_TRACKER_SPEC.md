# Nokia FM Tracker Specification

Production Flutter mobile app for a telecom engineer monitoring Nokia FM trouble tickets across Sohag, Qena, Luxor, and Aswan.

## Core Features

- Import a one-time Nokia site list Excel workbook into SQLite.
- Import the daily Nokia FM report from sheet index 0 (`Down Cells_1`) and sheet index 1 (`Down Site_2`).
- Enrich imported tickets with governorate by matching the Nokia `Node` value against the local `sites` table.
- Upsert down-site and down-cell records by TT number while preserving action history.
- Browse filtered down-site and down-cell tickets by governorate, search text, severity, duration, and outage category or alert group.
- Add action history with engineer name, timestamp, and action text.
- Share filtered results or individual ticket summaries to WhatsApp/share sheet.
- Export filtered results or individual ticket records to Excel.

## Required Tables

- `sites(site_name PK, governorate, lat, long, site_type, power_type, transmission, num_sectors, address)`
- `down_sites(id PK autoincrement, node, tt_number UNIQUE, governorate, first_occ, outage_cat, alert_group, severity, icd_status, handling_comment, imported_at)`
- `down_cells(id PK autoincrement, node, tt_number UNIQUE, governorate, first_occ, cell_number, alert_group, severity, icd_status, imported_at)`
- `actions(id PK autoincrement, tt_number, tt_type, engineer_name, action_text, created_at)`

## UI

- Bottom tabs: Down Sites, Down Cells, Import.
- Down Sites: stats, governorate chips, search, advanced filters, ticket cards, actions, share, export.
- Down Cells: same flow with alert group filtering and unique affected-site stat.
- Import: last import timestamp, import buttons, and database counts.

## Notes

- The app adds `shared_preferences` in addition to the requested packages because the specification requires storing `last_import`.
- Excel column matching is case-insensitive and ignores spaces, underscores, and punctuation to handle real Nokia workbook header variants.
