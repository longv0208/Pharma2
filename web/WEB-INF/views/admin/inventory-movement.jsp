<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:set var="adminNav" value="inventory-history"/>
<c:set var="m" value="${movement}"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <%@ include file="/WEB-INF/jspf/admin-head.jspf" %>
    <title>Biến động #<c:out value="${m.movementId}"/> — PharmaFlow</title>
</head>
<body class="admin-layout">

<%@ include file="/WEB-INF/jspf/admin-nav.jspf" %>

<div class="admin-shell">
    <%@ include file="/WEB-INF/jspf/admin-sidebar.jspf" %>

    <main class="admin-main">
        <nav class="crumbs" aria-label="Breadcrumb">
            <a href="${ctx}/inventory">Tồn kho</a>
            <span aria-hidden="true">›</span>
            <a href="${ctx}/inventory?action=history">Lịch sử</a>
            <span aria-hidden="true">›</span>
            <span>Biến động #<c:out value="${m.movementId}"/></span>
        </nav>

        <div class="section-head">
            <div>
                <h2><c:out value="${m.movementLabel}"/></h2>
                <p class="section-sub">
                    <fmt:formatDate value="${m.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                    · <c:out value="${m.productName}"/>
                    · lô <c:out value="${m.batchNumber}"/>
                </p>
            </div>
            <a class="btn btn-ghost" href="${ctx}/inventory?action=history">← Lịch sử</a>
        </div>

        <div class="profile-card">
            <fieldset class="profile-group">
                <legend>Đối tượng</legend>
                <div class="profile-grid">
                    <div class="form-field">
                        <label>Sản phẩm</label>
                        <span>
                            <a href="${ctx}/inventory?action=product&id=${m.productId}">
                                <c:out value="${m.productName}"/>
                            </a>
                        </span>
                    </div>
                    <div class="form-field">
                        <label>SKU</label>
                        <span><c:out value="${m.sku}"/></span>
                    </div>
                    <div class="form-field">
                        <label>Lô</label>
                        <span>
                            <a href="${ctx}/inventory?action=batch&id=${m.batchId}">
                                <c:out value="${m.batchNumber}"/>
                            </a>
                        </span>
                    </div>
                    <div class="form-field">
                        <label>Loại biến động</label>
                        <span class="status-badge ${m.movementCss}"><c:out value="${m.movementLabel}"/></span>
                    </div>
                    <div class="form-field">
                        <label>Người thực hiện</label>
                        <span><c:out value="${empty m.performedByName ? '—' : m.performedByName}"/></span>
                    </div>
                    <div class="form-field">
                        <label>Tham chiếu</label>
                        <span>
                            <c:choose>
                                <c:when test="${empty m.referenceLabel}">—</c:when>
                                <c:when test="${empty m.referencePath}">
                                    <c:out value="${m.referenceLabel}"/>
                                    <c:if test="${m.referenceId != null}"> #<c:out value="${m.referenceId}"/></c:if>
                                </c:when>
                                <c:otherwise>
                                    <a href="${ctx}${m.referencePath}">
                                        <c:out value="${m.referenceLabel}"/> #<c:out value="${m.referenceId}"/>
                                    </a>
                                </c:otherwise>
                            </c:choose>
                        </span>
                    </div>
                </div>
            </fieldset>

            <fieldset class="profile-group">
                <legend>Số lượng</legend>
                <div class="qty-compare">
                    <div>
                        <p class="qty-compare-label">Tồn thực tế</p>
                        <p class="qty-compare-line">
                            <c:out value="${m.onHandBefore}"/>
                            <span aria-hidden="true">→</span>
                            <strong><c:out value="${m.onHandAfter}"/></strong>
                            <span class="${m.onHandChange > 0 ? 'qty-up' : (m.onHandChange < 0 ? 'qty-down' : '')}">
                                (<c:out value="${m.onHandChangeLabel}"/>)
                            </span>
                        </p>
                    </div>
                    <div>
                        <p class="qty-compare-label">Đã đặt</p>
                        <p class="qty-compare-line">
                            <c:out value="${m.reservedBefore}"/>
                            <span aria-hidden="true">→</span>
                            <strong><c:out value="${m.reservedAfter}"/></strong>
                            <span class="${m.reservedChange > 0 ? 'qty-up' : (m.reservedChange < 0 ? 'qty-down' : '')}">
                                (<c:out value="${m.reservedChangeLabel}"/>)
                            </span>
                        </p>
                    </div>
                </div>
            </fieldset>

            <fieldset class="profile-group">
                <legend>Lý do</legend>
                <p class="reason-full">
                    <c:out value="${empty m.reason ? 'Không ghi lý do.' : m.reason}"/>
                </p>
            </fieldset>
        </div>
    </main>
</div>

<%@ include file="/WEB-INF/jspf/admin-footer.jspf" %>

</body>
</html>
