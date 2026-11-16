# Chuyển khoản QR tự xác nhận qua SePay Webhooks

Checkout gồm “Chuyển khoản QR ngân hàng — tự xác nhận” và COD; từ 27/10/2026
đã bỏ VNPay khỏi việc tạo đơn mới. Đây là tích hợp SePay Webhooks đọc giao dịch ngân hàng; không cần
dùng Merchant VNPAY. Ngày 27/10/2026 đã đối chiếu tài khoản MB/VA, lưu hồ sơ
HMAC cục bộ và bật cấu hình trong Tomcat. SePay “Gửi thử” đã thành công HTTP
200; POST không có chữ ký bị từ chối 401. Đã đối chiếu giao dịch thật cho đơn
#5 (25.000đ, SePay `93501943`): ban đầu Form trả 401; đổi cấu hình webhook
sang JSON thì thông báo tự gửi lại và phát lại thủ công đều trả 200, payment
được lưu `THANH_CONG` với tham chiếu `SEPAY:93501943`.

## Người dùng thanh toán như thế nào

1. Chọn chuyển khoản QR ở checkout. Giá tiền và tồn kho được đọc từ database.
2. Đơn tạo một lần, giữ kho như trước; payment có provider `SEPAY`.
3. Trang đơn hiển thị QR với số tiền và nội dung riêng `PFSP<id-đơn>`.
4. Khách quét QR để chuyển tiền; ngân hàng/SePay báo tiền vào tới webhook.
5. Server xác minh chữ ký, thời gian, tài khoản nhận, ngân hàng, chiều tiền vào,
   mã đơn và số tiền. Khớp hoàn toàn thì payment chuyển `THANH_CONG`, đơn
   chuyển thanh toán `DA_THANH_TOAN` và xử lý đơn `DA_XAC_NHAN`. Trang chi tiết
   và danh sách đơn chờ QR tự cập nhật. Không có nút tự khai “đã trả tiền”.

Thanh toán không tự hoàn tất giao hàng hoặc xuất kho. Không xác định khoản đã
trả từ ảnh biên lai, ảnh QR hay thao tác của khách hàng.

## Các bước cần thực hiện trên tài khoản SePay

