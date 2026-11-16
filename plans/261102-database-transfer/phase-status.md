# Database transfer snapshot

Status: Complete (2026-11-02)

- Read the active DBContext configuration and connected to the actual
  `127.0.0.1:3306/pharmaflow2` database on MySQL 8.4.9.
- Exported schema and all current rows with mysqldump using a consistent
  InnoDB snapshot, UTF-8, explicit INSERT column names and primary-key order.
- Added `sql/pharmaflow2_full_20261102.sql` for a fresh destination database.
  No DROP/TRUNCATE statements or MySQL server account definitions are included.
- Updated README setup and added `docs/database-transfer.md` with Workbench
  and Windows Command Prompt import instructions, DBContext settings and
  the requirement to copy the bundled product image files.
- Restored the delivered SQL into an isolated, uniquely named temporary
  database on MySQL 8.4.9. Verified 31 tables and all 271 rows, including
  36 products and 20 catalog metadata rows.
- Compared normalized SHOW CREATE TABLE output and exact column metadata
  for all tables. MySQL may display redundant CHARACTER SET utf8mb4 after
  restore; normalization removes only that display difference when followed
  by an explicit matching utf8mb4 collation.
- SHA-256 of deterministically exported row data matched source and restore:
  `8b0baa907ea3c104de16692ad68eb7bfdf6ba283d5f6f0e48fa5339cf000923d`.
- Checked all 49 foreign keys for orphan rows and verified all 20 database
  image paths point to files bundled in the source tree.
- Removed all owned temporary validation databases; did not modify the
  source database, Java code or existing seed/migration files.
- No Java build was run because changes contain SQL and documentation only.
