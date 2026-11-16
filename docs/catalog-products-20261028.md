# Bổ sung 20 sản phẩm ngày 28/10/2026

Đã nhập trực tiếp vào MySQL `pharmaflow2`: 20 sản phẩm mới, ID 17–36,
và 20 dòng `product_catalog_details`. Tổng database hiện có 36 sản phẩm;
30 sản phẩm đang hiển thị trên cửa hàng. Bảng phụ được người dùng phê duyệt
trước khi tạo; không sửa cấu trúc các bảng sản phẩm, kho và đơn hàng hiện có.

## Dữ liệu và ảnh

Danh sách đầy đủ, hoạt chất, hàm lượng, nhà sản xuất, quy cách, giá theo đơn vị,
phân loại, URL nguồn và SHA-256 ảnh nằm trong
[`catalog-products-20261028.json`](../sql/catalog-products-20261028.json).

- Ảnh gốc trong `sql/IMG Product/<tên thuốc>/<SKU>.png` hoặc `.jpg`.
  Mỗi thư mục có `source.md` ghi nguồn sản phẩm, nguồn ảnh, nguồn giá,
  ngày đối chiếu và checksum. Đã mở ảnh đối chiếu tên/hàm lượng trên bao bì.
- Bản dùng cho website nằm trong `web/images/products/`, có cùng nội dung
  với ảnh gốc. Đường dẫn ảnh được lưu trong MySQL thay vì thêm nhánh SKU vào Java.
- Giá là giá công khai của trang sản phẩm tại ngày 28/10/2026, theo đúng đơn vị
  niêm yết (hộp, viên, gói, tuýp hoặc chai), không quy đổi giá hộp thành giá viên.
  18 giá lấy từ Long Châu; Farzincol và Differin lấy giá công khai từ Pharmacity.
  Trang chi tiết thuốc có liên kết nguồn thông tin, nguồn giá và ngày kiểm tra.
- Không tạo barcode hoặc số đăng ký giả. Số đăng ký có trong bản nhập được chép
  từ thông tin nguồn; không phải kết luận về hiệu lực pháp lý hiện tại.
- **Không tạo lô, số lượng tồn hoặc hạn dùng giả.** Cả 20 sản phẩm mới có tồn
  khả dụng bằng 0 và không thể thêm vào giỏ. Cần nhập lô thực tế bằng quy trình
  nhập kho của dự án trước khi bán các sản phẩm không kê đơn.
- Hai sản phẩm kê đơn (Farzincol, Differin) chỉ dùng để tra cứu;
  `online_sale_allowed=0`, không thể đặt hàng/thanh toán trực tuyến.
- Các sản phẩm cũ giữ nguyên. Giá mẫu của các đợt nhập trước không được xem là
  giá thương mại đã xác minh trong đợt bổ sung này.

## Chủ đề và bộ lọc

`ProductServlet` nhận `q`, `category`, `type`, `tag`, `promo`, `page`.
`ProductDAO` dùng cùng điều kiện cho truy vấn đếm và truy vấn danh sách;
phân trang giữ nguyên toàn bộ bộ lọc.

| Bộ lọc | Số kết quả sau triển khai |
| --- | ---: |
| Tất cả | 30 |
| Không kê đơn | 28 |
| Kê đơn, chỉ tra cứu | 2 |
| Hạn chế | 0 |
| Chăm sóc sức khỏe | 4 |
| Mẹ & Bé | 6 |
| Khuyến mãi đang áp dụng | 0 |
| Giảm đau và hạ sốt | 6 |
| Cảm lạnh và cúm | 7 |
| Tiêu hóa | 6 |
| Vitamin và thực phẩm bổ sung | 4 |
| Kháng sinh | 1 |
| Dị ứng | 3 |
| Da liễu | 3 |

`tag=health` nhận sản phẩm có `health_care=1` và các sản phẩm trong danh mục
Vitamin và thực phẩm bổ sung hiện có. `tag=mother-baby` nhận sáu sản phẩm
có cờ tương ứng: năm dạng Hapacol dành cho trẻ và Farzincol. Chủ đề chỉ là
phân nhóm danh mục, không thay thế chỉ định hoặc hướng dẫn dùng theo độ tuổi.

