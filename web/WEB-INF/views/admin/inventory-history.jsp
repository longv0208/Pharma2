<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:set var="adminNav" value="inventory-history"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/WEB-INF/jspf/admin-head.jspf" %>
    <title>Lịch sử Tồn kho — PharmaFlow</title>
</head>
<body class="admin-layout">

<%@ include file="/WEB-INF/jspf/admin-nav.jspf" %>

<div class="admin-shell">
    <%@ include file="/WEB-INF/jspf/admin-sidebar.jspf" %>

    <main class="admin-main">
        <nav class="crumbs" aria-label="Breadcrumb">
            <a href="${ctx}/inventory">Tồn kho</a>
            <span aria-hidden="true">›</span>
            <span>Lịch sử</span>
        </nav>

        <div class="section-head">
            <div>
                <h2>Lịch sử Tồn kho</h2>
                <p class="section-sub">Mỗi dòng hiện đủ tên, lô và loại. Số trước/sau và lý do nằm ở trang chi tiết.</p>
            </div>
        </div>

        <c:if test="${param.err == 'notfound'}">
            <div class="alert alert-error" role="alert">Không tìm thấy biến động kho.</div>
        </c:if>

        <%-- Filter bar --%>
        <form class="filter-bar" method="get" action="${ctx}/inventory">
            <input type="hidden" name="action" value="history">
            <input type="search" name="q" value="<c:out value='${param.q}'/>"
                   placeholder="Tên sản phẩm hoặc SKU…" aria-label="Tìm kiếm sản phẩm">
            <input type="search" name="batch" value="<c:out value='${param.batch}'/>"
                   placeholder="Số lô…" aria-label="Tìm kiếm lô">
            <select name="type" aria-label="Loại biến động">
                <option value="">Tất cả loại</option>
                <option value="NHAP_KHO"               ${param.type == 'NHAP_KHO'               ? 'selected' : ''}>Nhập kho</option>
                <option value="BAN_TAI_QUAY"           ${param.type == 'BAN_TAI_QUAY'           ? 'selected' : ''}>Bán tại quầy</option>
                <option value="GIU_HANG_ONLINE"        ${param.type == 'GIU_HANG_ONLINE'        ? 'selected' : ''}>Giữ hàng online</option>
                <option value="GIAI_PHONG_GIU_HANG"    ${param.type == 'GIAI_PHONG_GIU_HANG'    ? 'selected' : ''}>Giải phóng giữ hàng</option>
                <option value="BAN_ONLINE"             ${param.type == 'BAN_ONLINE'             ? 'selected' : ''}>Bán online</option>
                <option value="DIEU_CHINH"             ${param.type == 'DIEU_CHINH'             ? 'selected' : ''}>Điều chỉnh</option>
                <option value="DIEU_CHINH_KIEM_KE"     ${param.type == 'DIEU_CHINH_KIEM_KE'     ? 'selected' : ''}>Điều chỉnh kiểm kê</option>
                <option value="KHOA"                   ${param.type == 'KHOA'                   ? 'selected' : ''}>Khóa</option>
                <option value="MO_KHOA"                ${param.type == 'MO_KHOA'                ? 'selected' : ''}>Mở khóa</option>
                <option value="CHUYEN_VI_TRI"          ${param.type == 'CHUYEN_VI_TRI'          ? 'selected' : ''}>Chuyển vị trí</option>
                <option value="HOAN_HANG"              ${param.type == 'HOAN_HANG'              ? 'selected' : ''}>Hoàn hàng</option>
            </select>
            <input type="date" name="from" value="<c:out value='${param.from}'/>" aria-label="Từ ngày">
            <input type="date" name="to" value="<c:out value='${param.to}'/>" aria-label="Đến ngày">
            <button type="submit" class="btn btn-secondary btn-sm">Lọc</button>
            <a href="${ctx}/inventory?action=history" class="btn btn-ghost btn-sm">Đặt lại</a>
        </form>

        <div class="admin-card">
            <c:choose>
                <c:when test="${empty movements}">
                    <div class="empty-state"><p>Không tìm thấy biến động nào.</p></div>
                </c:when>
                <c:otherwise>
                    <table class="admin-table ledger-table">
                        <thead>
                        <tr>
                            <th>Ngày / giờ</th>
                            <th>Sản phẩm</th>
                            <th>Lô</th>
                            <th>Loại</th>
                            <th class="col-num">Tồn thực tế</th>
                            <th class="col-num">Đã đặt</th>
                            <th>Người thực hiện</th>
                            <th class="col-act">Chi tiết</th>
                        </tr>
                        </thead>
                        <tbody>
                        <c:forEach var="m" items="${movements}">
                            <tr>
                                <td class="col-when">
                                    <fmt:formatDate value="${m.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                                </td>
                                <td>
                                    <a href="${ctx}/inventory?action=product&id=${m.productId}">
                                        <c:out value="${m.productName}"/>
                                    </a>
                                    <span class="cell-sub"><c:out value="${m.sku}"/></span>
                                </td>
                                <td>
                                    <a href="${ctx}/inventory?action=batch&id=${m.batchId}">
                                        <c:out value="${m.batchNumber}"/>
                                    </a>
                                </td>
                                <td>
                                    <span class="status-badge ${m.movementCss}">
                                        <c:out value="${m.movementLabel}"/>
                                    </span>
                                </td>
                                <td class="col-num">
                                    <span class="${m.onHandChange > 0 ? 'qty-up' : (m.onHandChange < 0 ? 'qty-down' : '')}">
                                        <c:out value="${m.onHandChangeLabel}"/>
                                    </span>
                                    <span class="cell-sub">còn <c:out value="${m.onHandAfter}"/></span>
                                </td>
                                <td class="col-num">
                                    <span class="${m.reservedChange > 0 ? 'qty-up' : (m.reservedChange < 0 ? 'qty-down' : '')}">
                                        <c:out value="${m.reservedChangeLabel}"/>
                                    </span>
                                    <span class="cell-sub">còn <c:out value="${m.reservedAfter}"/></span>
                                </td>
                                <td><c:out value="${m.performedByName}"/></td>
                                <td class="col-actions">
                                    <a class="btn btn-secondary btn-sm"
                                       href="${ctx}/inventory?action=movement&id=${m.movementId}">Xem</a>
                                </td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>

                    <%-- Pagination --%>
                    <c:url var="pagerBase" value="/inventory">
                        <c:param name="action" value="history"/>
                        <c:param name="q" value="${param.q}"/>
                        <c:param name="batch" value="${param.batch}"/>
                        <c:param name="type" value="${param.type}"/>
                        <c:param name="productId" value="${param.productId}"/>
                        <c:param name="batchId" value="${param.batchId}"/>
                        <c:param name="from" value="${param.from}"/>
                        <c:param name="to" value="${param.to}"/>
                    </c:url>
                    <c:set var="pagerPages" value="${totalPages}"/>
                    <%@ include file="/WEB-INF/jspf/pager.jspf" %>
                </c:otherwise>
            </c:choose>
        </div>
    </main>
</div>

<%@ include file="/WEB-INF/jspf/admin-footer.jspf" %>

</body>
</html>

