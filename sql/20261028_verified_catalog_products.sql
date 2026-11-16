-- Verified catalog expansion: 20 medicines, checked 2026-10-28.
-- Run after 20261028_catalog_details_schema.sql. Insert only; preserve existing rows.
-- No inventory, orders or promotion offers are fabricated.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 1, 'Hapacol 150', 'HAPACOL150', NULL, 'Paracetamol', '150mg/gói', 'Thuốc bột pha uống', 'Công ty Cổ phần Dược Hậu Giang', '893100040923', 'Hapacol 150. Hộp 24 Gói x 0.9g. Thành phần: Paracetamol.', 'Giảm đau và hạ sốt; dạng bột dành cho trẻ em theo hướng dẫn của thuốc.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Hộp', 38600, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAPACOL150');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAPACOL150.png', 1, 0, 1, 'https://nhathuoclongchau.com.vn/thuoc/hapacol-150-3531.html', 'https://nhathuoclongchau.com.vn/thuoc/hapacol-150-3531.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAPACOL150'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 1, 'Hapacol 250', 'HAPACOL250', NULL, 'Paracetamol', '250mg/gói', 'Thuốc bột pha uống', 'Công ty Cổ phần Dược Hậu Giang', '893100041023', 'Hapacol 250. Hộp 24 Gói x 1g. Thành phần: Paracetamol.', 'Giảm đau và hạ sốt; chọn hàm lượng cho trẻ theo cân nặng và hướng dẫn của thuốc.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Hộp', 47000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAPACOL250');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAPACOL250.png', 1, 0, 1, 'https://nhathuoclongchau.com.vn/thuoc/hapacol-250mg-3530.html', 'https://nhathuoclongchau.com.vn/thuoc/hapacol-250mg-3530.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAPACOL250'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 2, 'Hapacol 150 Flu', 'HAPACOL150FLU', NULL, 'Paracetamol + Clorpheniramin maleat', '150mg + 1mg/gói', 'Thuốc bột sủi bọt', 'Công ty Cổ phần Dược Hậu Giang', '893100626724', 'Hapacol 150 Flu. Hộp 24 gói. Thành phần: Paracetamol + Clorpheniramin maleat.', 'Giảm sốt, đau nhức, sổ mũi trong các triệu chứng cảm.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Gói', 1696, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAPACOL150FLU');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAPACOL150FLU.jpg', 1, 0, 1, 'https://nhathuoclongchau.com.vn/thuoc/hapacol-flu-150mg-3522.html', 'https://nhathuoclongchau.com.vn/thuoc/hapacol-flu-150mg-3522.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAPACOL150FLU'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 2, 'Hapacol 250 Flu', 'HAPACOL250FLU', NULL, 'Paracetamol + Clorpheniramin maleat', '250mg + 1mg/gói', 'Cốm sủi bọt', 'Công ty Cổ phần Dược Hậu Giang', '893100263000', 'Hapacol 250 Flu. Hộp 24 Gói. Thành phần: Paracetamol + Clorpheniramin maleat.', 'Giảm các biểu hiện cảm sốt, sổ mũi và đau nhức.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Gói', 2146, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAPACOL250FLU');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAPACOL250FLU.jpg', 1, 0, 1, 'https://nhathuoclongchau.com.vn/thuoc/hapacol-flu-250mg-3521.html', 'https://nhathuoclongchau.com.vn/thuoc/hapacol-flu-250mg-3521.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAPACOL250FLU'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 2, 'Hapacol 325 Flu', 'HAPACOL325FLU', NULL, 'Paracetamol + Clorpheniramin maleat', '325mg + 2mg/gói', 'Cốm sủi bọt', 'CÔNG TY CỔ PHẦN DƯỢC HẬU GIANG', '893100140324', 'Hapacol 325 Flu. Hộp 24 Gói x 1.5g. Thành phần: Paracetamol + Clorpheniramin maleat.', 'Điều trị triệu chứng sốt, đau đầu và sổ mũi do cảm.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Hộp', 52800, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAPACOL325FLU');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAPACOL325FLU.png', 1, 0, 1, 'https://nhathuoclongchau.com.vn/thuoc/hapacol-325mg-flu-dhg-24-goi-20664.html', 'https://nhathuoclongchau.com.vn/thuoc/hapacol-325mg-flu-dhg-24-goi-20664.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAPACOL325FLU'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 1, 'Hapacol 650 Extra', 'HAPACOL650EXTRA', NULL, 'Paracetamol + Cafein', '650mg + 65mg/viên', 'Viên nén', 'CÔNG TY CỔ PHẦN DƯỢC HẬU GIANG', '893100263100', 'Hapacol 650 Extra. Hộp 10 vỉ x 10 viên. Thành phần: Paracetamol + Cafein.', 'Giảm các cơn đau như đau đầu, đau răng và đau cơ.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Viên', 714, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAPACOL650EXTRA');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAPACOL650EXTRA.png', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/hapacol-650-extra-dhg-10x10-28113.html', 'https://nhathuoclongchau.com.vn/thuoc/hapacol-650-extra-dhg-10x10-28113.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAPACOL650EXTRA'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 3, 'Hamett 3g', 'HAMETT3', NULL, 'Diosmectit', '3g/gói', 'Bột pha hỗn dịch uống', 'Công ty Cổ phần Dược Hậu Giang', 'VD-20555-14', 'Hamett 3g. Hộp 24 gói. Thành phần: Diosmectit.', 'Điều trị triệu chứng tiêu chảy; phối hợp bù nước và điện giải theo hướng dẫn.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Tiêu chảy cần bù nước và điện giải. Trường hợp nặng, kéo dài hoặc có dấu hiệu mất nước cần được khám và hướng dẫn điều trị.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Gói', 2300, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'HAMETT3');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/HAMETT3.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/hamett-3g-3533.html', 'https://nhathuoclongchau.com.vn/thuoc/hamett-3g-3533.html', '2026-10-28'
FROM products p WHERE p.sku = 'HAMETT3'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 4, 'Berocca 10 viên', 'BEROCCA10', NULL, 'Vitamin nhóm B + Vitamin C + Calci + Magnesi + Kẽm', 'Vitamin C 500mg; Calci 100mg; Magnesi 100mg; Kẽm 10mg', 'Viên nén sủi bọt', 'BAYER', '899100177223', 'Berocca 10 viên. Tuýp 10 Viên. Thành phần: Vitamin nhóm B + Vitamin C + Calci + Magnesi + Kẽm.', 'Bổ sung vitamin và khoáng chất khi thiếu hụt hoặc có nhu cầu tăng.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Tuýp', 75000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'BEROCCA10');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/BEROCCA10.jpg', 1, 1, 0, 'https://nhathuoclongchau.com.vn/thuoc/berocca-1515.html', 'https://nhathuoclongchau.com.vn/thuoc/berocca-1515.html', '2026-10-28'
FROM products p WHERE p.sku = 'BEROCCA10'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 4, 'Farzincol 10mg', 'FARZINCOL10', NULL, 'Kẽm gluconat (tương đương kẽm nguyên tố)', '70mg (tương đương kẽm 10mg)/viên', 'Viên nén', 'CÔNG TY CỔ PHẦN DƯỢC PHẨM DƯỢC LIỆU PHARMEDIC', '893110881724', 'Farzincol 10mg. Hộp 10 vỉ x 10 viên. Thành phần: Kẽm gluconat (tương đương kẽm nguyên tố).', 'Điều trị và phòng tình trạng thiếu kẽm theo chỉ định chuyên môn.', 'Thuốc kê đơn: sử dụng theo đơn của bác sĩ và tờ hướng dẫn kèm bao bì; không tự điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KE_DON', 'Hộp', 65000, 0, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'FARZINCOL10');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/FARZINCOL10.png', 1, 1, 1, 'https://nhathuoclongchau.com.vn/thuoc/farzincol-10mg-3786.html', 'https://www.pharmacity.vn/thuoc-bo-sung-kem-farzincol-10mg.html', '2026-10-28'
FROM products p WHERE p.sku = 'FARZINCOL10'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 1, 'Efferalgan 500mg', 'EFFERALGAN500', NULL, 'Paracetamol', '500mg/viên', 'Viên nén sủi bọt', 'UPSA SAS', '300100011324', 'Efferalgan 500mg. Hộp 4 Vỉ x 4 Viên. Thành phần: Paracetamol.', 'Điều trị các triệu chứng đau và sốt.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không phối hợp nhiều thuốc cùng chứa paracetamol; quá liều có thể gây tổn thương gan. Hỏi dược sĩ để chọn đúng hàm lượng và liều dùng.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Hộp', 51990, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'EFFERALGAN500');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/EFFERALGAN500.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/efferalgan-500mg-1620.html', 'https://nhathuoclongchau.com.vn/thuoc/efferalgan-500mg-1620.html', '2026-10-28'
FROM products p WHERE p.sku = 'EFFERALGAN500'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 6, 'Clorpheniramin 4mg DHG', 'CLORPHENIRAMIN4DHG', NULL, 'Clorpheniramin maleat', '4mg/viên', 'Viên nén', 'Công ty Cổ phần Dược Hậu Giang', 'VD-21132-14', 'Clorpheniramin 4mg DHG. Hộp 10 Vỉ x 20 Viên. Thành phần: Clorpheniramin maleat.', 'Giảm biểu hiện viêm mũi dị ứng, chảy nước mũi và một số triệu chứng dị ứng.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Viên', 104, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'CLORPHENIRAMIN4DHG');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/CLORPHENIRAMIN4DHG.png', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/clorpheniramin-4-200v-4228.html', 'https://nhathuoclongchau.com.vn/thuoc/clorpheniramin-4-200v-4228.html', '2026-10-28'
FROM products p WHERE p.sku = 'CLORPHENIRAMIN4DHG'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 3, 'Smecta 3g', 'SMECTA3', NULL, 'Diosmectit', '3g/gói', 'Bột pha hỗn dịch uống', 'BEAUFOUR IPSEN INDUSTRIE', 'VN-19485-15', 'Smecta 3g. Hộp 30 Gói x 3g. Thành phần: Diosmectit.', 'Điều trị triệu chứng tiêu chảy và bảo vệ niêm mạc đường tiêu hóa theo hướng dẫn.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Tiêu chảy cần bù nước và điện giải. Trường hợp nặng, kéo dài hoặc có dấu hiệu mất nước cần được khám và hướng dẫn điều trị.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Gói', 5633, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'SMECTA3');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/SMECTA3.png', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/smecta-2236.html', 'https://nhathuoclongchau.com.vn/thuoc/smecta-2236.html', '2026-10-28'
FROM products p WHERE p.sku = 'SMECTA3'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 3, 'Kremil-S', 'KREMILS', NULL, 'Nhôm hydroxyd + Magnesi hydroxyd + Simethicon', '178mg + 233mg + 30mg/viên', 'Viên nén nhai', 'Công ty TNHH United International Pharma', '893100353323', 'Kremil-S. Hộp 10 Vỉ x 10 Viên. Thành phần: Nhôm hydroxyd + Magnesi hydroxyd + Simethicon.', 'Giảm triệu chứng tăng acid dạ dày, nóng rát và đầy hơi.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Viên', 1200, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'KREMILS');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/KREMILS.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/kremils-s-3315.html', 'https://nhathuoclongchau.com.vn/thuoc/kremils-s-3315.html', '2026-10-28'
FROM products p WHERE p.sku = 'KREMILS'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 2, 'Eugica', 'EUGICA', NULL, 'Eucalyptol + Tinh dầu tần + Tinh dầu gừng + Menthol', '100mg + 0,18mg + 0,5mg + 0,5mg/viên', 'Viên nang mềm', 'Công ty Cổ phần Dược Hậu Giang', '893100512124', 'Eugica. Hộp 10 Vỉ x 10 Viên. Thành phần: Eucalyptol + Tinh dầu tần + Tinh dầu gừng + Menthol.', 'Giảm ho, long đờm và các triệu chứng cảm, sổ mũi theo hướng dẫn.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Viên', 730, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'EUGICA');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/EUGICA.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/eugica-vien-uong-dieu-tri-ho-cam-cum-490.html', 'https://nhathuoclongchau.com.vn/thuoc/eugica-vien-uong-dieu-tri-ho-cam-cum-490.html', '2026-10-28'
FROM products p WHERE p.sku = 'EUGICA'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 7, 'Canesten Cream 1% 20g', 'CANESTEN20', NULL, 'Clotrimazol', '10mg/g (1%); tuýp 20g', 'Kem bôi da', 'Encube Ethicals Private Ltd', '890100002524', 'Canesten Cream 1% 20g. Tuýp X 20g. Thành phần: Clotrimazol.', 'Điều trị nhiễm nấm ngoài da do các tác nhân nhạy cảm.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Tuýp', 59000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'CANESTEN20');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/CANESTEN20.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/canesten-cream-4398.html', 'https://nhathuoclongchau.com.vn/thuoc/canesten-cream-4398.html', '2026-10-28'
FROM products p WHERE p.sku = 'CANESTEN20'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 7, 'Differin Cream 0.1% 30g', 'DIFFERIN30', NULL, 'Adapalen', '0,1%; tuýp 30g', 'Kem bôi da', 'LABORATOIRES GALDERMA', 'VN-19652-16', 'Differin Cream 0.1% 30g. Tuýp X 30g. Thành phần: Adapalen.', 'Điều trị tại chỗ mụn trứng cá theo đơn của bác sĩ.', 'Thuốc kê đơn: sử dụng theo đơn của bác sĩ và tờ hướng dẫn kèm bao bì; không tự điều trị.', 'Chỉ dùng ngoài da theo đơn; tránh mắt và niêm mạc. Không dùng trong thai kỳ; đọc đầy đủ chống chỉ định trong tờ hướng dẫn.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KE_DON', 'Tuýp', 172000, 0, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'DIFFERIN30');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/DIFFERIN30.png', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/differin-0130mg-17372.html', 'https://www.pharmacity.vn/differin-cream-01-30g.html', '2026-10-28'
FROM products p WHERE p.sku = 'DIFFERIN30'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 3, 'Gaviscon 10ml', 'GAVISCON10', NULL, 'Natri alginat + Natri bicarbonat + Calci carbonat', '500mg + 267mg + 160mg/10ml', 'Hỗn dịch uống', 'Reckitt Benckiser Healthcare', '500100136224', 'Gaviscon 10ml. Hộp 24 Gói X 10ml. Thành phần: Natri alginat + Natri bicarbonat + Calci carbonat.', 'Giảm các triệu chứng trào ngược dạ dày - thực quản như ợ nóng và ợ chua.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Gói', 8000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'GAVISCON10');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/GAVISCON10.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/gaviscon-927-3656.html', 'https://nhathuoclongchau.com.vn/thuoc/gaviscon-927-3656.html', '2026-10-28'
FROM products p WHERE p.sku = 'GAVISCON10'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 3, 'Gaviscon Dual Action 10ml', 'GAVISCONDUAL10', NULL, 'Natri alginat + Natri bicarbonat + Calci carbonat', '500mg + 213mg + 325mg/10ml', 'Hỗn dịch uống', 'RECKITT BENCKISER HEALTHCARE (UK) LIMITED', '500100792324', 'Gaviscon Dual Action 10ml. Hộp 24 Gói X 10ml. Thành phần: Natri alginat + Natri bicarbonat + Calci carbonat.', 'Giảm ợ nóng, ợ chua và khó tiêu liên quan trào ngược dạ dày - thực quản.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Gói', 10000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'GAVISCONDUAL10');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/GAVISCONDUAL10.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/gaviscon-dual-action-24-goi-x-10ml-17619.html', 'https://nhathuoclongchau.com.vn/thuoc/gaviscon-dual-action-24-goi-x-10ml-17619.html', '2026-10-28'
FROM products p WHERE p.sku = 'GAVISCONDUAL10'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 5, 'Dorithricin', 'DORITHRICIN20', NULL, 'Tyrothricin + Benzalkonium clorid + Benzocain', '0,5mg + 1mg + 1,5mg/viên', 'Viên nén ngậm', 'MEDICE ARZNEIMITTEL PUTTER GMBH & CO.KG', '400100014224', 'Dorithricin. Hộp 2 Vỉ x 10 Viên. Thành phần: Tyrothricin + Benzalkonium clorid + Benzocain.', 'Điều trị triệu chứng nhiễm khuẩn miệng - họng, đau họng và nuốt khó.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Đọc đầy đủ thận trọng và tương tác trong tờ hướng dẫn. Hỏi nhân viên y tế trước khi dùng cho trẻ em, người mang thai hoặc đang cho con bú.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Hộp', 72000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'DORITHRICIN20');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/DORITHRICIN20.png', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/dorithricin-3952.html', 'https://nhathuoclongchau.com.vn/thuoc/dorithricin-3952.html', '2026-10-28'
FROM products p WHERE p.sku = 'DORITHRICIN20'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