Không nhập thuốc hạn chế chỉ để lấp đầy bộ lọc. Bộ lọc này có trạng thái rỗng
và đã được kiểm thử với dữ liệu tạm thời. Danh mục Kháng sinh có Dorithricin,
thuốc chứa tyrothricin có tác dụng kháng khuẩn tại chỗ theo nguồn sản phẩm.

**Không sao chép ưu đãi của nhà thuốc khác thành ưu đãi PharmaFlow.** Chưa có
chương trình của cửa hàng được xác nhận nên không nhập khuyến mãi thật.
`promo=1` chỉ nhận sản phẩm không kê đơn được phép bán online, có đủ
`promotion_label`, `promotion_source_url`, `promotion_from`, `promotion_until`
và ngày hiện tại nằm trong thời hạn. Đã kiểm thử chương trình còn hạn, hết hạn,
chưa bắt đầu, thiếu nguồn và loại trừ thuốc kê đơn bằng bảng TEMPORARY.
Các trường này chỉ phục vụ lọc chương trình có bằng chứng; chưa triển khai
cơ chế tính giá giảm tự động.

## Áp dụng trên một database khác

Sao lưu trước, dùng database đã có schema nền và các danh mục ID 1–7 của dự án.
Chạy hai file theo thứ tự bằng MySQL client hoặc Workbench:

1. [`20261028_catalog_details_schema.sql`](../sql/20261028_catalog_details_schema.sql)
2. [`20261028_verified_catalog_products.sql`](../sql/20261028_verified_catalog_products.sql)

Migration sản phẩm chạy trong transaction, chỉ INSERT khi SKU/chìa khóa metadata
chưa tồn tại. Chạy lại trên máy này vẫn có 36 sản phẩm và 20 metadata, không
tạo trùng và không ghi đè thông tin đã có. Khi chuyển sang database khác, ID
sản phẩm có thể khác vì metadata nối theo SKU thay vì gán cứng ID mới.

Mã Java mới cần bảng metadata trước khi khởi động. Build WAR bằng Ant `dist`
và triển khai cả `web/images/products` cùng mã nguồn. Bản preview hiện chạy tại
<http://127.0.0.1:18080/Pharma_Flow/products>.

## Kiểm tra đã thực hiện

- Ant `dist` thành công; toàn bộ JSP biên dịch với 0 lỗi.
- `CatalogFilterTest`: **56 kiểm tra đạt**, chỉ dùng bảng TEMPORARY trong một
  kết nối riêng. Có tìm kiếm, bộ lọc kết hợp, phân trang, khuyến mãi theo thời
  gian, ẩn bản ghi/danh mục ngừng hoạt động, phân quyền mua OTC/Rx/hạn chế,
  và truy vấn quản trị/trang chủ.
- **463 kiểm tra dữ liệu, HTTP và tài nguyên đạt**: 20 bản ghi khớp manifest,
  20 ảnh đúng checksum ở thư mục gốc/web/WAR và trả HTTP 200, 20 chi tiết có
  nguồn, các bộ lọc và phân trang trả đúng số lượng. Trang chủ HTTP 200;
  các ID bị ẩn trước đó vẫn HTTP 404.
- Đối chiếu INSERT trong bản sao trước/sau: 16 sản phẩm cũ, các danh mục và
  toàn bộ lô tồn kho giữ nguyên. Bản sao trước khi nhập nằm tại
  `build/catalog-backup-20261028/before-dcc8678f74134cd89e16cfd45c2d131e.sql`.
- `SePayPaymentTest`: **112 kiểm tra đạt** với sự kiện ngân hàng giả lập;
  không thực hiện giao dịch chuyển tiền.
