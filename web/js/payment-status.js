(function () {
    "use strict";
    const notice = document.getElementById("payment-watch");
    const pendingOrders = document.querySelectorAll("[data-payment-status-url]");
    if (!notice && pendingOrders.length === 0) return;
    const targets = notice ? [notice] : Array.from(pendingOrders);
    const started = Date.now();

    function showMessage(message) {
        if (notice) notice.textContent = message;
    }

    async function checkPayment() {
        if (Date.now() - started > 20 * 60 * 1000) {
            showMessage("Chưa nhận được xác nhận thanh toán. Bạn có thể tải lại trang để kiểm tra hoặc liên hệ cửa hàng.");
            return;
        }
        if (!document.hidden) {
            for (const target of targets) {
                try {
                    const response = await fetch(target.dataset.statusUrl || target.dataset.paymentStatusUrl, {
                        credentials: "same-origin",
                        cache: "no-store",
                        headers: { Accept: "application/json" }
                    });
                    if (response.redirected || response.status === 401 || response.status === 403) {
                        showMessage("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để xem kết quả.");
                        return;
                    }
                    if (response.status === 404) {
                        showMessage("Không tìm thấy đơn hàng. Vui lòng kiểm tra danh sách đơn của bạn.");
                        if (notice) return;
                        continue;
                    }
                    if (response.ok) {
                        const result = await response.json();
                        if (result.paymentStatus === "DA_THANH_TOAN" || result.paymentStatus === "THAT_BAI") {
                            if (!notice) {
                                window.location.reload();
                                return;
                            }
                            const next = new URL(window.location.href);
                            next.searchParams.delete("payment");
                            next.searchParams.delete("ok");
                            next.searchParams.delete("err");
                            if (result.paymentStatus === "DA_THANH_TOAN") {
                                next.searchParams.set("ok", "paid");
                            } else {
                                next.searchParams.set("err", "payment_failed");
                            }
                            window.location.replace(next.toString());
                            return;
                        }
                    }
                } catch (error) {
                    // A network error cannot determine whether money was received.
                    showMessage("Đang kết nối lại để kiểm tra xác nhận thanh toán…");
                }
            }
        }
        window.setTimeout(checkPayment, 3000);
    }

    window.setTimeout(checkPayment, 1000);
}());
