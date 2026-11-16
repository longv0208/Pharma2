# Ảnh sản phẩm

Trạng thái hiện tại: đã bổ sung 13 ảnh sản phẩm. Sau khi người dùng cho phép
thay ba bản ghi mẫu, cửa hàng hiển thị 10 sản phẩm trực tuyến và cả 10 đều
có ảnh. Ba bản ghi mẫu được giữ lại ở trạng thái ngừng hoạt động để bảo toàn
lịch sử. Chi tiết thay thế và nguồn xác minh ở phần cuối tài liệu.

Đã đọc trực tiếp bảng `products` của database đang cấu hình (`pharmaflow2`)
và đối chiếu với thư mục `C:\Users\PC-DELL\Downloads\thuoc` ngày 26/10/2026.
Ảnh được lưu nguyên bản vào `web/images/products/{SKU}.webp` hoặc `.jpg`.
Web dùng `Product.getImagePath()` để ghép theo SKU, không phụ thuộc ID hay tên
hiển thị và không cần thêm cột vào database. Ảnh được đóng gói trong WAR.

## Đối chiếu ảnh

| SKU | Sản phẩm trong database / thư mục nguồn | File nguồn được chọn |
| --- | --- | --- |
| PARA500 | Paracetamol 500mg | `00032865_paracetamol_stada_500mg_10x10_4111_61af_large_6bbfac12ff.webp` |
| IBU200 | Ibuprofen 200mg | `ibuprofen_bb3bc9e48c.webp` |
| OME20 | Omeprazole 20mg | `IMG_1874_d7a893c364.webp` |
| VITC500 | Vitamin C 500mg | `00014912_vitamin_c_500mg_vidipha_10x10_bao_phim_5185_5bbc_large_1456953bfa.webp` |
| CALD3 | Calcium D3 | `00001523_calcium_sandoz_600_vitamin_d3_8048_6094_large_eb606dfbd9.webp` |
| AMOX500 | Amoxicillin 500mg | `00000739_amoxicillin_500mg_mekophar_2051_5b71_large_73d974cae1.webp` |
| CEFU500 | Cefuroxime 500mg | `cefuroxim_500mg_10x10_vidipha_00022349_707e241905.webp` |
| CET10 | Cetirizine 10mg | `cetirizin_10mg_10x10_vidipha_00016170_eaffe341aa.webp` |
| HYDRO1 | Hydrocortisone Cream 1% | `00502859_0396d52731.webp` |
| REST001 | Thuốc giảm đau hạn chế | `00028583_di_ansel_8_roussel_2x10_1796_608a_large_d447d566c4.webp` |

Ảnh xuất hiện trên trang chủ, danh mục, chi tiết và quản trị sản phẩm.
Sản phẩm không được ánh xạ hoặc ảnh tải lỗi sẽ hiển thị biểu tượng dự phòng.
Trong lần bổ sung 10 ảnh ban đầu, dữ liệu bán hàng được giữ nguyên.
Việc thay ba mục mẫu theo chấp thuận sau đó được ghi riêng ở cuối tài liệu.

## Các trường hợp thiếu ảnh ở lần kiểm tra ban đầu

- `COLD001` (Thuốc cảm cúm tổng hợp), `DISC001` (Thuốc cảm đã ngừng kinh doanh)
  và `TEST01` (kiểm thử) không có thư mục ảnh cùng tên.
- Thư mục `Cozz DHG` có ảnh thuốc chứa eucalyptol, menthol, tinh dầu tần và
  tinh dầu gừng. Database chưa có sản phẩm Cozz tương ứng. Không ghép ảnh này
  cho `COLD001` vì bản ghi đó chứa paracetamol + chlorpheniramine.

## Khác biệt giữa ảnh người dùng cung cấp và dữ liệu minh họa

- `CALD3`: hộp Calcium-Sandoz ghi calcium 600mg + vitamin D3 400IU, dạng viên
  sủi; database ghi 500mg + 400IU, viên nén.
- `REST001`: hộp DI-ANSEL 8 ghi paracetamol 500mg + codein phosphate 8mg;
  database là bản ghi minh họa `Test Restricted Ingredient`, 10mg.
