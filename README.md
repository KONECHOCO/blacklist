# blacklist

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database access (admin)

The server database (SQLite) can be browsed and queried with a web page that is
**not public**: it only listens on the server itself and is reached through an SSH tunnel.

1. Open the tunnel from your PC (keep the window open):
   `ssh -N -L 8095:127.0.0.1:8095 choco@23.88.32.156`
2. Open http://localhost:8095 in the browser.

Tables: `reports` (community reports), `external` (FTC, BNETZA, CURATED seed data),
`removals` (GDPR removal requests), `allowlist` (numbers never published),
`comment_flags` (flagged comments).

## Backups

Every night at 03:30 (cron of user `choco` on the VPS) `python -m app.backup` saves the data that
cannot be rebuilt — `reports`, `comment_flags`, `removals`, `allowlist` — to
`~/apps/blacklist-api/data/backups/blacklist_YYYY-MM-DD_HHMM.db.gz` (last 30 days kept).
Imported data (FTC, BNetzA, curated seed) is re-imported automatically.

Copy the latest backup to your PC:
`scp "choco@23.88.32.156:apps/blacklist-api/data/backups/*.gz" .`

Restore: `gunzip` the file and copy its tables back into `data/blacklist.db` (stop the container first).