- Đã mở web kiểm tra chủ đề, lọc kết hợp và nút mua bị vô hiệu hóa trên thuốc
  kê đơn. Ảnh kiểm tra giao diện lưu trong `build/catalog-deployment-proof/`.

## Danh sách và nguồn đối chiếu

Giá dưới đây gắn với đơn vị bán trong MySQL. Nguồn và ngày đối chiếu đầy đủ
cũng được lưu trong từng thư mục thuốc.

| Sản phẩm / SKU | Giá VND / đơn vị | Loại | Chủ đề | Nguồn |
| --- | ---: | --- | --- | --- |
| Hapacol 150 / `HAPACOL150` | 38.600 / Hộp | Không kê đơn | Mẹ & Bé | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hapacol-150-3531.html) |
| Hapacol 250 / `HAPACOL250` | 47.000 / Hộp | Không kê đơn | Mẹ & Bé | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hapacol-250mg-3530.html) |
| Hapacol 150 Flu / `HAPACOL150FLU` | 1.696 / Gói | Không kê đơn | Mẹ & Bé | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hapacol-flu-150mg-3522.html) |
| Hapacol 250 Flu / `HAPACOL250FLU` | 2.146 / Gói | Không kê đơn | Mẹ & Bé | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hapacol-flu-250mg-3521.html) |
| Hapacol 325 Flu / `HAPACOL325FLU` | 52.800 / Hộp | Không kê đơn | Mẹ & Bé | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hapacol-325mg-flu-dhg-24-goi-20664.html) |
| Hapacol 650 Extra / `HAPACOL650EXTRA` | 714 / Viên | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hapacol-650-extra-dhg-10x10-28113.html) |
| Hamett 3g / `HAMETT3` | 2.300 / Gói | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/hamett-3g-3533.html) |
| Berocca 10 viên / `BEROCCA10` | 75.000 / Tuýp | Không kê đơn | Sức khỏe | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/berocca-1515.html) |
| Farzincol 10mg / `FARZINCOL10` | 65.000 / Hộp | Kê đơn, tra cứu | Sức khỏe, Mẹ & Bé | [Thông tin](https://nhathuoclongchau.com.vn/thuoc/farzincol-10mg-3786.html) · [Giá](https://www.pharmacity.vn/thuoc-bo-sung-kem-farzincol-10mg.html) |
| Efferalgan 500mg / `EFFERALGAN500` | 51.990 / Hộp | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/efferalgan-500mg-1620.html) |
| Clorpheniramin 4mg DHG / `CLORPHENIRAMIN4DHG` | 104 / Viên | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/clorpheniramin-4-200v-4228.html) |
| Smecta 3g / `SMECTA3` | 5.633 / Gói | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/smecta-2236.html) |
| Kremil-S / `KREMILS` | 1.200 / Viên | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/kremils-s-3315.html) |
| Eugica / `EUGICA` | 730 / Viên | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/eugica-vien-uong-dieu-tri-ho-cam-cum-490.html) |
| Canesten Cream 1% 20g / `CANESTEN20` | 59.000 / Tuýp | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/canesten-cream-4398.html) |
| Differin Cream 0.1% 30g / `DIFFERIN30` | 172.000 / Tuýp | Kê đơn, tra cứu | Thuốc | [Thông tin](https://nhathuoclongchau.com.vn/thuoc/differin-0130mg-17372.html) · [Giá](https://www.pharmacity.vn/differin-cream-01-30g.html) |
| Gaviscon 10ml / `GAVISCON10` | 8.000 / Gói | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/gaviscon-927-3656.html) |
| Gaviscon Dual Action 10ml / `GAVISCONDUAL10` | 10.000 / Gói | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/gaviscon-dual-action-24-goi-x-10ml-17619.html) |
| Dorithricin / `DORITHRICIN20` | 72.000 / Hộp | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/dorithricin-3952.html) |
| Rhinex 0.05% 15ml / `RHINEX005` | 6.000 / Chai | Không kê đơn | Thuốc | [Thông tin và giá](https://nhathuoclongchau.com.vn/thuoc/rhinex-005-2410.html) |
