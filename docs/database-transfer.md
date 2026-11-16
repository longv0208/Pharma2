# Chuyển database PharmaFlow sang máy khác

File nhập đầy đủ: [`sql/pharmaflow2_full_20261102.sql`](../sql/pharmaflow2_full_20261102.sql).
File được xuất trực tiếp từ database `pharmaflow2` đang được cấu hình trong
`src/java/db/DBContext.java` ngày **02/11/2026**, trên MySQL **8.4.9**.

File chứa lệnh tạo database, tạo bảng và nhập toàn bộ dữ liệu tại thời điểm
xuất: **31 bảng, 271 bản ghi**, gồm **36 sản phẩm**, **20 bản ghi thông tin
danh mục/đường dẫn ảnh**, **8 danh mục** và **9 tài khoản ứng dụng**. Các ID,
khóa chính, khóa ngoại, chỉ mục, CHECK, AUTO_INCREMENT và dữ liệu tiếng Việt
được giữ lại. Mật khẩu tài khoản ứng dụng vẫn ở dạng hash như database gốc.

Đây là bản chụp dữ liệu ngày 02/11/2026; thay đổi phát sinh sau đó cần được
xuất lại nếu muốn chuyển tiếp. Dùng MySQL 8.x; phiên bản đã nhập thử là
MySQL 8.4.9. Không dùng file này cho MySQL 5.7 hoặc MariaDB.

## 1. Chuẩn bị trên máy nhận

1. Cài và khởi động MySQL; khuyến nghị cùng phiên bản MySQL 8.4.
2. Sao chép toàn bộ mã nguồn dự án, gồm thư mục `web/images/products`.
3. Dùng tài khoản MySQL có quyền tạo database, tạo bảng và nhập dữ liệu.
   Tài khoản MySQL này được cấu hình trên máy nhận; file SQL không tạo
   tài khoản đăng nhập máy chủ MySQL.
4. Máy nhận phải chưa có database tên `pharmaflow2`. Nếu đã có, chọn tên mới
   và thay tên trong **hai câu lệnh `CREATE DATABASE` và `USE` ở đầu file**,
   rồi cập nhật `DB_URL` của ứng dụng theo tên đó.

Không chạy file lên database đang có dữ liệu. File cố ý không chứa lệnh
`DROP DATABASE`, `DROP TABLE` hay `TRUNCATE`; câu `CREATE DATABASE` sẽ báo lỗi
nếu tên đã tồn tại. Khi có lỗi, dừng thực thi, không tiếp tục các câu lệnh
phía sau và không dùng tùy chọn `mysql --force`.

## 2. Nhập bằng MySQL Workbench

1. Kết nối tới MySQL trên máy nhận.
2. Chọn **File → Open SQL Script**, mở `sql/pharmaflow2_full_20261102.sql`.
3. Thực thi **toàn bộ file** bằng nút Execute hoặc **Ctrl + Shift + Enter**.
   File tự tạo và chọn database, không cần chạy seed trước.
4. Kiểm tra phần Action Output không có lỗi, sau đó Refresh Schemas.

Hai câu lệnh đầu tiên có dạng:

```sql
CREATE DATABASE `pharmaflow2`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `pharmaflow2`;
```

Các câu `CREATE TABLE` và `INSERT INTO` còn lại đã có sẵn trong file;
cần chạy cả file để có đủ cấu trúc và dữ liệu.

## 3. Hoặc nhập bằng Command Prompt trên Windows

Mở **Command Prompt (cmd.exe)** tại thư mục `Pharma_Flow-main`, rồi chạy:

```bat
mysql -h 127.0.0.1 -P 3306 -u root -p --default-character-set=utf8mb4 < sql\pharmaflow2_full_20261102.sql
```

Nhập mật khẩu MySQL của máy nhận khi được hỏi. Nếu tài khoản có mật khẩu
trống, nhấn Enter. Thay `root`, địa chỉ máy chủ và cổng theo cấu hình thực tế.

Nếu `mysql` chưa nằm trong PATH, dùng đường dẫn đến `mysql.exe`, ví dụ:

```bat
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -h 127.0.0.1 -P 3306 -u root -p --default-character-set=utf8mb4 < sql\pharmaflow2_full_20261102.sql
```

Các lệnh có ký tự `<` ở trên dành cho **cmd.exe**, không dán trực tiếp vào
PowerShell. Với PowerShell, có thể dùng cách mở file bằng Workbench ở mục 2.

## 4. Kiểm tra dữ liệu và cấu hình ứng dụng

Chạy các câu SQL sau trong Workbench. Kết quả mong đợi nằm ở cột cuối:

```sql
USE `pharmaflow2`;

SELECT COUNT(*) AS table_count
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'; -- 31

SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL SELECT 'product_catalog_details', COUNT(*) FROM product_catalog_details
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'users', COUNT(*) FROM users;
-- products: 36; product_catalog_details: 20; categories: 8; users: 9
```

Trong `src/java/db/DBContext.java`, sửa `DB_URL`, `DB_USER`, `DB_PWD` theo
máy nhận. Ví dụ URL khi dùng database và cổng mặc định của dự án:

```text
jdbc:mysql://127.0.0.1:3306/pharmaflow2?useSSL=false&serverTimezone=UTC&characterEncoding=UTF-8
```

Sau đó Clean & Build bằng NetBeans/Ant và triển khai trên Tomcat như hướng
dẫn trong README. Tài khoản ứng dụng được giữ nguyên từ database gốc;
không thay mật khẩu hoặc tạo tài khoản mẫu mới trong bản xuất này.

## 5. Ảnh sản phẩm và các file SQL cũ

Database lưu **đường dẫn ảnh**, ví dụ `/images/products/EFFERALGAN500.jpg`.
File ảnh nằm trong `web/images/products` và được đóng gói vào WAR. Một số
SKU cũ còn được ánh xạ tại `Product.getImagePath()`. Vì vậy phải chuyển cả
mã nguồn/ảnh hoặc WAR được build từ mã nguồn này để ảnh hiển thị đầy đủ.

Bản xuất đã gồm bảng `product_catalog_details` và dữ liệu của các migration
danh mục hiện tại. **Không chạy thêm** `db.sql`, `db_vi_full.sql`, seed cũ
hoặc các migration ngày 26/10 và 28/10 sau khi nhập bản này. Các file cũ được
giữ lại để tham khảo lịch sử.

## 6. Kiểm chứng bản xuất

Đã nhập thử file vào database tạm riêng trên MySQL 8.4.9 và xác nhận:

- Đủ 31 bảng và 271 bản ghi; số dòng của từng bảng khớp database gốc.
- Cấu trúc, thuộc tính cột, chỉ mục, CHECK và AUTO_INCREMENT khớp nguồn.
- Dữ liệu toàn bộ bảng khớp SHA-256 sau khi xuất theo cùng thứ tự khóa chính.
- Kiểm tra đủ 49 khóa ngoại, không có dòng tham chiếu tới bản ghi không tồn tại.
- Cả 20 đường dẫn ảnh trong `product_catalog_details` đều có file tương ứng
  trong `web/images/products`.
- Database tạm đã được xóa sau kiểm tra; database gốc không bị thay đổi.
