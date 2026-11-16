# VNPAY Merchant và xác nhận thanh toán tự động

Từ 27/10/2026, VNPay đã được bỏ khỏi checkout theo yêu cầu người dùng.
Controller và DAO không tạo đơn VNPay mới. Phần dưới ghi lại tích hợp cũ;
lịch sử và callback có chữ ký được giữ để đối chiếu các đơn đã tồn tại.

Người dùng chọn cổng VNPAY Merchant và xác nhận chưa có kết nối VNPAY/ngân
hàng. Mã nguồn đã được bổ sung IPN; chưa kích hoạt nhận tiền thật.

## Cách hoạt động

1. Checkout đọc tổng tiền từ database, ký yêu cầu và chuyển sang cổng VNPAY.
2. VNPAY cung cấp QR hoặc thẻ theo dịch vụ Merchant được cấp.
3. `/payment/vnpay/ipn` nhận GET từ VNPAY, xác minh HMAC-SHA512, Merchant,
   mã đơn, số tiền và trạng thái trước khi ghi nhận trong một transaction.
4. Thành công: `online_payments.THANH_CONG` và
   `online_orders.payment_status=DA_THANH_TOAN`. Đơn vẫn chờ xử lý/giao hàng;
   không tự đánh dấu đã giao, không xuất kho.
5. Khách quay lại web: Return URL chỉ đọc kết quả đã lưu. Trang chi tiết tự
   kiểm tra trạng thái mỗi 3 giây và chuyển sang kết quả khi IPN cập nhật.

Ảnh QR nhận chuyển khoản MB không phải mã Merchant VNPAY. Tài khoản nhận tiền
phải được đăng ký/xác nhận với VNPAY khi mở dịch vụ. Không chèn ảnh VietQR
nhận chuyển khoản vào luồng VNPAY rồi coi đó là bằng chứng đã thanh toán.

## Cấu hình còn cần để kết nối thật

- Đăng ký Merchant với VNPAY và tài khoản ngân hàng muốn nhận tiền.
- Nhận `TmnCode`, `HashSecret` và xác nhận dịch vụ QR được bật nếu cần QR.
- Triển khai website có HTTPS công khai; đăng ký IPN URL với VNPAY:
  `https://<domain>/<context>/payment/vnpay/ipn`.
- Cấu hình Return URL:
  `https://<domain>/<context>/payment/vnpay/return`.
- Đặt biến môi trường từ `config/vnpay.env.example` cho tiến trình Tomcat và
  khởi động lại. File ví dụ không được Java tự đọc. Không gửi HashSecret vào
  chat, đưa vào Git, JSP hoặc log.

| Biến môi trường | JVM property tương đương | Ý nghĩa |
| --- | --- | --- |
| VNPAY_TMN_CODE | vnpay.tmnCode | Mã Merchant do VNPAY cấp |
| VNPAY_HASH_SECRET | vnpay.hashSecret | Khóa ký bí mật do VNPAY cấp |
| VNPAY_ENVIRONMENT | vnpay.environment | `sandbox` mặc định; `production` khi được cấp kết nối thật |
| VNPAY_RETURN_URL | vnpay.returnUrl | URL công khai cố định; bắt buộc HTTPS trong production |
| VNPAY_BANK_CODE | vnpay.bankCode | `VNPAYQR` để chọn QR; bỏ trống để chọn ở VNPAY |

Ứng dụng ưu tiên biến môi trường, sau đó JVM property. Đã bỏ thông tin Sandbox
nhúng trong mã nguồn. Thiếu cấu hình sẽ vô hiệu hóa lựa chọn VNPAY trên
checkout và từ chối tạo đơn VNPAY; COD giữ nguyên. Sandbox không nhận tiền thật.
Localhost HTTP không thể nhận IPN từ máy chủ VNPAY trên Internet.

## Bảo vệ và giới hạn

- IPN độc lập với phiên đăng nhập. Endpoint xem trạng thái đơn yêu cầu khách
  hàng đăng nhập và chỉ đọc đơn thuộc khách hàng đó.
- Thông báo trùng được phản hồi mà không cập nhật/nhả kho thêm lần nữa.
  Thông báo có mã giao dịch khác không được ghi đè một khoản đã thành công.
- Sai chữ ký, Merchant, tham số lặp hoặc thiếu trường bắt buộc không ghi dữ liệu.
- Thanh toán thất bại rõ ràng nhả giữ kho một lần, ghi audit và hủy đơn.
  Các trạng thái chưa hoàn tất, nghi ngờ, đảo hoặc hoàn tiền được giữ chờ đối
  soát; không tự coi là đã trả tiền hay tự nhả kho.
- Chưa có dịch vụ QueryDR/đối soát chủ động, hoàn tiền hoặc job xử lý đơn quá
  hạn. Những khoản không có IPN hoặc cần đối soát phải được kiểm tra qua VNPAY;
  không suy luận đã trả tiền từ việc khách đóng trang hoặc bấm xác nhận.
- Trình duyệt kiểm tra tối đa 20 phút và tạm dừng khi tab bị ẩn. IPN vẫn cập
  nhật database ngay cả khi trình duyệt đã đóng.

## Kiểm thử

`test/payment/VnpayPaymentTest.java` chạy độc lập bằng JDK 17, không cần thêm
JUnit/JAR. Biên dịch test với classpath `build/web/WEB-INF/classes`,
`lib/jakarta.servlet-api.jar` và `web/WEB-INF/lib/*`. Chạy
`payment.VnpayPaymentTest --database` để kiểm tra đầy đủ. Các bảng ghi thử là
MySQL TEMPORARY theo từng connection; tự biến mất khi đóng kết nối, không ghi
đơn hàng hoặc tồn kho thật. Không dùng thông tin Merchant thật khi chạy test.

Chạy `node test/payment/payment-status.test.js` để kiểm tra cập nhật giao diện.

Đã thực thi: 63 kiểm tra Java/IPN/database và 8 kịch bản cập nhật trình duyệt.
Bao gồm: chỉ có Return chưa đánh dấu thanh toán; IPN thành công; thông báo
lặp; sai chữ ký, số tiền, Merchant; tham số lặp; trạng thái chưa rõ; bảo toàn
tồn kho khi thành công; nhả kho/audit một lần khi thất bại; rollback khi dữ
liệu giữ kho không khớp. Đây là kiểm thử mô phỏng, chưa phải chuyển tiền thật.
Build Ant thành công và toàn bộ JSP biên dịch bằng Tomcat 10.1 với 0 lỗi.
Trên bản chạy thử: IPN khi chưa cấu hình trả JSON `RspCode=99`, callback không
hợp lệ bị từ chối, API trạng thái chặn khách chưa đăng nhập, các tài nguyên
giao diện và danh mục vẫn trả HTTP 200.

## Tài liệu VNPAY được đối chiếu

- [Đặc tả thanh toán và IPN](https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html)
- [Return URL và IPN khác nhau thế nào](https://sandbox.vnpayment.vn/apis/docs/faqs/)
- [Mã trạng thái VNPAY](https://sandbox.vnpayment.vn/apis/docs/bang-ma-loi/)
