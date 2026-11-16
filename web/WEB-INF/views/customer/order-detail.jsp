<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đơn hàng #${order.onlineOrderId} — PharmaFlow</title>
    <link rel="stylesheet" href="${ctx}/css/main.css">
</head>
<body>

<%@ include file="/WEB-INF/jspf/header.jspf" %>

<section class="section">
    <div class="container">
        <div class="section-head">
            <div>
                <h2>Đơn hàng #<c:out value="${order.onlineOrderId}"/></h2>
                <p class="section-sub">
                    Đặt lúc <fmt:formatDate value="${order.createdAt}" pattern="yyyy-MM-dd HH:mm"/>
                    <c:if test="${not empty order.updatedAt}">
                        · Cập nhật <fmt:formatDate value="${order.updatedAt}" pattern="yyyy-MM-dd HH:mm"/>
                    </c:if>
                </p>
            </div>
            <a class="btn btn-ghost btn-sm" href="${ctx}/orders">&larr; Đơn hàng của tôi</a>
        </div>

        <c:if test="${param.ok == 'placed' or param.ok == 'cancelled' or param.ok == 'cancel_requested' or param.ok == 'return_requested' or (param.ok == 'paid' and order.paymentStatus == 'DA_THANH_TOAN')}">
            <div class="alert alert-success" role="status">
                <c:choose>
                    <c:when test="${param.ok == 'placed'}">Đặt hàng thành công. Chúng tôi sẽ liên hệ để xác nhận.</c:when>
                    <c:when test="${param.ok == 'paid'}">Thanh toán thành công. Trạng thái đơn hàng: <c:out value="${order.statusLabel}"/>.</c:when>
                    <c:when test="${param.ok == 'cancelled'}">Đã hủy đơn hàng.</c:when>
                    <c:when test="${param.ok == 'cancel_requested'}">Đã gửi yêu cầu hủy. Hàng sẽ về kho sau khi nhân viên kiểm tra.</c:when>
                    <c:when test="${param.ok == 'return_requested'}">Đã gửi yêu cầu hoàn đơn. Nhân viên sẽ xem xét.</c:when>
                    <c:otherwise>Thao tác thành công.</c:otherwise>
                </c:choose>
            </div>
        </c:if>
        <c:if test="${not empty param.err}">
            <div class="alert alert-error" role="alert">
                <c:choose>
                    <c:when test="${param.err == 'NOT_CANCELLABLE'}">Đơn hàng không thể hủy ở trạng thái hiện tại.</c:when>
                    <c:when test="${param.err == 'ONLINE_PAYMENT_NOT_CANCELLABLE'}">Đơn thanh toán trực tuyến không thể hủy sau khi đặt.</c:when>
                    <c:when test="${param.err == 'payment_failed'}">Thanh toán VNPAY không thành công. Đơn hàng đã được hủy.</c:when>
                    <c:when test="${param.err == 'payment_verify'}">Không thể xác minh kết quả thanh toán.</c:when>
                    <c:when test="${param.err == 'ORDER_NOT_FOUND'}">Không tìm thấy đơn hàng.</c:when>
                    <c:when test="${param.err == 'NOT_RETURNABLE'}">Chỉ đơn đã giao mới yêu cầu hoàn được.</c:when>
                    <c:when test="${param.err == 'REASON_REQUIRED'}">Nhập lý do hoàn, tối đa 500 ký tự.</c:when>
                    <c:otherwise>Đã có lỗi xảy ra, vui lòng thử lại.</c:otherwise>
                </c:choose>
            </div>
        </c:if>

        <c:if test="${order.paymentProvider == 'SEPAY' and order.paymentStatus == 'CHO_THANH_TOAN'}">
            <div class="profile-card">
                <h3>Quét QR để thanh toán</h3>
                <c:choose>
                    <c:when test="${not empty bankQrUrl}">
                        <img src="<c:out value='${bankQrUrl}'/>" alt="QR chuyển khoản cho đơn hàng"
                             width="280" height="280" referrerpolicy="no-referrer"
                             style="display:block;max-width:100%;height:auto;margin:16px auto">
                        <p>Ngân hàng: <strong><c:out value="${bankGateway}"/></strong></p>
                        <p>Số tài khoản: <strong><c:out value="${bankAccountNumber}"/></strong></p>
                        <c:if test="${not empty bankAccountName}">
                            <p>Chủ tài khoản: <strong><c:out value="${bankAccountName}"/></strong></p>
                        </c:if>
                        <p>Số tiền: <strong><fmt:formatNumber value="${order.totalAmount}" maxFractionDigits="0"/>&#x20AB;</strong></p>
                        <p>Nội dung chuyển khoản: <strong><c:out value="${bankPaymentCode}"/></strong></p>
                        <p class="field-hint">Giữ nguyên số tiền và nội dung khi chuyển khoản.
                            Trang tự cập nhật khi xác nhận được tiền vào tài khoản.</p>
                    </c:when>
                    <c:otherwise>
                        <p>Chuyển khoản QR đang tạm ngừng. Vui lòng liên hệ cửa hàng để kiểm tra đơn.</p>
                    </c:otherwise>
                </c:choose>
            </div>
        </c:if>

        <c:if test="${order.paymentMethod == 'THANH_TOAN_TRUC_TUYEN' and order.paymentStatus == 'CHO_THANH_TOAN'}">
            <c:url var="paymentStatusUrl" value="/orders">
                <c:param name="action" value="payment-status"/>
                <c:param name="id" value="${order.onlineOrderId}"/>
            </c:url>
            <div id="payment-watch" class="alert" role="status"
                 data-status-url="<c:out value='${paymentStatusUrl}'/>">
                Đang chờ xác nhận thanh toán. Trang sẽ tự cập nhật khi có kết quả.
            </div>
            <script src="${ctx}/js/payment-status.js" defer></script>
        </c:if>

        <div class="profile-card">
            <table class="admin-table">
                <tbody>
                <tr>
                    <th style="width:220px">Trạng thái</th>
                    <td>
                        <span class="status-badge ${order.statusCss}">
                            <c:out value="${order.statusLabel}"/>
                        </span>
                    </td>
                </tr>
                <tr>
                    <th>Thanh toán</th>
                    <td>
                        <c:out value="${order.paymentLabel}"/>
                        <span class="field-hint">(<c:out value="${order.paymentStatusLabel}"/>)</span>
                    </td>
                </tr>
                <tr>
                    <th>Người nhận</th>
                    <td><c:out value="${order.customerName}"/></td>
                </tr>
                <tr>
                    <th>Điện thoại</th>
                    <td><c:out value="${order.customerPhone}"/></td>
                </tr>
                <tr>
                    <th>Địa chỉ giao hàng</th>
                    <td><c:out value="${order.fullAddress}"/></td>
                </tr>
                </tbody>
            </table>
        </div>

        <div class="profile-card" style="margin-top:24px">
            <table class="admin-table">
                <thead>
                <tr>
                    <th>Sản phẩm</th>
                    <th>SKU</th>
                    <th>Đơn vị</th>
                    <th class="col-num">Đơn giá</th>
                    <th class="col-num">Số lượng</th>
                    <th class="col-num">Thành tiền</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="item" items="${items}">
                    <tr>
                        <td>
                            <a href="${ctx}/products/${item.productId}">
                                <c:out value="${item.productName}"/>
                            </a>
                        </td>
                        <td><c:out value="${item.sku}"/></td>
                        <td><c:out value="${item.sellingUnit}"/></td>
                        <td class="col-num">
                            <fmt:formatNumber value="${item.unitPrice}" type="number" groupingUsed="true"/>
                        </td>
                        <td class="col-num"><c:out value="${item.quantity}"/></td>
                        <td class="col-num">
                            <fmt:formatNumber value="${item.subtotal}" type="number" groupingUsed="true"/>&#x20AB;
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>

            <div class="pos-total-row">
                <span>Tổng cộng</span>
                <span class="pos-total">
                    <fmt:formatNumber value="${order.totalAmount}" type="number" groupingUsed="true"/>&#x20AB;
                </span>
            </div>

            <c:if test="${not empty order.returnReason}">
                <p class="field-hint">Lý do hoàn: <c:out value="${order.returnReason}"/></p>
            </c:if>
            <c:if test="${order.cancellable}">
                <div class="profile-actions">
                    <form method="post" action="${ctx}/orders?action=cancel"
                          onsubmit="return confirm('${order.orderStatus == 'CHO_XU_LY' ? 'Bạn chắc chắn muốn hủy đơn hàng này?' : 'Gửi yêu cầu hủy? Hàng chỉ về kho sau khi nhân viên kiểm tra.'}');">
                        <input type="hidden" name="orderId" value="${order.onlineOrderId}">
                        <button type="submit" class="btn btn-danger">
                            ${order.orderStatus == 'CHO_XU_LY' ? 'Hủy đơn hàng' : 'Yêu cầu hủy đơn'}
                        </button>
                    </form>
                </div>
            </c:if>
            <c:if test="${order.returnable}">
                <form method="post" action="${ctx}/orders?action=return" class="profile-form"
                      style="margin-top:16px"
                      onsubmit="return confirm('Gửi yêu cầu hoàn đơn này?');">
                    <input type="hidden" name="orderId" value="${order.onlineOrderId}">
                    <div class="form-field">
                        <label for="reason">Lý do hoàn đơn</label>
                        <textarea id="reason" name="reason" rows="3" maxlength="500" required
                                  placeholder="Mô tả lý do trả hàng"></textarea>
                    </div>
                    <button type="submit" class="btn btn-danger">Yêu cầu hoàn đơn</button>
                </form>
            </c:if>
        </div>
    </div>
</section>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

</body>
</html>
