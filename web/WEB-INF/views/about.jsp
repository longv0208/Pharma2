<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Tìm hiểu PharmaFlow, quy định bán thuốc, hồ sơ pháp lý, chính sách mua hàng và cách bảo vệ thông tin cá nhân của bạn.">
    <title>Giới thiệu &amp; Chính sách nhà thuốc — PharmaFlow</title>
    <link rel="stylesheet" href="${ctx}/css/main.css?v=20261111">
    <link rel="stylesheet" href="${ctx}/css/about.css?v=20261111-encoding1">
    <script src="${ctx}/js/about.js?v=20261111" defer></script>
</head>
<body class="about-page">
<a class="about-skip" href="#noi-dung">Đến nội dung chính</a>
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<main id="noi-dung">
    <section class="about-hero" aria-labelledby="about-title">
        <div class="container">
            <nav class="about-breadcrumb" aria-label="Đường dẫn">
                <a href="${ctx}/home">Trang chủ</a><span aria-hidden="true">/</span><span>Về PharmaFlow</span>
            </nav>
            <div class="about-hero-grid">
                <div>
                    <p class="about-eyebrow">VỀ NHÀ THUỐC PHARMAFLOW</p>
                    <h1 id="about-title">Hiểu rõ nhà thuốc.<br><span>An tâm mỗi lựa chọn.</span></h1>
                    <p class="about-lead">Thông tin thuốc dễ tra cứu, chính sách dễ hiểu và quyền riêng tư được tôn trọng. Tìm hiểu cách PharmaFlow đồng hành cùng bạn trong việc chăm sóc sức khỏe.</p>
                    <div class="about-hero-actions">
                        <a class="btn btn-primary btn-lg" href="#chinh-sach">Xem chính sách nhà thuốc <span aria-hidden="true">↗</span></a>
                        <a class="about-text-link" href="#bao-mat">Quyền riêng tư của bạn <span aria-hidden="true">→</span></a>
                    </div>
                </div>
                <aside class="about-guide" aria-label="Ba điều bạn cần biết">
                    <div class="about-guide-head">
                        <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><rect x="3" y="7" width="18" height="14" rx="3"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M12 11v6M9 14h6"/></svg>
                        <span>CHĂM SÓC BẮT ĐẦU TỪ SỰ THẤU HIỂU</span>
                    </div>
                    <ol>
                        <li><span>01</span><div><strong>Hiểu về sản phẩm</strong><p>Đọc thông tin, nhãn và hướng dẫn trước khi dùng.</p></div></li>
                        <li><span>02</span><div><strong>Mua thuốc đúng quy định</strong><p>Thuốc kê đơn cần đơn thuốc hợp lệ và tư vấn chuyên môn.</p></div></li>
                        <li><span>03</span><div><strong>Chủ động với dữ liệu của bạn</strong><p>Biết thông tin nào được sử dụng và vì mục đích gì.</p></div></li>
                    </ol>
                </aside>
            </div>
            <div class="about-meta"><span>Giới thiệu · Quy định · Chính sách · Bảo mật</span><span>Rà soát nội dung: <time datetime="2026-11-11">11/11/2026</time></span></div>
        </div>
    </section>

    <div class="container about-layout">
        <aside class="about-sidebar">
            <nav class="about-toc" aria-label="Nội dung trang">
                <p>TRÊN TRANG NÀY</p>
                <a href="#gioi-thieu" aria-current="location"><span>01</span> Giới thiệu nhà thuốc</a>
                <a href="#quy-dinh"><span>02</span> Quy định &amp; hồ sơ pháp lý</a>
                <a href="#chinh-sach"><span>03</span> Chính sách mua hàng</a>
                <a href="#bao-mat"><span>04</span> Bảo mật thông tin</a>
                <a href="#tham-chieu"><span>05</span> Văn bản tham chiếu</a>
                <div class="about-toc-foot">Cần xem lại chính sách?<br><button type="button" id="print-policies" hidden>In hoặc lưu thành PDF <span aria-hidden="true">↗</span></button></div>
            </nav>
        </aside>

        <div class="about-content">
            <section class="about-section" id="gioi-thieu" aria-labelledby="intro-title">
                <p class="about-kicker">01 / GIỚI THIỆU</p>
                <h2 id="intro-title">Nhà thuốc gần hơn với bạn</h2>
                <p>PharmaFlow kết nối việc tra cứu sản phẩm, mua hàng trực tuyến và quản lý hoạt động nhà thuốc. Bạn có thể tìm thông tin sản phẩm, đặt các mặt hàng được phép bán trực tuyến và theo dõi đơn hàng trong tài khoản của mình.</p>
                <div class="about-principles">
                    <article><span class="about-mini-icon" aria-hidden="true">+</span><h3>Thông tin rõ ràng</h3><p>Phân biệt thuốc kê đơn, thuốc không kê đơn và sản phẩm chăm sóc sức khỏe.</p></article>
                    <article><svg class="about-mini-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="m12 3 8 4v5c0 4-4 7-8 9-4-2-8-5-8-9V7l8-4Z"/><path d="m8 12 3 3 5-6"/></svg><h3>Sử dụng có trách nhiệm</h3><p>Thông tin trên website hỗ trợ tra cứu; việc dùng thuốc cần theo hướng dẫn chuyên môn.</p></article>
                    <article><svg class="about-mini-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v3"/></svg><h3>Tôn trọng riêng tư</h3><p>Giải thích mục đích sử dụng dữ liệu và các quyền của khách hàng.</p></article>
                </div>
                <div class="about-notice"><strong>Thông tin cơ sở</strong><p>Tên pháp nhân, địa chỉ nhà thuốc, dược sĩ phụ trách, số giấy phép và đầu mối liên hệ chính thức chưa được cung cấp trên trang này. Khách hàng cần xác minh những thông tin đó trước khi sử dụng dịch vụ thực tế.</p></div>
            </section>

            <section class="about-section" id="quy-dinh" aria-labelledby="regulations-title">
                <p class="about-kicker">02 / QUY ĐỊNH &amp; PHÁP LÝ</p>
                <h2 id="regulations-title">Hiểu điều kiện hoạt động nhà thuốc</h2>
                <p>Luật Dược 105/2016/QH13 cùng các văn bản sửa đổi, hướng dẫn quy định điều kiện hành nghề, kinh doanh, chất lượng, giá và nguồn gốc thuốc. Các nhóm hồ sơ dưới đây là yêu cầu tham chiếu; không phải xác nhận PharmaFlow đã được cấp phép. <a href="#nguon-duoc" class="about-cite">[1]</a></p>
                <h3 class="about-subheading">Các nhóm hồ sơ cốt lõi</h3>
                <div class="about-accordion">
                    <details><summary><span><b>01</b> Chứng chỉ hành nghề dược</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Người chịu trách nhiệm chuyên môn của nhà thuốc phải có chứng chỉ phù hợp. Điều 18 Luật Dược quy định văn bằng đại học ngành dược và 02 năm thực hành chuyên môn tại cơ sở dược phù hợp, cùng các điều kiện hành nghề liên quan.</p><p>Thông tin cần công khai: họ tên dược sĩ phụ trách, số chứng chỉ và phạm vi hành nghề.</p></div></details>
                    <details><summary><span><b>02</b> Đăng ký doanh nghiệp hoặc hộ kinh doanh</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Cơ sở cần đăng ký loại hình và ngành nghề phù hợp. Theo Nghị định 168/2025/NĐ-CP, thủ tục hộ kinh doanh thuộc cơ quan đăng ký kinh doanh cấp xã; doanh nghiệp thực hiện tại cơ quan đăng ký kinh doanh cấp tỉnh theo phân cấp hiện hành. <a href="#nguon-dang-ky" class="about-cite">[5]</a></p></div></details>
                    <details><summary><span><b>03</b> Đáp ứng Thực hành tốt cơ sở bán lẻ thuốc (GPP)</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Nhà thuốc phải đáp ứng và duy trì GPP về nhân sự, cơ sở vật chất, bảo quản, hồ sơ và quy trình thao tác chuẩn. Giấy chứng nhận GPP riêng được cấp theo trường hợp và đề nghị của cơ sở; không nên hiểu mọi cơ sở đều phải có bốn giấy phép độc lập. <a href="#nguon-gpp" class="about-cite">[2]</a></p></div></details>
                    <details><summary><span><b>04</b> Giấy chứng nhận đủ điều kiện kinh doanh dược</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Cơ sở chỉ được kinh doanh trong phạm vi được cấp phép. Việc đánh giá GPP gắn với quy trình thẩm định điều kiện kinh doanh dược theo quy định; cần kiểm tra cơ quan cấp, địa điểm và phạm vi hoạt động ghi trong hồ sơ.</p></div></details>
                </div>
                <h3 class="about-subheading">Điều kiện vận hành cần duy trì</h3>
                <ul class="about-checklist">
                    <li><strong>Bảo quản &amp; truy xuất.</strong> Theo dõi nguồn nhập, số lô, hạn dùng; bảo quản theo nhãn. GPP quy định diện tích nhà thuốc tối thiểu 10 m²; điều kiện nhiệt độ phòng không quá 30°C, độ ẩm không quá 75%. Thuốc cần bảo quản lạnh áp dụng điều kiện riêng. <a href="#nguon-gpp" class="about-cite">[2]</a></li>
                    <li><strong>Thuốc kiểm soát đặc biệt.</strong> Chỉ kinh doanh khi đáp ứng điều kiện và phạm vi được phép, theo Luật Dược, Nghị định 163/2025/NĐ-CP và Thông tư 18/2026/TT-BYT. <a href="#nguon-dac-biet" class="about-cite">[4]</a></li>
                    <li><strong>Hồ sơ &amp; liên thông dữ liệu.</strong> Duy trì phần mềm, dữ liệu mua bán, tồn kho và kết nối theo yêu cầu quản lý dược. Việc giới thiệu chức năng quản lý nội bộ không đồng nghĩa đã hoàn tất liên thông với hệ thống quốc gia. <a href="#nguon-gpp" class="about-cite">[2]</a></li>
                    <li><strong>An toàn phòng cháy, chữa cháy.</strong> Thực hiện điều kiện, hồ sơ và phương án phù hợp quy mô, loại công trình và phân cấp quản lý; không áp dụng một mẫu giấy phép chung cho mọi nhà thuốc. <a href="#nguon-pccc" class="about-cite">[6]</a></li>
                </ul>
            </section>

            <section class="about-section" id="chinh-sach" aria-labelledby="policies-title">
                <p class="about-kicker">03 / CHÍNH SÁCH MUA HÀNG</p>
                <h2 id="policies-title">Rõ ràng từ lựa chọn đến nhận hàng</h2>
                <div class="about-rx-note"><span class="about-rx" aria-hidden="true">Rx</span><div><h3>Thuốc kê đơn cần được kiểm tra đơn tại nhà thuốc</h3><p>PharmaFlow không mở đặt mua trực tuyến cho thuốc kê đơn hoặc thuốc hạn chế. Nội dung về các sản phẩm này phục vụ tra cứu; không thay thế việc khám bệnh và kê đơn.</p></div></div>
                <div class="about-accordion">
                    <details open><summary><span>Phạm vi bán hàng &amp; thông tin sản phẩm</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Trong nhóm thuốc, website chỉ cho phép đặt mua thuốc không kê đơn được cấu hình bán trực tuyến và còn tồn kho hợp lệ. Thuốc hết hạn hoặc thuộc lô bị khóa không được đưa vào lượng hàng có thể bán.</p><p>Kiểm tra tên, hoạt chất, hàm lượng, dạng bào chế, quy cách, hướng dẫn và cảnh báo trên nhãn. Thuốc kê đơn chỉ được cấp bán theo đơn hợp lệ và trong phạm vi được phép. <a href="#nguon-don-thuoc" class="about-cite">[3]</a></p></div></details>
                    <details><summary><span>Giá bán &amp; thanh toán</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Kiểm tra số lượng, đơn giá, phí giao hàng và tổng tiền ở bước xác nhận. Sử dụng phương thức được hiển thị khi thanh toán: COD hoặc chuyển khoản QR nếu được kích hoạt.</p><p>Với chuyển khoản, dùng đúng tài khoản, số tiền và nội dung gắn với đơn hàng. Không chuyển tiền theo thông tin lạ hoặc cung cấp mã OTP, mật khẩu ngân hàng cho người tự nhận là nhân viên.</p></div></details>
                    <details><summary><span>Xác nhận đơn &amp; giao nhận</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Thông tin tiếp nhận đơn chưa thay thế xác nhận khả năng cung ứng. Theo dõi trạng thái trong mục Đơn hàng; cung cấp đúng người nhận, số điện thoại và địa chỉ để giao hàng.</p><p>Thời gian, phạm vi và chi phí giao hàng cần được xác nhận theo từng đơn. Khi nhận, kiểm tra tên sản phẩm, số lượng, bao bì, số lô, hạn dùng và điều kiện bảo quản trên nhãn.</p></div></details>
                    <details><summary><span>Đổi trả, hoàn tiền &amp; phản ánh chất lượng</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Nếu nhận sai hàng, thiếu hàng, bao bì hư hỏng hoặc nghi ngờ chất lượng, giữ sản phẩm, bao bì, mã đơn và chứng từ để đề nghị nhà thuốc kiểm tra. Ngừng dùng sản phẩm nghi ngờ và hỏi ý kiến chuyên môn.</p><p>Việc tiếp nhận đổi trả và hoàn tiền được xem xét theo nguyên nhân, chứng từ, tình trạng sản phẩm và quy định bảo đảm chất lượng thuốc; không mặc định mọi thuốc đã giao đều có thể nhập lại để bán. Thuốc thuộc thông báo thu hồi được xử lý theo hướng dẫn của cơ quan có thẩm quyền.</p><p>Đầu mối tiếp nhận trực tuyến chưa được công bố. Vui lòng xác minh thông tin liên hệ chính thức của cơ sở trước khi gửi phản ánh hoặc dữ liệu cá nhân.</p></div></details>
                </div>
            </section>

            <section class="about-section" id="bao-mat" aria-labelledby="privacy-title">
                <p class="about-kicker">04 / BẢO MẬT THÔNG TIN</p>
                <h2 id="privacy-title">Dữ liệu của bạn, quyền của bạn</h2>
                <p>Chính sách này giải thích việc sử dụng thông tin khi tạo tài khoản, cập nhật hồ sơ và đặt hàng. Thông tin sức khỏe, đơn thuốc cần được bảo vệ ở mức độ phù hợp với dữ liệu nhạy cảm. Căn cứ tham chiếu là Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025/NĐ-CP. <a href="#nguon-du-lieu" class="about-cite">[7]</a></p>
                <div class="about-data-table" role="region" aria-label="Dữ liệu và mục đích sử dụng" tabindex="0">
                    <table>
                        <caption>Thông tin nào được sử dụng?</caption>
                        <thead><tr><th scope="col">Nhóm thông tin</th><th scope="col">Mục đích sử dụng</th></tr></thead>
                        <tbody>
                            <tr><th scope="row">Họ tên, email, điện thoại, tên đăng nhập</th><td>Tạo, xác minh và quản lý tài khoản; trao đổi về giao dịch.</td></tr>
                            <tr><th scope="row">Địa chỉ &amp; thông tin người nhận</th><td>Xử lý và giao đơn hàng đến đúng người nhận.</td></tr>
                            <tr><th scope="row">Đơn hàng &amp; trạng thái thanh toán</th><td>Theo dõi giao dịch, đối soát và giải quyết phản ánh.</td></tr>
                            <tr><th scope="row">Đơn thuốc, thông tin sức khỏe nếu được cung cấp</th><td>Kiểm tra điều kiện cấp bán và hỗ trợ chuyên môn theo căn cứ xử lý phù hợp.</td></tr>
                            <tr><th scope="row">Cookie phiên đăng nhập</th><td>Duy trì phiên và nhận diện tài khoản đang sử dụng.</td></tr>
                        </tbody>
                    </table>
                </div>
                <div class="about-accordion">
                    <details><summary><span>Mục đích, sự đồng ý &amp; chia sẻ dữ liệu</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Dữ liệu cần được xử lý đúng mục đích đã thông báo và trên căn cứ pháp luật phù hợp. Với hoạt động cần sự đồng ý, sự đồng ý phải rõ ràng, có thể kiểm chứng; không mặc định việc đọc trang này là chấp thuận tiếp thị hoặc xử lý dữ liệu sức khỏe.</p><p>Chỉ chia sẻ thông tin cần thiết với bên giao hàng, thanh toán hoặc cơ quan có thẩm quyền theo mục đích và căn cứ hợp pháp. Không sử dụng đơn thuốc, lịch sử mua hàng cho quảng cáo ngoài mục đích đã thông báo và căn cứ xử lý phù hợp.</p></div></details>
                    <details><summary><span>Lưu trữ &amp; biện pháp bảo vệ</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Hệ thống hiện lưu mật khẩu dưới dạng băm và kiểm tra phiên đăng nhập, vai trò khi truy cập chức năng được phân quyền. Đây là các biện pháp đã có; trang này không xác nhận mọi dữ liệu đã được mã hóa hoặc hệ thống đã được chứng nhận an toàn thông tin.</p><p>Thời gian lưu cần gắn với mục đích giao dịch, nghĩa vụ lưu hồ sơ dược, kế toán và các yêu cầu pháp luật liên quan. Khi hết căn cứ lưu giữ, dữ liệu cần được xóa, hủy hoặc khử nhận dạng theo quy trình phù hợp. Không công bố một thời hạn lưu chung cho mọi loại dữ liệu.</p></div></details>
                    <details><summary><span>Quyền truy cập, chỉnh sửa, rút lại đồng ý &amp; xóa dữ liệu</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Bạn có quyền được biết, xem, yêu cầu chỉnh sửa, cung cấp, xóa, hạn chế hoặc phản đối xử lý dữ liệu; rút lại sự đồng ý và thực hiện các quyền khác theo quy định. Một số yêu cầu có thể bị giới hạn khi pháp luật yêu cầu tiếp tục lưu trữ hoặc cho phép xử lý.</p><p>Bạn có thể <a href="${ctx}/profile">xem và cập nhật hồ sơ tài khoản</a> sau khi đăng nhập. Yêu cầu xóa dữ liệu hoặc rút lại sự đồng ý cần được tiếp nhận và xác minh qua đầu mối chính thức của cơ sở; chức năng gửi yêu cầu này trực tuyến hiện chưa được cung cấp.</p></div></details>
                    <details><summary><span>Cookie, liên kết ngoài &amp; bảo vệ tài khoản</span><span class="about-plus" aria-hidden="true">+</span></summary><div class="about-detail"><p>Cookie phiên giúp duy trì đăng nhập. Chặn cookie có thể làm gián đoạn việc sử dụng tài khoản. Trang sử dụng phông chữ Google Fonts theo giao diện chung; khi tải phông, trình duyệt có thể gửi thông tin kết nối đến nhà cung cấp.</p><p>Các liên kết văn bản pháp luật dẫn đến website bên ngoài và chịu chính sách riêng của đơn vị đó. Hãy dùng mật khẩu riêng, đăng xuất trên thiết bị dùng chung và không gửi mật khẩu, OTP hoặc hồ sơ sức khỏe qua kênh chưa được xác minh.</p></div></details>
                </div>
                <div class="about-rights"><div><h3>Chủ động kiểm tra thông tin của bạn</h3><p>Xem lại tên, số điện thoại và địa chỉ giao hàng trong hồ sơ tài khoản.</p></div><a class="btn btn-secondary" href="${ctx}/profile">Mở hồ sơ cá nhân <span aria-hidden="true">→</span></a></div>
            </section>

            <section class="about-section about-sources" id="tham-chieu" aria-labelledby="sources-title">
                <p class="about-kicker">05 / NGUỒN THAM CHIẾU</p>
                <h2 id="sources-title">Tra cứu từ nguồn chính thức</h2>
                <p>Các bản gốc cần được đọc cùng văn bản sửa đổi, bổ sung và quy định chuyển tiếp. Thông tin dưới đây được đối chiếu ngày 11/11/2026.</p>
                <ol class="about-source-list">
                    <li id="nguon-duoc"><span class="about-source-number">01</span><div><h3>Luật Dược &amp; hướng dẫn thi hành</h3><p><a href="https://chinhphu.vn/default.aspx?docid=184569&amp;pageid=27160" target="_blank" rel="noopener noreferrer">Luật 105/2016/QH13 ↗</a> · <a href="https://congbao.chinhphu.vn/van-ban/luat-so-44-2024-qh15-43548/53667.htm" target="_blank" rel="noopener noreferrer">Luật sửa đổi 44/2024/QH15 ↗</a> · <a href="https://congbao.chinhphu.vn/van-ban/nghi-dinh-so-163-2025-nd-cp-45343/57274.htm" target="_blank" rel="noopener noreferrer">Nghị định 163/2025/NĐ-CP ↗</a></p></div></li>
                    <li id="nguon-gpp"><span class="about-source-number">02</span><div><h3>Thực hành tốt cơ sở bán lẻ thuốc (GPP)</h3><p><a href="https://datafiles.chinhphu.vn/cpp/files/vbpq/2025/7/11-vbhn-byt.pdf" target="_blank" rel="noopener noreferrer">Văn bản hợp nhất 11/VBHN-BYT năm 2025 (PDF) ↗</a> · <a href="https://vanban.chinhphu.vn/?docid=219396&amp;pageid=27160" target="_blank" rel="noopener noreferrer">Quyết định 2656/QĐ-BYT năm 2026 ↗</a></p><p class="about-source-note">Quyết định 2656 bãi bỏ điểm đ khoản 1 Điều 5 Thông tư 02/2018/TT-BYT; cần đọc cùng bản hợp nhất.</p></div></li>
                    <li id="nguon-don-thuoc"><span class="about-source-number">03</span><div><h3>Đơn thuốc điều trị ngoại trú</h3><p><a href="https://chinhphu.vn/?docid=214386&amp;pageid=27160" target="_blank" rel="noopener noreferrer">Thông tư 26/2025/TT-BYT ↗</a></p></div></li>
                    <li id="nguon-dac-biet"><span class="about-source-number">04</span><div><h3>Thuốc phải kiểm soát đặc biệt</h3><p><a href="https://congbao.chinhphu.vn/van-ban/thong-tu-so-18-2026-tt-byt-469674/65587.htm" target="_blank" rel="noopener noreferrer">Thông tư 18/2026/TT-BYT ↗</a></p></div></li>
                    <li id="nguon-dang-ky"><span class="about-source-number">05</span><div><h3>Đăng ký doanh nghiệp &amp; hộ kinh doanh</h3><p><a href="https://chinhphu.vn/?docid=214334&amp;pageid=27160" target="_blank" rel="noopener noreferrer">Nghị định 168/2025/NĐ-CP ↗</a></p></div></li>
                    <li id="nguon-pccc"><span class="about-source-number">06</span><div><h3>Phòng cháy, chữa cháy &amp; cứu nạn, cứu hộ</h3><p><a href="https://chinhphu.vn/?docid=212483&amp;pageid=27160" target="_blank" rel="noopener noreferrer">Luật 55/2024/QH15 và văn bản sửa đổi, hướng dẫn ↗</a></p></div></li>
                    <li id="nguon-du-lieu"><span class="about-source-number">07</span><div><h3>Bảo vệ dữ liệu cá nhân</h3><p><a href="https://congbao.chinhphu.vn/van-ban/luat-so-91-2025-qh15-45578/57730.htm" target="_blank" rel="noopener noreferrer">Luật 91/2025/QH15 ↗</a> · <a href="https://vanban.chinhphu.vn/?docid=216387&amp;pageid=27160" target="_blank" rel="noopener noreferrer">Nghị định 356/2025/NĐ-CP ↗</a></p><p class="about-source-note">Từ 01/01/2026, Nghị định 13/2023/NĐ-CP hết hiệu lực theo Điều 42 Nghị định 356/2025/NĐ-CP.</p></div></li>
                </ol>
                <a class="about-dav-link" href="https://dav.gov.vn/" target="_blank" rel="noopener noreferrer"><span>Thông báo quản lý dược, chất lượng &amp; thu hồi thuốc</span><strong>Cục Quản lý Dược (DAV) <span aria-hidden="true">↗</span></strong></a>
                <a class="about-back-top" href="#noi-dung">Về đầu trang ↑</a>
            </section>
        </div>
    </div>
</main>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
</body>
</html>
