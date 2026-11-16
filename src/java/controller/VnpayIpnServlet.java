package controller;

import dao.VnpayPaymentDAO;
import dao.VnpayPaymentDAO.PaymentResult;
import util.VnpayConfig;
import util.VnpayUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;

/** Authenticated server-to-server payment confirmation; no browser session needed. */
@WebServlet(name = "VnpayIpnServlet", urlPatterns = {"/payment/vnpay/ipn"})
public class VnpayIpnServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json");
        resp.setHeader("Cache-Control", "no-store");

        if (!VnpayConfig.isConfigured()) {
            reply(resp, "99", "Payment not configured");
            return;
        }
        Map<String, String> params = VnpayUtil.callbackParameters(req.getParameterMap());
        if (!VnpayUtil.verifyReturnSignature(params)) {
            reply(resp, "97", "Invalid signature");
            return;
        }
        if (!VnpayConfig.tmnCode().equals(params.get("vnp_TmnCode"))) {
            reply(resp, "97", "Invalid merchant");
            return;
        }
        if (!VnpayUtil.validCallbackFields(params)) {
            reply(resp, "99", "Invalid payment data");
            return;
        }

        long orderId = VnpayUtil.parseTxnRef(params.get("vnp_TxnRef"));
        long amount = Long.parseLong(params.get("vnp_Amount"));
        String transactionNo = params.get("vnp_TransactionNo");
        String responseCode = params.get("vnp_ResponseCode");
        String status = params.get("vnp_TransactionStatus");
        PaymentResult result;
        if ("00".equals(responseCode) && "00".equals(status)) {
            result = paymentDao().processSuccess(orderId, amount, transactionNo);
        } else if ("02".equals(status) && !"00".equals(responseCode) && !"07".equals(responseCode)) {
            result = paymentDao().processFailure(orderId, amount, transactionNo);
        } else {
            // Pending, suspicious or reversed transfers need reconciliation.
            // Do not mark them paid or release their stock as a failed payment.
            reply(resp, "99", "Payment requires reconciliation");
            return;
        }

        switch (result.code) {
            case "SUCCESS":
            case "PAYMENT_FAILED":
                reply(resp, "00", "Confirm Success");
                break;
            case "ALREADY_SUCCESS":
            case "ALREADY_FAILED":
                reply(resp, "02", "Order already confirmed");
                break;
            case "ORDER_NOT_FOUND":
            case "PAYMENT_NOT_FOUND":
                reply(resp, "01", "Order not found");
                break;
            case "AMOUNT_MISMATCH":
                reply(resp, "04", "Invalid amount");
                break;
            default:
                reply(resp, "99", "Unable to confirm payment");
                break;
        }
    }

    /** Allows callback tests to use isolated temporary database tables. */
    protected VnpayPaymentDAO paymentDao() {
        return new VnpayPaymentDAO();
    }

    private void reply(HttpServletResponse resp, String code, String message) throws IOException {
        resp.getWriter().write("{\"RspCode\":\"" + code + "\",\"Message\":\"" + message + "\"}");
    }
}
