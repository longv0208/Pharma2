package controller;

import dao.VnpayPaymentDAO;
import dao.VnpayPaymentDAO.OrderRowView;
import util.VnpayUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.Map;

/** Browser return displays persisted results; only the signed IPN records payment. */
@WebServlet(name = "VnpayPaymentServlet", urlPatterns = {"/payment/vnpay/return"})
public class VnpayPaymentServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setHeader("Cache-Control", "no-store");
        Map<String, String> params = VnpayUtil.callbackParameters(req.getParameterMap());
        if (!VnpayUtil.verifyReturnSignature(params) || !VnpayUtil.validCallbackFields(params)) {
            sendVerifyError(req, resp, params);
            return;
        }
        long orderId = VnpayUtil.parseTxnRef(params.get("vnp_TxnRef"));
        OrderRowView order = paymentDao().findOrder(orderId);
        long amount = Long.parseLong(params.get("vnp_Amount"));
        if (order == null || !"THANH_TOAN_TRUC_TUYEN".equals(order.paymentMethod)
                || order.totalAmount.multiply(BigDecimal.valueOf(100)).longValueExact() != amount) {
            sendVerifyError(req, resp, params);
            return;
        }

        String result = "&payment=pending";
        if ("DA_THANH_TOAN".equals(order.paymentStatus)) {
            result = "&ok=paid";
        } else if ("THAT_BAI".equals(order.paymentStatus)) {
            result = "&err=payment_failed";
        }
        resp.sendRedirect(req.getContextPath() + "/orders?action=detail&id=" + orderId + result);
    }

    protected VnpayPaymentDAO paymentDao() {
        return new VnpayPaymentDAO();
    }

    private void sendVerifyError(HttpServletRequest req, HttpServletResponse resp,
            Map<String, String> params) throws IOException {
        long orderId = -1;
        if (params != null) {
            orderId = VnpayUtil.parseTxnRef(params.get("vnp_TxnRef"));
        }
        if (orderId > 0) {
            resp.sendRedirect(req.getContextPath() + "/orders?action=detail&id=" + orderId
                    + "&err=payment_verify");
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/orders?err=payment_verify");
    }
}
