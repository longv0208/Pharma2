package controller;

import dao.SePayPaymentDAO;
import util.SePayConfig;
import util.SePayUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.Map;

/** SePay Webhooks: HMAC-SHA256, incoming transfers, JSON or form payload. */
@WebServlet(name = "SePayWebhookServlet", urlPatterns = {"/payment/sepay/webhook"})
public class SePayWebhookServlet extends HttpServlet {
    private static final java.util.logging.Logger LOG = java.util.logging.Logger.getLogger(SePayWebhookServlet.class.getName());
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json");
        resp.setHeader("Cache-Control", "no-store");
        if (!SePayConfig.isConfigured()) {
            reply(resp, 503, false);
            return;
        }
        String type = req.getContentType();
        String mediaType = "";
        if (type != null) mediaType = type.split(";", 2)[0].trim();
        boolean json = mediaType.equalsIgnoreCase("application/json");
        if (!json && !mediaType.equalsIgnoreCase("application/x-www-form-urlencoded")) {
            reply(resp, 415, false);
            return;
        }
        byte[] body = req.getInputStream().readNBytes(16385);
        if (body.length > 16384) {
            reply(resp, 413, false);
            return;
        }
        String timestamp = req.getHeader("X-SePay-Timestamp");
        String signature = req.getHeader("X-SePay-Signature");
        if (!SePayUtil.verifySignature(timestamp, signature, body)) {
            // Diagnose delivery failures without logging credentials or bank payloads.
            String timestampState = "missing or malformed";
            if (timestamp != null && timestamp.matches("[0-9]{1,12}")) {
                long age = java.time.Instant.now().getEpochSecond() - Long.parseLong(timestamp);
                timestampState = Math.abs(age) <= 300 ? "current" : "expired or clock skew";
            }
            boolean signatureFormatValid = signature != null && signature.matches("sha256=[0-9a-fA-F]{64}");
            LOG.log(java.util.logging.Level.WARNING,
                    "SePay authentication rejected: type={0}, timestamp={1}, signatureFormatValid={2}, bodyBytes={3}",
                    new Object[]{mediaType, timestampState, signatureFormatValid, body.length});
            reply(resp, 401, false);
            return;
        }
        try {
            Map<String, String> event;
            if (json) event = SePayUtil.parseJson(body);
            else event = SePayUtil.parseForm(body);
            long orderId = SePayUtil.parsePaymentCode(event.get("content"));
            if (orderId <= 0) {
                // Signed connectivity tests and unrelated events never touch the DAO.
                reply(resp, 200, true);
                return;
            }
            if (!SePayConfig.accountNumber().equals(event.get("accountNumber"))
                    || !SePayConfig.gateway().equalsIgnoreCase(event.getOrDefault("gateway", ""))
                    || (SePayConfig.vaAccount() != null
                    && !SePayConfig.vaAccount().equals(event.get("subAccount")))) {
                reply(resp, 403, false);
                return;
            }
            if (!"in".equals(event.get("transferType"))) {
                reply(resp, 200, true);
                return;
            }
            String id = event.get("id");
            if (id == null || !id.matches("[1-9][0-9]{0,18}")) throw new IllegalArgumentException("Invalid event id");
            String code = event.get("code");
            if (code != null && !code.isBlank() && !code.equalsIgnoreCase(SePayUtil.paymentCode(orderId))) {
                reply(resp, 400, false);
                return;
            }
            BigDecimal amount = SePayUtil.transferAmount(event.get("transferAmount"));
            String result = paymentDao().confirmTransfer(orderId, id, amount);
            if ("DB_ERROR".equals(result)) {
                reply(resp, 503, false);
                return;
            }
            if (!"SUCCESS".equals(result) && !"ALREADY_SUCCESS".equals(result)) {
                LOG.log(java.util.logging.Level.WARNING,
                        "SePay receipt {0}, order {1} requires reconciliation: {2}",
                        new Object[]{id, orderId, result});
            }
            // Acknowledge delivery, not payment success. Only SUCCESS above writes.
            // Wrong amounts/codes/late deposits require reconciliation in SePay.
            reply(resp, 200, true);
        } catch (IllegalArgumentException ex) {
            reply(resp, 400, false);
        }
    }

    protected SePayPaymentDAO paymentDao() {
        return new SePayPaymentDAO();
    }

    private void reply(HttpServletResponse resp, int status, boolean success) throws IOException {
        resp.setStatus(status);
        resp.getWriter().write("{\"success\":" + success + "}");
    }
}
