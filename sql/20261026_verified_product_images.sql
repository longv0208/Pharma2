-- Approved replacement of three demonstration catalog entries.
-- Apply after db_vi_full.sql to the application's configured database.
-- The old identities, inventory batches and historical references are retained.
-- New products have no inventory until a real goods receipt is recorded.
-- Prices below are inherited demo prices, not verified commercial quotations.
-- Barcode is NULL rather than reusing a fabricated barcode.
-- Sources and image checks: docs/product-images.md.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO products (
    category_id, product_name, sku, barcode, active_ingredient, strength,
    dosage_form, manufacturer, registration_number, short_description,
    indication, usage_instruction, warnings, contraindications,
    product_type, selling_unit, selling_price, online_sale_allowed, status
)
SELECT
    2, 'Bepamin 500mg/2mg', 'BEPAMIN500', NULL,
    'Paracetamol + Clorpheniramin maleat', '500mg + 2mg',
    'Viên nén', 'Công ty Liên doanh Meyer-BPC', 'VD-34412-20',
    'Bepamin của Meyer-BPC, hộp 25 vỉ x 20 viên nén. Mỗi viên chứa paracetamol 500mg và clorpheniramin maleat 2mg.',
    'Giảm sốt và các triệu chứng cảm cúm.',
    'Dùng theo tờ hướng dẫn sử dụng của nhà sản xuất và tư vấn của nhân viên y tế.',
    NULL, NULL, 'KHONG_KE_DON', 'Hộp', original.selling_price, 1, 'HOAT_DONG'
FROM products original
WHERE original.sku = 'COLD001'
  AND NOT EXISTS (SELECT 1 FROM products existing WHERE existing.sku = 'BEPAMIN500');

INSERT INTO products (
    category_id, product_name, sku, barcode, active_ingredient, strength,
    dosage_form, manufacturer, registration_number, short_description,
    indication, usage_instruction, warnings, contraindications,
    product_type, selling_unit, selling_price, online_sale_allowed, status
)
SELECT
    2, 'Cozz DHG', 'COZZDHG', NULL,
    'Eucalyptol + Menthol + Tinh dầu tần + Tinh dầu gừng',
    '100mg + 0,5mg + 0,18mg + 0,5mg',
    'Viên nang mềm', 'Công ty Cổ phần Dược Hậu Giang', NULL,
    'Cozz của DHG Pharma, hộp 10 vỉ x 10 viên nang mềm, chứa eucalyptol, menthol, tinh dầu tần và tinh dầu gừng.',
    'Giảm ho, sổ mũi và cảm do lạnh; làm dịu họng.',
    'Dùng theo tờ hướng dẫn sử dụng của nhà sản xuất và tư vấn của nhân viên y tế.',
    'Cần đọc kỹ phần chống chỉ định và thận trọng trong tờ hướng dẫn sử dụng.',
    'Không dùng cho trẻ dưới 30 tháng tuổi, phụ nữ có thai hoặc đang cho con bú; xem đầy đủ chống chỉ định trên nhãn.',
    'KHONG_KE_DON', 'Hộp', original.selling_price, 1, 'HOAT_DONG'
FROM products original
WHERE original.sku = 'DISC001'
  AND NOT EXISTS (SELECT 1 FROM products existing WHERE existing.sku = 'COZZDHG');

INSERT INTO products (
    category_id, product_name, sku, barcode, active_ingredient, strength,
    dosage_form, manufacturer, registration_number, short_description,
    indication, usage_instruction, warnings, contraindications,
    product_type, selling_unit, selling_price, online_sale_allowed, status
)
SELECT
    6, 'Corityne 10mg', 'CORITYNE10', NULL,
    'Loratadin', '10mg', 'Viên nén', 'Công ty Liên doanh Meyer-BPC', 'VD-29428-18',
    'Corityne của Meyer-BPC chứa loratadin 10mg, hộp 3 vỉ x 10 viên nén.',
    'Giảm triệu chứng viêm mũi dị ứng và mề đay.',
    'Dùng theo tờ hướng dẫn sử dụng của nhà sản xuất và tư vấn của nhân viên y tế.',
    NULL, NULL, 'KHONG_KE_DON', 'Hộp', original.selling_price, 1, 'HOAT_DONG'
FROM products original
WHERE original.sku = 'TEST01'
  AND NOT EXISTS (SELECT 1 FROM products existing WHERE existing.sku = 'CORITYNE10');

UPDATE products original
JOIN products replacement ON replacement.sku = 'BEPAMIN500'
SET original.status = 'NGUNG_HOAT_DONG', original.online_sale_allowed = 0
WHERE original.sku = 'COLD001'
  AND original.product_name = 'Thuốc cảm cúm tổng hợp'
  AND (original.status <> 'NGUNG_HOAT_DONG' OR original.online_sale_allowed <> 0);

UPDATE products original
JOIN products replacement ON replacement.sku = 'COZZDHG'
SET original.status = 'NGUNG_HOAT_DONG', original.online_sale_allowed = 0
WHERE original.sku = 'DISC001'
  AND original.product_name = 'Thuốc cảm đã ngừng kinh doanh'
  AND (original.status <> 'NGUNG_HOAT_DONG' OR original.online_sale_allowed <> 0);

UPDATE products original
JOIN products replacement ON replacement.sku = 'CORITYNE10'
SET original.status = 'NGUNG_HOAT_DONG', original.online_sale_allowed = 0
WHERE original.sku = 'TEST01'
  AND original.product_name = 'kiểm thử'
  AND (original.status <> 'NGUNG_HOAT_DONG' OR original.online_sale_allowed <> 0);

COMMIT;