- Nhãn hiệu/nhà sản xuất trên ảnh có thể khác tên nhà sản xuất minh họa trong
  database. Chỉ bổ sung ảnh theo các thư mục được cung cấp, không sửa thông tin thuốc.

## Bổ sung hoặc thay ảnh sau này

Thay file `web/images/products/{SKU}.webp` hoặc `.jpg` đúng phần mở rộng đã
được ánh xạ để đổi ảnh cho một SKU.
Với sản phẩm mới, thêm SKU và đường dẫn tương ứng trong `Product.getImagePath()`.
Build và triển khai lại ứng dụng bằng quy trình NetBeans/Ant hiện có.

## File thay đổi và kiểm tra ở lần bổ sung 10 ảnh ban đầu

- `src/java/model/Product.java`: thêm getter đường dẫn ảnh theo SKU.
- `web/WEB-INF/jspf/product-card.jsp`: ảnh cho trang chủ và danh mục.
- `web/WEB-INF/views/product-detail.jsp`: ảnh lớn trên trang chi tiết.
- `web/WEB-INF/views/admin/product-list.jsp` và `product-form.jsp`: ảnh thu nhỏ
  và xem trước trong quản trị, bao gồm các sản phẩm không bán trực tuyến.
- `web/css/main.css`: giữ nguyên tỉ lệ ảnh, bố cục chi tiết thích ứng màn hình.
- `web/WEB-INF/web.xml`: khai báo MIME `image/webp`.
- `web/images/products/`: 10 ảnh WebP, tổng 341.774 byte; checksum khớp nguồn.

Kết quả xác minh ngày 26/10/2026:

- Build Ant `dist` thành công, WAR chứa đủ 10 ảnh.
- Biên dịch toàn bộ 77 file Java bằng JDK 17 thành công.
- Biên dịch toàn bộ JSP bằng Jasper của Tomcat 10.1: 0 lỗi.
  Tùy chọn `compile.jsps=true` của công cụ NetBeans cũ không hỗ trợ source 17;
  đã dùng Jasper của Tomcat để xác minh thay thế, không sửa cấu hình build.
- Web chạy thử trên Tomcat riêng tại `http://127.0.0.1:18080/Pharma_Flow/`:
  trang chủ, danh mục và chi tiết các sản phẩm có/không có ảnh trả HTTP 200.
  Cả 10 ảnh trả HTTP 200 và `image/webp`.
- Kiểm tra trực quan danh mục và chi tiết Paracetamol trên trình duyệt:
  ảnh hiển thị, không bị cắt; các sản phẩm chưa có ảnh giữ biểu tượng dự phòng.
- Điều kiện truy cập thuốc kê đơn được giữ nguyên: `/products/7` vẫn HTTP 404.
- JSP quản trị đã được biên dịch; chưa kiểm thử giao diện bằng phiên đăng nhập
  quản trị. Không thực hiện ghi dữ liệu hay thay đổi cấu trúc database.

## Rà soát 3 bản ghi mẫu trước khi được phép thay thế

Đã đọc lại toàn bộ thông tin của ba bản ghi trực tiếp từ `pharmaflow2` và
tra cứu nguồn công khai theo yêu cầu xác minh đúng sản phẩm trước khi gắn ảnh.

| SKU | Dữ liệu xác minh trực tiếp | Kết luận về ảnh thật |
| --- | --- | --- |
| COLD001 | Tên chung “Thuốc cảm cúm tổng hợp”; paracetamol + chlorpheniramine 500mg + 2mg; viên nén; nhà sản xuất `MediCare`; số đăng ký `REG-COLD-003` | Chưa đủ thông tin để xác định một nhãn thuốc cụ thể. Không gán ảnh của nhãn khác chỉ vì cùng thành phần. |
| DISC001 | Tên “Thuốc cảm đã ngừng kinh doanh”; `Test Ingredient` 100mg; `Old Pharma`; mô tả ghi rõ thuốc minh họa dùng kiểm thử | Là bản ghi kiểm thử, chưa có danh tính thuốc thật để tìm ảnh chính xác. |
| TEST01 | Tên “kiểm thử”; `Test Ingredient` 100mg; `Old Pharma`; mô tả “Chỉ là dữ liệu kiểm thử phát triển” | Là bản ghi kiểm thử, chưa có danh tính thuốc thật để tìm ảnh chính xác. |

