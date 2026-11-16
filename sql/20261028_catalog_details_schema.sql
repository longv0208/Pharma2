-- Approved catalog metadata for verified product images, topics and source records.
-- User approved this new table on 2026-10-28. Run before the matching product migration.
-- Existing product, inventory and order tables are not altered.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS product_catalog_details (
    product_id BIGINT NOT NULL,
    image_path VARCHAR(255) NOT NULL,
    catalog_visible TINYINT(1) NOT NULL DEFAULT 1,
    health_care TINYINT(1) NOT NULL DEFAULT 0,
    mother_baby TINYINT(1) NOT NULL DEFAULT 0,
    source_url VARCHAR(1000) NOT NULL,
    price_source_url VARCHAR(1000) NOT NULL,
    verified_at DATE NOT NULL,
    promotion_label VARCHAR(150) DEFAULT NULL,
    promotion_source_url VARCHAR(1000) DEFAULT NULL,
    promotion_from DATE DEFAULT NULL,
    promotion_until DATE DEFAULT NULL,
    PRIMARY KEY (product_id),
    CONSTRAINT fk_catalog_details_product FOREIGN KEY (product_id)
        REFERENCES products (product_id),
    CONSTRAINT chk_catalog_visibility CHECK (catalog_visible IN (0, 1)),
    CONSTRAINT chk_catalog_health CHECK (health_care IN (0, 1)),
    CONSTRAINT chk_catalog_mother_baby CHECK (mother_baby IN (0, 1)),
    CONSTRAINT chk_catalog_promotion_dates CHECK (
        promotion_until IS NULL OR promotion_from IS NULL OR promotion_until >= promotion_from
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
