-- Product barcode is unused. Drop the column and its unique index.
-- Existing barcode values are discarded; no other table references them.
SET @db := DATABASE();
SET @has_barcode := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'products' AND COLUMN_NAME = 'barcode'
);
SET @sql := IF(@has_barcode = 1,
  'ALTER TABLE products DROP COLUMN barcode',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