Ứng viên đã đối chiếu cho thành phần của `COLD001`:

- [Bepamin trên website chính thức Bepharco](https://bepharco.com/en-US/products/medicine-1/bepamin-1)
  ghi paracetamol 500mg + clorpheniramin 2mg, dạng viên nén, nhà sản xuất
  Meyer-BPC. Thành phần và dạng bào chế phù hợp nhưng nhà sản xuất khác
  bản ghi `MediCare`; chưa thể coi là cùng sản phẩm.
- Đã xem trực quan [ảnh mặt hộp chính thức](https://bepharco.com/Data/Sites/1/Product/8767/be-1.jpg):
  nhãn Bepamin ghi 500mg + 2mg và số đăng ký `VD-34412-20`, khác
  `REG-COLD-003` trong database.
- [Catalogue chính thức của Bepharco](https://bepharco.com/Data/Sites/1/media/catalogue/20240224---catalogue-bpc.pdf)
  cũng xác nhận thành phần Bepamin nêu trên.

Ở thời điểm kiểm tra ban đầu, chưa thêm ảnh cho ba SKU mẫu vì chưa xác minh
được đúng danh tính sản phẩm. Sau đó người dùng đã cho phép thay ba bản ghi
mẫu bằng các sản phẩm thật có ảnh đã xác minh, như phần dưới.

Đã kiểm tra các khóa ngoại bằng truy vấn chỉ đọc: `COLD001` đang có một lô
tồn kho, một liên kết nhà cung cấp và hai dòng lịch sử kiểm kê. Không đổi
danh tính thuốc của bản ghi này chỉ để khớp ảnh. `DISC001` và `TEST01` không
có tham chiếu trong các khóa ngoại đã kiểm tra. Nếu cần chuyển sang danh mục
thuốc thật, cần quyết định riêng về bản ghi sản phẩm và lịch sử hiện có.

## Ba sản phẩm thật đã bổ sung theo chấp thuận của người dùng

Đã tải ảnh từ website của hãng, xem trực quan nhãn hộp và đối chiếu tên,
hoạt chất, hàm lượng, dạng bào chế, quy cách và nhà sản xuất trước khi nhập.

| Mục mẫu được thay trên cửa hàng | Sản phẩm mới / SKU / ID thực tế | Thông tin khớp nguồn hãng | Ảnh trong dự án |
| --- | --- | --- | --- |
| COLD001 | Bepamin 500mg/2mg / BEPAMIN500 / 14 | Meyer-BPC; paracetamol 500mg + clorpheniramin maleat 2mg; viên nén; hộp 25 vỉ x 20 viên | `BEPAMIN500.jpg` |
| DISC001 | Cozz DHG / COZZDHG / 15 | DHG Pharma; eucalyptol 100mg + menthol 0,5mg + tinh dầu tần 0,18mg + tinh dầu gừng 0,5mg; viên nang mềm; hộp 10 vỉ x 10 viên | `COZZDHG.webp` |
| TEST01 | Corityne 10mg / CORITYNE10 / 16 | Meyer-BPC; loratadin 10mg; viên nén; hộp 3 vỉ x 10 viên | `CORITYNE10.jpg` |

Nguồn đối chiếu và ảnh nguyên bản:

- Bepamin: [trang hãng](https://bepharco.com/en-US/products/medicine-1/bepamin-1),
  [ảnh mặt hộp](https://bepharco.com/Data/Sites/1/Product/8767/be-1.jpg).
  Số đăng ký đọc từ nhãn ảnh: `VD-34412-20`.
- Cozz: [trang DHG Pharma](https://dhgpharma.com.vn/vi/san-pham/ho-hap/cozz),
  [ảnh hộp của hãng](https://dhgpharma.com.vn/sites/default/files/styles/458x458/public/2026-03/Cozz%20Xanh%20H_0.jpg.webp?itok=_YU6EnTh).
  Không suy đoán số đăng ký; trường này được để NULL.
- Corityne: [trang hãng](https://bepharco.com/corityne-2),
  [ảnh mặt hộp](https://bepharco.com/Data/Sites/1/Product/8805/corac-1.jpg).
  File hãng có tên `corac-1.jpg` nhưng đã mở ảnh và xác nhận nhãn ghi
  **Corityne, Loratadin 10mg, Meyer-BPC**, số đăng ký `VD-29428-18`.
- [Catalogue chính thức Bepharco](https://bepharco.com/Data/Sites/1/media/catalogue/catalogue-bpc-version-english-minisize.pdf)
  đối chiếu chéo thành phần Bepamin và Corityne.

Các số đăng ký nêu trên được chép từ nhãn ảnh, không phải kết luận về tình
trạng hiệu lực pháp lý hiện tại. Không sao chép phần liều dùng Corityne trên
trang web vì chưa có tờ hướng dẫn đã đối chiếu; web dự án dẫn người dùng
đọc tờ hướng dẫn của nhà sản xuất.

### Cập nhật database và bảo toàn dữ liệu

- Migration: `sql/20261026_verified_product_images.sql`, áp dụng sau seed SQL.
  Không thay cấu trúc bảng, không xóa bản ghi.
- Đã thực thi trên `pharmaflow2` trong một transaction: tạo 3 sản phẩm mới,
  chuyển `COLD001`, `DISC001`, `TEST01` sang `NGUNG_HOAT_DONG` và tắt bán online.
- Không đổi danh tính, ID, hoạt chất hay hàm lượng của ba bản ghi cũ. Toàn bộ
  lô tồn, liên kết nhà cung cấp, lịch sử kiểm kê và các sản phẩm khác được
  đối chiếu trước/sau và giữ nguyên.
- Ba sản phẩm mới không có lô tồn: hiển thị ảnh và thông tin nhưng báo hết
  hàng, chưa thể thêm vào giỏ. Không chuyển tồn kho mẫu sang thuốc thật.
- Giá bán kế thừa ba mục mẫu (45.000đ, 30.000đ, 120.000đ) phục vụ dự án demo,
  chưa phải giá thương mại được xác minh. Barcode để NULL, không dùng mã giả.
- Bản sao trước/sau nằm tại
  `E:\Android\temp\codex-pharma-images-c63926ebdb674d25b7485cd51262828d\verified-products-backup-083a8bdfa8d94a75ba74ea4754c3799d`.

### Kiểm tra sau khi thay thế

- Ant `dist` thành công; WAR chứa đủ 13 ảnh sản phẩm.
- Chạy lại migration không tạo trùng: 0 bản ghi thêm, 0 bản ghi thay đổi.
- `/products`: HTTP 200, 10 thẻ sản phẩm và 10 ảnh; không còn tên ba mục mẫu.
- `/products/14`, `/products/15`, `/products/16`: HTTP 200, đúng tên, đúng URL
  ảnh và trạng thái hết hàng. Cả ba ảnh trả HTTP 200, MIME JPEG/WebP phù hợp.
- `/products/3`, `/products/12`, `/products/13`: HTTP 404 trên cửa hàng.
- `/home`: HTTP 200. Không thay đổi các điều kiện bán hàng hiện có.
- Đã mở danh mục và chi tiết Cozz trên trình duyệt: ảnh hiển thị đúng,
  tên/hoạt chất/nhà sản xuất khớp bản ghi mới; đã lưu ảnh kiểm tra giao diện.

## Đợt bổ sung 20 sản phẩm ngày 28/10/2026

Đã thêm 20 thư mục tên thuốc tại `sql/IMG Product`, mỗi thư mục chứa ảnh gốc
và `source.md`; ảnh dùng trên web nằm ở `web/images/products`. 20 đường dẫn
ảnh và nguồn được lưu trong bảng MySQL `product_catalog_details` đã được
người dùng phê duyệt. Các ảnh cũ tiếp tục dùng đường dẫn đã có.

[Ghi chú đợt nhập mới](catalog-products-20261028.md) có danh sách 20 sản phẩm,
giá công khai theo đơn vị và nguồn kiểm tra, cách chạy migration và kết quả
kiểm thử. Các sản phẩm mới chưa có lô tồn thực tế, nên chưa thể thêm vào giỏ.
Hai thuốc kê đơn chỉ dùng để tra cứu. Không nhập ưu đãi của nhà thuốc nguồn
thành ưu đãi PharmaFlow. Thông tin giá demo của đợt trước ở trên được giữ
để ghi nhận lịch sử, không áp dụng cho 20 sản phẩm mới.