1. Tạo tài khoản tại [SePay](https://my.sepay.vn/) và xem gói/hạn mức phù hợp.
2. Vào Ngân hàng → Kết nối thêm → MB → loại tài khoản cá nhân/doanh nghiệp.
   Chủ tài khoản tự nhập thông tin và OTP theo hướng dẫn của SePay/MB.
3. Mã thanh toán của website dùng tiền tố **PFSP**, phần sau là số ID đơn hàng.
   Nếu bật bộ lọc mã trên SePay thì phải cấu hình tiền tố PFSP tương ứng.
   Khi chưa có tiền tố đó, để bộ lọc tiền tố trống và tắt “Chỉ gửi khi có mã
   thanh toán”; server vẫn kiểm tra mã PFSP từ nội dung gốc của ngân hàng.
4. Triển khai web có HTTPS công khai, rồi tạo webhook với các lựa chọn sau:

Nếu đang chạy trên máy cá nhân, xem [kiểm tra và mở HTTPS cho webhook](sepay-https.md).
Đường hầm cho dự án khác không dùng được cho PharmaFlow.

| Cấu hình trên SePay | Giá trị |
| --- | --- |
| URL nhận | `https://<domain>/Pharma_Flow/payment/sepay/webhook` |
| Phương thức | POST |
| Tài khoản | Đúng tài khoản MB nhận tiền đã liên kết |
| Chiều giao dịch | Tiền vào |
| Định dạng body | `application/json` (dùng cấu hình này trên SePay) |
| Chứng thực | HMAC-SHA256 |
| Secret | Khóa sinh trong SePay, ít nhất 32 ký tự; đặt giống trên máy chủ |
| Gửi lại khi lỗi | Bật |

Endpoint hỗ trợ cả JSON mặc định của SePay và form-urlencoded. HMAC được
kiểm tra trên body nguyên byte trước khi giải mã; gateway không chuyển đổi
JSON sang form hoặc serialize lại body. Cấu hình SePay thực tế phải dùng JSON:
“Gửi thử” gửi JSON ngay cả khi webhook lưu Form, nên riêng test kết nối thành
công chưa đủ xác nhận luồng giao dịch thật. Trong lần đối chiếu 27/10/2026,
Form của giao dịch thật trả 401, JSON cùng khóa/tài khoản trả 200. Không nới
kiểm tra chữ ký hoặc tái tạo body từ các trường đã parse để chấp nhận Form.
Không thêm JAR mới. JSON dùng bộ đọc giới hạn theo schema object phẳng của
SePay: tối đa 16 KiB/64 trường, từ chối khóa trùng (kể cả giá trị null), UTF-8
hoặc escape lỗi, object/mảng lồng và dữ liệu thừa. Số tiền/ID giữ nguyên chuỗi
chữ số, không qua số thực double.

5. Đặt các biến trong `config/sepay.env.example` vào môi trường tiến trình
   Tomcat, sau đó khởi động lại. File `.example` không tự nạp cấu hình.

| Biến | JVM property tương đương | Cách điền |
| --- | --- | --- |
| SEPAY_WEBHOOK_SECRET | sepay.webhookSecret | Secret HMAC của webhook đã tạo |
| SEPAY_ACCOUNT_NUMBER | sepay.accountNumber | Tài khoản nhận, phải khớp `accountNumber` trong thông báo |
| SEPAY_VA_ACCOUNT | sepay.vaAccount | Nếu dùng VA, nhập số VA; phải khớp `subAccount` trong thông báo |
| SEPAY_ACCOUNT_NAME | sepay.accountName | Tên chủ tài khoản để hiển thị, có thể để trống |
| SEPAY_BANK_CODE | sepay.bankCode | `MB` mặc định, dùng tạo QR |
| SEPAY_GATEWAY | sepay.gateway | `MBBank` mặc định, dùng đối chiếu thông báo |

Không gửi mật khẩu, OTP, secret vào chat hoặc Git. Dùng secret và endpoint
riêng cho Test mode; không gửi giao dịch mô phỏng vào hệ thống nhận tiền thật.
Nếu dùng VA, giữ `SEPAY_ACCOUNT_NUMBER` là tài khoản ngân hàng chính, điền số
VA riêng trong `SEPAY_VA_ACCOUNT`. QR và số tài khoản hiển thị cho khách sẽ
dùng VA. Webhook yêu cầu đồng thời tài khoản chính và `subAccount` khớp VA;
VA khác hoặc thiếu VA sẽ bị từ chối. Trên SePay, chọn đúng VA cho webhook.
Bỏ trống biến VA nếu muốn dùng tài khoản chính.

## Lưu khóa và chạy lại trên Windows

Không cần ghi secret vào `.env` hoặc mã nguồn. Tại thư mục gốc dự án Java:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\configure-sepay.ps1
```

Công cụ hỏi tài khoản chính, VA, tên chủ tài khoản và khóa HMAC. Nhập **cùng
một khóa** đã cấu hình trên SePay vào ô nhập ẩn. Khóa cần ít nhất 32 ký tự,
không có khoảng trắng đầu/cuối. Không gửi khóa vào chat.

Hồ sơ lưu ở `%LOCALAPPDATA%\PharmaFlow\payments\sepay.clixml`, ngoài Git.
Secret được mã hóa bằng Windows DPAPI, chỉ giải mã được với cùng người dùng
Windows trên máy đó ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-clixml?view=powershell-5.1)).
Thông tin tài khoản/VA trong hồ sơ không được mã hóa.
Đây là cấu hình cho bản chạy thử trên máy; khi chuyển hosting phải cấu hình
secret riêng trên máy chủ, không chép hồ sơ DPAPI sang máy khác.

Configure luôn lưu hồ sơ với `Enabled=false`; không tự bật nhận tiền khi
chưa có webhook. Sau khi webhook đúng URL/tài khoản/VA/HMAC đã được lưu:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\configure-sepay.ps1 -Action Enable -WebhookConfirmed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\start-local-preview.ps1 -Restart
```

Script khởi động chỉ nạp hồ sơ đang Enabled vào môi trường tiến trình Java
mới; không đưa secret vào tham số dòng lệnh hoặc log. Biến môi trường secret
được đặt tường minh từ trước có ưu tiên cao hơn hồ sơ cục bộ. `-Restart` chỉ
dừng bản Tomcat riêng của dự án sau khi kiểm tra executable, base và cổng.
Chạy trong NetBeans hoặc máy chủ khác vẫn dùng biến môi trường/JVM như bảng.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\configure-sepay.ps1 -Action Status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\configure-sepay.ps1 -Action Disable
```

Đổi hồ sơ chưa tác động tới Java đang chạy: sau Configure/Enable/Disable cần
khởi động lại bản preview để áp dụng. Sau khi nạp đúng cấu hình, POST thiếu
chữ ký phải trả 401 thay vì 503. Tiếp tục kiểm tra gửi thử từ SePay và đối
chiếu tiền thật trước khi nhận đơn thanh toán thực tế.

## Kiểm tra tiền vào và xử lý lặp

- HMAC-SHA256 tính trên `timestamp.raw_body`; timestamp lệch quá 5 phút bị từ chối.
- Thông báo đã xác thực nhưng không có mã PFSP được xác nhận đã nhận rồi bỏ
  qua, không gọi DAO. Đây cũng là cách xử lý thông báo “Gửi thử” không gắn đơn.
  Có mã PFSP thì tài khoản/ngân hàng/VA vẫn bắt buộc khớp trước khi xử lý tiền.
- Nội dung phải có đúng một mã `PFSP<id>`. Nếu có trường `code` thì mã đó cũng
  phải khớp. Số tiền phải đúng toàn bộ giá trị đơn, không tự cộng tiền thiếu.
- Sự kiện SePay được lưu ở `online_payments.transaction_reference` dạng
  `SEPAY:<event-id>`. Khóa MySQL theo sự kiện và khóa dòng đơn/payment bảo vệ
  cập nhật đồng thời: một sự kiện không trả tiền cho hai đơn, không ghi hai lần.
- Thông báo hợp lệ đồng thời xác nhận đơn `CHO_XU_LY` → `DA_XAC_NHAN`. Khi
  phát lại đúng receipt đã thành công, đơn cũ đã trả tiền nhưng còn chờ xử lý
  được đối soát sang đã xác nhận; không lùi trạng thái đang chuẩn bị/giao hàng
  và không mở lại đơn đã hủy. Mọi bước chuẩn bị, xuất kho, giao hàng vẫn do
  luồng fulfillment xử lý.
- Thành công cập nhật payment và order trong cùng transaction; không đổi tồn,
  không nhả giữ hàng, không hoàn tất giao hàng.
- Sai số tiền, mã không khớp hoặc khoản đến muộn cho đơn đã hủy không đánh dấu
  thanh toán. Cần đối soát trên lịch sử SePay; server ghi log kết quả không khớp.
- JSON `success:true` là xác nhận đã nhận webhook, không đồng nghĩa mọi khoản
  chuyển đều khớp đơn. Lỗi database trả 503 để SePay gửi lại.
- Thiếu cấu hình thì lựa chọn QR bị khóa và webhook trả 503. Không có cấu hình
  ngân hàng cá nhân nào được tự lấy từ ảnh QR người dùng gửi trước đó.
- Không đổi schema, không thêm JAR. Dùng provider VARCHAR hiện có; thông tin
  phương thức trong đơn là `THANH_TOAN_TRUC_TUYEN`, provider phân biệt SEPAY/VNPAY.
- Chưa có job đối soát chủ động, tự hủy đơn chờ chuyển khoản hoặc tự hoàn tiền.

QR được tạo qua `vietqr.app`, endpoint do tài liệu SePay hướng dẫn. Khi khách
mở QR, dịch vụ ảnh nhận số tài khoản nhận tiền, số tiền và mã đơn; không nhận
secret, mật khẩu hay OTP. Người vận hành cần đồng ý cách tích hợp này khi cấu hình.

## Kiểm thử và nguồn đối chiếu

Test `test/payment/SePayPaymentTest.java` dùng HMAC và các bảng TEMPORARY trong
MySQL, không chuyển tiền thật. Chạy cùng classpath của test VNPAY, bằng main
`payment.SePayPaymentTest`. Có cả luồng checkout → tạo payment SEPAY → webhook
→ trạng thái đã thanh toán; kiểm tra phân quyền đọc đơn và bảo toàn tồn kho.

Lần sửa 27/10 đã thực thi **112 kiểm tra SePay**, **63 kiểm tra VNPAY**,
**14 kịch bản JavaScript**, Ant build và biên dịch toàn bộ JSP trên Tomcat
10.1 (0 lỗi). Có kiểm tra tự xác nhận, đối soát đơn cũ bằng receipt đã xác
thực, không lùi trạng thái fulfillment, không hồi sinh đơn hủy và danh sách
theo dõi nhiều đơn chờ thanh toán. Có kiểm tra controller chặn phương thức
VNPay từ form cũ, DAO từ chối tạo payment VNPay mới và giữ nguyên giỏ/tồn kho
khi từ chối. Checkout QR mặc định dùng SePay. Các test ngân hàng dùng dữ liệu tổng hợp
và bảng TEMPORARY, không thực hiện chuyển khoản hoặc sửa đơn thật.

Ở lần triển khai trước đã chạy 13 kết quả kiểm thử gateway và 12 kiểm tra hồ
sơ Windows (DPAPI, không tự bật cấu hình, Enable/Disable, từ chối dữ liệu sai).
Trong lần sửa này không thay đổi gateway hoặc cơ chế lưu khóa.

Người dùng đã chuyển khoản thật cho đơn #5. Đã đọc thông báo giao dịch trong
SePay, đối chiếu VA/nội dung PFSP5/số tiền 25.000đ, đổi webhook hiện có sang
JSON và phát lại qua SePay. Server xác thực HMAC rồi lưu `SEPAY:93501943`;
đơn đã thanh toán/đã xác nhận, chỉ có một payment, thời điểm ghi nhận tiền
không bị ghi đè khi phát lại. Không dùng nội dung UI hoặc ảnh biên lai để
ghi trạng thái thanh toán trực tiếp vào database.

Phần VA đã kiểm tra riêng: QR trỏ đến VA, vẫn giữ cấu hình tài khoản chính,
từ chối sai/thiếu VA và sai tài khoản chính, chấp nhận chuyển khoản khớp cả
hai, cập nhật đã thanh toán và vẫn hỗ trợ chế độ không dùng VA.

- [Liên kết MB cá nhân/doanh nghiệp](https://docs.sepay.vn/ket-noi-mb-api.html)
- [Xác thực HMAC](https://developer.sepay.vn/en/sepay-webhooks/xac-thuc)
- [Nhận webhook](https://docs.sepay.vn/tich-hop-webhooks.html)
- [Tạo QR động](https://docs.sepay.vn/tao-qr-code-vietqr-dong.html)
- [Test mode](https://developer.sepay.vn/vi/sepay-webhooks/test-mode/bat-dau-nhanh)

Các file chính: `SePayConfig`, `SePayUtil`, `SePayPaymentDAO`,
`SePayWebhookServlet`; tích hợp checkout/model/DAO đơn hàng và trang chi tiết.