INSERT INTO products (category_id, product_name, sku, barcode, active_ingredient, strength, dosage_form, manufacturer, registration_number, short_description, indication, usage_instruction, warnings, contraindications, product_type, selling_unit, selling_price, online_sale_allowed, status)
SELECT 2, 'Rhinex 0.05% 15ml', 'RHINEX005', NULL, 'Naphazolin nitrat', '0,05% (7,5mg/15ml)', 'Dung dịch nhỏ mũi', 'CÔNG TY CỔ PHẦN DƯỢC PHẨM TW 25', '893100631124', 'Rhinex 0.05% 15ml. Chai x 15ml. Thành phần: Naphazolin nitrat.', 'Giảm sung huyết mũi trong viêm mũi, viêm xoang và cảm lạnh theo hướng dẫn.', 'Đọc tờ hướng dẫn kèm bao bì; dùng đúng dạng thuốc và hỏi dược sĩ về cách dùng phù hợp. Không tự thay đổi liều điều trị.', 'Không tự dùng kéo dài. Chai thuốc và hàm lượng phải phù hợp với độ tuổi; hỏi dược sĩ trước khi dùng cho trẻ.', 'Không dùng khi dị ứng với hoạt chất hoặc thành phần tá dược. Các chống chỉ định khác: xem tờ hướng dẫn sử dụng của đúng sản phẩm.', 'KHONG_KE_DON', 'Chai', 6000, 1, 'HOAT_DONG'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'RHINEX005');
INSERT INTO product_catalog_details (product_id, image_path, catalog_visible, health_care, mother_baby, source_url, price_source_url, verified_at)
SELECT p.product_id, '/images/products/RHINEX005.jpg', 1, 0, 0, 'https://nhathuoclongchau.com.vn/thuoc/rhinex-005-2410.html', 'https://nhathuoclongchau.com.vn/thuoc/rhinex-005-2410.html', '2026-10-28'
FROM products p WHERE p.sku = 'RHINEX005'
AND NOT EXISTS (SELECT 1 FROM product_catalog_details m WHERE m.product_id = p.product_id);

COMMIT;
