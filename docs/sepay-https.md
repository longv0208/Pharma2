# HTTPS cho webhook SePay khi chạy PharmaFlow ở máy cá nhân

## Kết quả kiểm tra ngày 27/10/2026

**Trạng thái sau kết nối:** PharmaFlow đã chạy và trả HTTP 200 trên
`127.0.0.1:18080/Pharma_Flow`, dùng Tomcat base trong `build/tomcat-preview`.
Không còn phụ thuộc thư mục preview cũ trong `E:\Android\temp`.

- HTTPS hiện truy cập được; webhook SePay đã lưu, hồ sơ HMAC đã bật và nạp
  vào Tomcat. SePay “Gửi thử” thành công HTTP 200; POST không có chữ ký trả
  401. Đã nhận và đối soát thông báo giao dịch thật cho đơn #5 qua JSON;
  đơn đã thanh toán/đã xác nhận. Mạng ở các lần trước từng rớt kết
  nối và trả `530/1033`; luôn dùng Status để kiểm tra trạng thái hiện tại.
- URL Quick Tunnel thay đổi theo lần chạy. Không lấy URL lịch sử trong chat
  hoặc log cũ; chạy Status để biết endpoint hiện còn truy cập được hay không.
- Đường hầm ngrok có sẵn trên máy chuyển tới cổng `8080` của dự án khác;
  không dùng địa chỉ đó cho PharmaFlow, không đổi hoặc dừng dịch vụ đó.
- Các lần thử ở mạng cũ không kết nối được TCP/UDP 7844 và trả `530/1033`.
  Hostname trong các log thử cũ không sử dụng được; các tiến trình cũ đã dừng.
  Đã xử lý trường hợp truy vấn DNS quá sớm bị cache NXDOMAIN: chờ edge đăng ký
  và kiểm tra bản ghi DNS công khai trước khi gọi health qua bộ phân giải hệ
  thống. Không đổi DNS máy, không bỏ qua kiểm tra chứng chỉ TLS.
- `SEPAY_ACCOUNT_NUMBER`, `SEPAY_VA_ACCOUNT`, `SEPAY_WEBHOOK_SECRET` chưa có
  trong môi trường process/user/machine đã kiểm tra. Servlet đang trả 503 khi
  thiếu cấu hình. Bản đang chạy hiện nạp khóa/tài khoản từ hồ sơ cục bộ mã hóa
  đã bật, không ghi khóa vào biến môi trường user/machine hoặc vào Git.

## Chạy lại sau khi mạng cho phép kết nối Cloudflare

Máy đã có Node.js và cloudflared, không cần cài thêm package/JAR.
Mở PowerShell tại thư mục gốc dự án Java rồi chạy:

Nếu bản chạy thử trên cổng 18080 đã dừng, khởi động lại bằng script sau.
Lần đầu script tự tạo base riêng trong thư mục build của dự án, không cài
thêm Tomcat và không đổi server NetBeans hoặc dịch vụ của dự án khác:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\start-local-preview.ps1
```

Script yêu cầu cấu hình loopback `127.0.0.1:18080`, context đúng dự án hiện
tại, không đổi cấu hình hoặc dừng ứng dụng khác. Khi website trả HTTP 200,
mới mở lại HTTPS:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\sepay-https.ps1 -Action Start
```

Tham số mặc định: Tomcat `18080`, gateway `18181`. Nếu chạy Tomcat khác cổng,
thêm `-TomcatPort <cổng>`. Nếu cổng gateway bận, thêm `-GatewayPort <cổng>`.
Node/cloudflared cài ở đường dẫn khác thì truyền `-NodePath` và
`-CloudflaredPath` tương ứng. Cần Node.js 18 trở lên; bản kiểm thử là 24.
Thời gian chờ HTTPS mặc định 60 giây; có thể truyền
`-ConnectTimeoutSeconds <15..180>` khi DNS/đường hầm khởi tạo chậm.
Giao thức mặc định `auto` để cloudflared chọn QUIC/HTTP2; có thể truyền
`-TunnelProtocol http2` hoặc `-TunnelProtocol quic` khi cần kiểm tra mạng.

Công cụ chỉ trả URL sử dụng được khi `/healthz` qua HTTPS phản hồi đúng dịch
vụ PharmaFlow. Nếu chỉ được cấp hostname nhưng không kết nối được Internet,
Start báo lỗi và dừng các tiến trình vừa tạo. Không lấy URL trong log lỗi để
đăng ký webhook.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\sepay-https.ps1 -Action Status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\sepay-https.ps1 -Action Stop
```

Khi chỉ cập nhật mã gateway, dùng lệnh sau để giữ nguyên URL đã đăng ký trên
SePay. Công cụ xác minh tiến trình Node thuộc dự án trước khi khởi động lại;
không dừng cloudflared và không đụng agent của dự án khác:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\sepay-https.ps1 -Action RestartGateway
```

Nếu đổi mã Java thì build lại và chạy `start-local-preview.ps1 -Restart`.

Status phân biệt tiến trình đang chạy với `PublicHttpsReachable`. Chỉ dùng
`WebhookUrl` khi trạng thái sau là `True`. State/log ở
`%LOCALAPPDATA%\PharmaFlow\sepay-webhook`, không chứa khóa ngân hàng hoặc
secret webhook. Stop kiểm tra PID, executable và dấu nhận diện trước khi
dừng, không dừng agent của dự án khác.

Cloudflare Quick Tunnel dùng cho phát triển, cần giữ máy/Tomcat/gateway/tunnel
hoạt động; URL thay đổi khi tạo tunnel mới. Khi đổi URL phải cập nhật trên
SePay. Để dùng lâu dài, triển khai ứng dụng lên hosting/VPS có HTTPS cố định
hoặc dùng Cloudflare Tunnel với hostname cố định.

## Phạm vi mở ra Internet

Gateway chỉ lắng nghe trên loopback. Tunnel chuyển tiếp đến gateway này,
không chuyển trực tiếp đến toàn bộ Tomcat:

| Đường dẫn công khai | Hành vi |
| --- | --- |
| GET `/healthz` | Nhận diện dịch vụ, không chứa cấu hình/tài khoản |
| POST `/Pharma_Flow/payment/sepay/webhook` | Chuyển body nguyên byte và header chữ ký tới Servlet |
| Đường dẫn khác, kể cả trang quản trị, sản phẩm, đơn hàng | 404 |
| GET webhook | 405 |

Nhận JSON và form-urlencoded, tối đa 16 KiB. Chữ ký HMAC và timestamp được Servlet
xác minh như trước. Gateway không có secret, không xử lý thanh toán, không
ghi request body/header vào log. Giới hạn deadline upstream 10 giây, chỉ trả
JSON kết quả; cookie, redirect và trang lỗi HTML của Tomcat không đi ra ngoài.

## Sau khi HTTPS đã truy cập được

1. Trên SePay, tạo webhook tiền vào cho đúng tài khoản MB/VA với `WebhookUrl`.
   Chọn POST, **JSON**, HMAC-SHA256 và bật gửi lại. Dùng JSON cho webhook
   Live: “Gửi thử” không phản ánh định dạng Form của giao dịch thật.
2. Chủ tài khoản tự nhập secret và tài khoản chính/VA vào hồ sơ cục bộ hoặc
   môi trường Tomcat theo [hướng dẫn SePay](sepay-payments.md), rồi khởi động
   lại Tomcat với `start-local-preview.ps1 -Restart`. Không
   gửi secret/OTP vào chat; không dùng VA thay cho số tài khoản chính.
3. Kiểm tra unsigned POST không được chấp nhận. Kiểm thử SePay Test mode bằng
   endpoint/secret và dữ liệu thử riêng trước khi cấu hình Live. Sau đó đối
   chiếu khoản chuyển thật với đơn hàng chờ thanh toán. Không dùng giao dịch
   mô phỏng để đánh dấu đơn thật đã trả tiền.

## Kiểm thử

```powershell
node --test test/payment/webhook-gateway.test.cjs
```

Đã chạy thành công 13 kết quả kiểm thử (12 trường hợp con và test tổng), gồm
giữ nguyên raw body/chữ ký cho cả JSON/form, chặn route khác, payload quá lớn,
định dạng không hỗ trợ/nén, phản
hồi xác thực thất bại, lỗi HTML/redirect, timeout và Tomcat dừng. Không ghi
database hoặc chuyển tiền trong các kiểm thử gateway.

Nguồn: [Quick Tunnels](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/),
[Firewall của Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/tunnel-with-firewall/),
[Payload và phản hồi SePay](https://developer.sepay.vn/vi/sepay-webhooks/tich-hop-webhook).
