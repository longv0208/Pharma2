package payment;

import controller.SePayWebhookServlet;
import controller.OnlineOrderServlet;
import dao.OnlineOrderDAO;
import dao.SePayPaymentDAO;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import java.io.ByteArrayInputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import util.SePayConfig;
import util.SePayUtil;

/** Synthetic signed receipts and connection-local temporary MySQL fixtures. */
public final class SePayPaymentTest {
    private static final String SECRET = "test-only-sepay-webhook-secret-32-chars";
    private static int checks;

    public static void main(String[] args) throws Exception {
        if (System.getenv("SEPAY_WEBHOOK_SECRET") != null) throw new IllegalStateException("Do not run with a real webhook secret");
        check(!SePayConfig.isConfigured(), "Unconfigured bank payments disabled");
        Reply unconfigured = call(null, payload("100000", "in", "PFSP901", "1"), null, null);
        check(unconfigured.status == 503, "Webhook fails closed when not configured");
        System.setProperty("sepay.webhookSecret", SECRET);
        System.setProperty("sepay.accountNumber", "0000000000");
        check(SePayConfig.isConfigured(), "Synthetic configuration enabled");
        check(SePayUtil.parsePaymentCode("MB transfer pfsp901") == 901, "Memo matching is case insensitive");
        check(SePayUtil.parsePaymentCode("PFSP901 PFSP902") < 0, "Ambiguous memo rejected");
        check(SePayUtil.parsePaymentCode("XPFSP901") < 0, "Embedded code rejected");
        check(SePayUtil.parsePaymentCode("PFSP0901") < 0, "Leading-zero code rejected");
        check(SePayUtil.parsePaymentCode("PFSP9999999999999999999") < 0, "Overflow code rejected");
        String qr = SePayUtil.qrUrl(901, new BigDecimal("100000.00"));
        check(qr.startsWith("https://vietqr.app/img?"), "Documented QR image endpoint");
        check(qr.contains("amount=100000&des=PFSP901"), "QR contains exact VND amount and unique memo");
        boolean refusedFraction = false;
        try { SePayUtil.qrUrl(901, new BigDecimal("100000.50")); }
        catch (ArithmeticException expected) { refusedFraction = true; }
        check(refusedFraction, "QR never rounds payment amounts");

        testSuccessAndReplay();
        testInvalidCallbacks();
        testRemovedVnpayCheckout();
        testCheckoutAndOwnership();
        testVirtualAccount();
        testJsonNotifications();
        System.out.println("PASS " + checks + " SePay checks; only synthetic bank events were used");
    }

    private static void testSuccessAndReplay() throws Exception {
        try (VnpayPaymentTest.Fixture fixture = new VnpayPaymentTest.Fixture()) {
            fixture.execute("UPDATE online_payments SET provider = 'SEPAY'");
            SePayPaymentDAO dao = dao(fixture);
            String body = payload("100000", "in", "PFSP901", "1001");
            check(call(dao, body, null, null).status == 200, "Valid signed webhook accepted");
            check(fixture.scalar("SELECT payment_status FROM online_payments").equals("THANH_CONG"), "Receipt pays payment row");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("DA_THANH_TOAN"), "Receipt pays order");
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("DA_XAC_NHAN"), "Verified receipt automatically confirms order");
            check(fixture.scalar("SELECT transaction_reference FROM online_payments").equals("SEPAY:1001"), "Receipt identity stored");
            check(fixture.scalar("SELECT paid_at IS NOT NULL FROM online_payments").equals("1"), "Payment time stored");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("3"), "Reserved stock preserved");
            check(fixture.scalar("SELECT on_hand_quantity FROM inventory_batches").equals("10"), "Physical stock preserved");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("0"), "No stock movement on payment");
            check(dao.confirmTransfer(901, "1001", new BigDecimal("100000")).equals("ALREADY_SUCCESS"), "Receipt replay idempotent");
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("DA_XAC_NHAN"), "Replay keeps order confirmed");
            fixture.execute("UPDATE online_orders SET order_status = 'CHO_XU_LY'");
            check(dao.confirmTransfer(901, "1001", new BigDecimal("100000")).equals("ALREADY_SUCCESS"), "Verified legacy receipt can be reconciled");
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("DA_XAC_NHAN"), "Reconciliation confirms previously paid waiting order");
            fixture.execute("UPDATE online_orders SET order_status = 'DANG_CHUAN_BI'");
            dao.confirmTransfer(901, "1001", new BigDecimal("100000"));
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("DANG_CHUAN_BI"), "Replay cannot reset fulfillment progress");
            fixture.execute("UPDATE online_orders SET order_status = 'DA_HUY'");
            dao.confirmTransfer(901, "1001", new BigDecimal("100000"));
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("DA_HUY"), "Replay cannot revive a cancelled paid order");
            fixture.execute("UPDATE online_orders SET order_status = 'DA_XAC_NHAN'");
            check(dao.confirmTransfer(901, "1002", new BigDecimal("100000")).equals("INVALID_STATE"), "Second deposit cannot overwrite captured payment");
            check(fixture.scalar("SELECT IS_FREE_LOCK('PharmaFlow:SePay:1001')").equals("1"), "Receipt lock released");
            check(dao.confirmTransfer(902, "1001", new BigDecimal("100000")).equals("RECEIPT_ALREADY_USED"), "One receipt cannot pay a different order");
        }
    }

    private static void testInvalidCallbacks() throws Exception {
        try (VnpayPaymentTest.Fixture fixture = new VnpayPaymentTest.Fixture()) {
            fixture.execute("UPDATE online_payments SET provider = 'SEPAY'");
            SePayPaymentDAO dao = dao(fixture);
            String valid = payload("100000", "in", "PFSP901", "2001");
            check(call(dao, valid, "sha256=" + "0".repeat(64), null).status == 401, "Forged signature rejected");
            String oldTime = Long.toString(Instant.now().getEpochSecond() - 600);
            check(call(dao, valid, null, oldTime).status == 401, "Expired signed callback rejected");
            String futureTime = Long.toString(Instant.now().getEpochSecond() + 600);
            check(call(dao, valid, null, futureTime).status == 401, "Future signed callback rejected");
            check(call(dao, valid.replace("0000000000", "9999999999"), null, null).status == 403, "Wrong receiving account rejected");
            check(call(dao, valid.replace("MBBank", "OtherBank"), null, null).status == 403, "Wrong receiving bank rejected");
            check(call(dao, valid + "&transferAmount=1", null, null).status == 400, "Duplicate amount fields rejected");
            check(call(dao, valid + "&bad=%ZZ", null, null).status == 400, "Malformed encoding rejected");
            check(call(dao, payload("1e5", "in", "PFSP901", "2002"), null, null).status == 400, "Invalid amount format rejected");
            check(call(dao, payload("100000", "in", "PFSP901", "-1"), null, null).status == 400, "Invalid receipt id rejected");
            check(call(dao, payload("100000", "out", "PFSP901", "2003"), null, null).status == 200, "Outgoing money acknowledged without paying order");
            check(call(dao, payload("100000", "in", "no order code", "2004"), null, null).status == 200, "Unrelated transfer ignored");
            call(dao, payload("99999", "in", "PFSP901", "2005"), null, null);
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("CHO_THANH_TOAN"), "Underpayment never completes payment");
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("CHO_XU_LY"), "Underpayment never confirms order");
            call(dao, payload("100001", "in", "PFSP901", "2006"), null, null);
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("CHO_THANH_TOAN"), "Overpayment requires reconciliation");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("3"), "Invalid receipts do not release stock");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("0"), "Invalid receipts make no inventory writes");
            fixture.execute("UPDATE online_payments SET provider = 'VNPAY'");
            check(dao.confirmTransfer(901, "2007", new BigDecimal("100000")).equals("INVALID_STATE"), "SePay cannot confirm a VNPAY payment");
            check(dao.confirmTransfer(999, "2008", new BigDecimal("100000")).equals("ORDER_NOT_FOUND"), "Unknown order rejected");
            fixture.execute("UPDATE online_payments SET provider = 'SEPAY'");
            fixture.execute("UPDATE online_orders SET order_status = 'DA_HUY'");
            check(dao.confirmTransfer(901, "2009", new BigDecimal("100000")).equals("INVALID_STATE"), "Late payment cannot revive cancelled order");
        }
    }

    private static void testRemovedVnpayCheckout() throws Exception {
        java.lang.reflect.Method place = OnlineOrderServlet.class.getDeclaredMethod("handlePlace",
                HttpServletRequest.class, HttpServletResponse.class, User.class, long.class);
        place.setAccessible(true);
        for (String removed : new String[]{"THANH_TOAN_TRUC_TUYEN", "VNPAY", "UNKNOWN"}) {
            Map<String, Object> attributes = new LinkedHashMap<>();
            attributes.put("onlineCheckoutToken", "test-checkout-token");
            HttpSession session = (HttpSession) Proxy.newProxyInstance(SePayPaymentTest.class.getClassLoader(),
                    new Class<?>[]{HttpSession.class}, (proxy, method, args) -> {
                        if (method.getName().equals("getAttribute")) return attributes.get(args[0]);
                        if (method.getName().equals("removeAttribute")) attributes.remove(args[0]);
                        return null;
                    });
            HttpServletRequest request = (HttpServletRequest) Proxy.newProxyInstance(SePayPaymentTest.class.getClassLoader(),
                    new Class<?>[]{HttpServletRequest.class}, (proxy, method, args) -> {
                        if (method.getName().equals("getSession")) return session;
                        if (method.getName().equals("getContextPath")) return "/Pharma_Flow";
                        if (method.getName().equals("getParameter")) {
                            if (args[0].equals("checkoutToken")) return "test-checkout-token";
                            if (args[0].equals("paymentMethod")) return removed;
                            return "TEST";
                        }
                        throw new AssertionError("Unexpected checkout operation: " + method.getName());
                    });
            Reply reply = new Reply();
            place.invoke(new OnlineOrderServlet(), request, reply.response(), new User(), 999L);
            check("/Pharma_Flow/orders?action=checkout&err=payment_method".equals(reply.redirect),
                    "Removed or unknown checkout method is refused: " + removed);
        }
    }

    private static void testCheckoutAndOwnership() throws Exception {
        try (VnpayPaymentTest.Fixture fixture = new VnpayPaymentTest.Fixture()) {
            for (String table : new String[]{"products", "carts", "cart_items", "online_order_items"}) fixture.createTemporaryTable(table);
            fixture.execute("INSERT INTO products (product_id, category_id, product_name, sku, product_type, "
                    + "selling_unit, selling_price, online_sale_allowed, status) "
                    + "VALUES (1,1,'SEPAY TEST','SEPAY-TEST','KHONG_KE_DON','Hộp',100000,1,'HOAT_DONG')");
            fixture.execute("INSERT INTO carts (cart_id, customer_id, status) VALUES (901,999,'DANG_HOAT_DONG')");
            fixture.execute("INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (901,1,1)");
            OnlineOrderDAO orders = new OnlineOrderDAO() {
                @Override public Connection getConnection() { return fixture.dao.getConnection(); }
            };
            OnlineOrderDAO.OrderResult refused = orders.placeOrder(999,999,"SEPAY TEST","0000000000",
                    "TEST","TEST","TEST","TEST","THANH_TOAN_TRUC_TUYEN","VNPAY");
            check(!refused.ok && "INVALID_PAYMENT_METHOD".equals(refused.error), "DAO refuses creation of new VNPAY payments");
            check(fixture.scalar("SELECT COUNT(*) FROM online_orders").equals("1"), "Refused provider creates no order");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("3"), "Refused provider reserves no stock");
            check(fixture.scalar("SELECT status FROM carts").equals("DANG_HOAT_DONG"), "Refused provider preserves cart");
            OnlineOrderDAO.OrderResult placed = orders.placeOrder(999,999,"SEPAY TEST","0000000000",
                    "TEST","TEST","TEST","TEST","THANH_TOAN_TRUC_TUYEN");
            check(placed.ok, "Checkout creates SePay order atomically");
            check(orders.findOrderForCustomer(placed.orderId,999).getPaymentProvider().equals("SEPAY"), "Customer order reports correct provider");
            check(orders.findOrderForCustomer(placed.orderId,998) == null, "Another customer cannot read payment order");
            check(orders.findOrders(999,0,10).get(0).getPaymentProvider().equals("SEPAY"), "Order history identifies SePay");
            check(fixture.scalar("SELECT status FROM carts").equals("DA_CHUYEN_THANH_DON"), "Checkout consumes cart");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("4"), "Checkout reserves stock normally");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batch_locations").equals("4"),
                    "Checkout reserves stock at the selected bin");
            Reply paid = call(dao(fixture), payload("100000","in","PFSP" + placed.orderId,"3001"),null,null);
            check(paid.status == 200, "Checkout followed by signed bank receipt succeeds");
            check(orders.findOrderForCustomer(placed.orderId,999).getPaymentStatus().equals("DA_THANH_TOAN"), "New checkout becomes paid automatically");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("4"), "Payment preserves checkout reservation");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batch_locations").equals("4"),
                    "Payment preserves the reserved quantity at the bin");
        }
    }

    private static void testVirtualAccount() throws Exception {
        System.setProperty("sepay.vaAccount", "VATEST0000001");
        try (VnpayPaymentTest.Fixture fixture = new VnpayPaymentTest.Fixture()) {
            fixture.execute("UPDATE online_payments SET provider = 'SEPAY'");
            check(SePayConfig.isConfigured(), "VA configuration accepted");
            check(SePayConfig.qrAccountNumber().equals("VATEST0000001"), "QR uses VA number");
            check(SePayUtil.qrUrl(901, new BigDecimal("100000")).contains("acc=VATEST0000001&"), "Dynamic QR directs payment to VA");
            check(SePayConfig.accountNumber().equals("0000000000"), "Main account remains separate");
            SePayPaymentDAO dao = dao(fixture);
            String body = payload("100000", "in", "PFSP901", "4001");
            check(call(dao, body, null, null).status == 403, "Missing VA rejected when VA configured");
            check(call(dao, body + "&subAccount=OTHER0000001", null, null).status == 403, "Different VA rejected");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("CHO_THANH_TOAN"), "Wrong VA cannot pay order");
            String correct = body + "&subAccount=VATEST0000001";
            check(call(dao, correct.replace("accountNumber=0000000000", "accountNumber=9999999999"), null, null).status == 403,
                    "Correct VA still requires main receiving account");
            check(call(dao, correct, null, null).status == 200, "Matching main account and VA accepted");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("DA_THANH_TOAN"), "VA transfer completes payment");
        } finally {
            System.clearProperty("sepay.vaAccount");
        }
        check(SePayConfig.qrAccountNumber().equals("0000000000"), "Main-account mode still supported");
    }

    private static SePayPaymentDAO dao(VnpayPaymentTest.Fixture fixture) {
        return new SePayPaymentDAO() {
            @Override public Connection getConnection() { return fixture.dao.getConnection(); }
        };
    }

    private static void testJsonNotifications() throws Exception {
        Map<String, String> decoded = SePayUtil.parseJson(("{\"id\":9007199254740993,\"code\":null,"
                + "\"content\":\"Thuốc \\\"A\\\" \\u0050FSP901 \\ud83d\\udc8a\",\"test\":true}")
                .getBytes(StandardCharsets.UTF_8));
        check(decoded.get("id").equals("9007199254740993"), "JSON IDs retain all digits without floating point");
        check(decoded.containsKey("code") && decoded.get("code") == null, "JSON null code remains optional");
        check(decoded.get("content").equals("Thuốc \"A\" PFSP901 💊"), "JSON strings decode UTF-8, escapes and surrogate pairs");
        check(SePayUtil.parsePaymentCode(decoded.get("content")) == 901, "Escaped JSON memo uses the same order matching");
        for (String invalid : new String[]{"[]", "{}{}", "{\"id\":01}", "{\"id\":+1}",
                "{\"id\":1,}", "{\"id\":}", "{\"code\":null,\"code\":\"PFSP901\"}",
                "{\"id\":1,\"\\u0069d\":2}", "{\"x\":{}}", "{\"x\":[]}",
                "{\"x\":\"\\x20\"}", "{\"x\":\"\\ud800\"}", "{\"x\":\"\\udc00\"}",
                "{\"x\":\"line\nfeed\"}", "{\"x\":\"\\uZZZZ\"}", "{\"x\":\"unfinished}"}) {
            boolean refused = false;
            try { SePayUtil.parseJson(invalid.getBytes(StandardCharsets.UTF_8)); }
            catch (IllegalArgumentException expected) { refused = true; }
            check(refused, "Malformed, nested or duplicate JSON must be rejected");
        }
        boolean refusedUtf8 = false;
        try { SePayUtil.parseJson(new byte[]{'{', '"', 'x', '"', ':', '"', (byte) 0xc3, '(', '"', '}'}); }
        catch (IllegalArgumentException expected) { refusedUtf8 = true; }
        check(refusedUtf8, "Malformed UTF-8 JSON rejected");
        boolean refusedSize = false;
        try { SePayUtil.parseJson(("{\"x\":\"" + "x".repeat(16384) + "\"}").getBytes(StandardCharsets.UTF_8)); }
        catch (IllegalArgumentException expected) { refusedSize = true; }
        check(refusedSize, "JSON decoder is bounded to 16 KiB");

        try (VnpayPaymentTest.Fixture fixture = new VnpayPaymentTest.Fixture()) {
            fixture.execute("UPDATE online_payments SET provider = 'SEPAY'");
            SePayPaymentDAO dao = dao(fixture);
            String body = "{\"id\":5001,\"gateway\":\"MBBank\",\"accountNumber\":\"0000000000\","
                    + "\"transferType\":\"in\",\"transferAmount\":100000,\"code\":null,\"content\":\"PFSP901\"}";
            String mediaType = "application/json; charset=UTF-8";
            check(call(dao, "{\"test\":true,\"message\":\"Connectivity check\"}", null, null, mediaType).status == 200,
                    "Signed connection test without payment code is acknowledged");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("CHO_THANH_TOAN"),
                    "Connection test never completes a real payment");
            check(call(dao, body, "sha256=" + "0".repeat(64), null, mediaType).status == 401, "JSON still requires authentic raw-body HMAC");
            check(call(dao, body, null, null, "text/plain").status == 415, "Unsupported media still rejected");
            check(call(dao, body.replace("100000", "1e5"), null, null, mediaType).status == 400, "Exponent amount cannot bypass amount validation");
            check(call(dao, body.replace("0000000000", "9999999999"), null, null, mediaType).status == 403,
                    "JSON payment still requires the receiving account");
            check(call(dao, body.replace("\"code\":null", "\"code\":null,\"code\":\"PFSP901\""), null, null, mediaType).status == 400,
                    "Repeated null JSON fields are rejected after signature verification");
            System.setProperty("sepay.vaAccount", "VATEST0000001");
            try {
                check(call(dao, body, null, null, mediaType).status == 403, "JSON bank payment still requires the configured VA");
                body = body.replace("\"code\":null", "\"subAccount\":\"VATEST0000001\",\"code\":null");
                check(call(dao, body, null, null, mediaType).status == 200, "Signed JSON payment with matching VA accepted");
                check(fixture.scalar("SELECT payment_status FROM online_orders").equals("DA_THANH_TOAN"), "JSON receipt completes the matching payment");
                check(fixture.scalar("SELECT order_status FROM online_orders").equals("DA_XAC_NHAN"), "JSON receipt confirms matching order");
                check(fixture.scalar("SELECT transaction_reference FROM online_payments").equals("SEPAY:5001"), "JSON receipt identity stored");
                check(call(dao, body, null, null, mediaType).status == 200, "JSON receipt retry remains idempotent");
                check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("3"), "JSON payment preserves reserved stock");
                check(fixture.scalar("SELECT on_hand_quantity FROM inventory_batches").equals("10"), "JSON payment preserves physical stock");
            } finally { System.clearProperty("sepay.vaAccount"); }
        }
    }

    private static String payload(String amount, String direction, String memo, String eventId) {
        Map<String, String> values = new LinkedHashMap<>();
        values.put("id", eventId);
        values.put("gateway", "MBBank");
        values.put("accountNumber", "0000000000");
        values.put("transferType", direction);
        values.put("transferAmount", amount);
        values.put("content", memo);
        StringBuilder body = new StringBuilder();
        for (Map.Entry<String, String> entry : values.entrySet()) {
            if (body.length() > 0) body.append('&');
            body.append(entry.getKey()).append('=').append(URLEncoder.encode(entry.getValue(),StandardCharsets.UTF_8));
        }
        return body.toString();
    }

    private static Reply call(SePayPaymentDAO dao, String body, String signature, String timestamp) throws Exception {
        return call(dao, body, signature, timestamp, "application/x-www-form-urlencoded; charset=UTF-8");
    }

    private static Reply call(SePayPaymentDAO dao, String body, String signature, String timestamp, String contentType) throws Exception {
        if (timestamp == null) timestamp = Long.toString(Instant.now().getEpochSecond());
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        if (signature == null) {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            signature = "sha256=" + java.util.HexFormat.of().formatHex(mac.doFinal((timestamp + "." + body).getBytes(StandardCharsets.UTF_8)));
        }
        final String sentTime = timestamp;
        final String sentSignature = signature;
        HttpServletRequest req = (HttpServletRequest) Proxy.newProxyInstance(SePayPaymentTest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class}, (proxy, method, args) -> {
                    if (method.getName().equals("getContentType")) return contentType;
                    if (method.getName().equals("getHeader")) {
                        if (args[0].equals("X-SePay-Timestamp")) return sentTime;
                        if (args[0].equals("X-SePay-Signature")) return sentSignature;
                    }
                    if (method.getName().equals("getInputStream")) {
                        ByteArrayInputStream input = new ByteArrayInputStream(bytes);
                        return new ServletInputStream() {
                            @Override public int read() { return input.read(); }
                            @Override public boolean isFinished() { return input.available() == 0; }
                            @Override public boolean isReady() { return true; }
                            @Override public void setReadListener(ReadListener listener) { throw new UnsupportedOperationException(); }
                        };
                    }
                    return null;
                });
        Reply reply = new Reply();
        new Hook(dao).invoke(req, reply.response());
        return reply;
    }

    private static final class Hook extends SePayWebhookServlet {
        private final SePayPaymentDAO dao;
        Hook(SePayPaymentDAO dao) { this.dao = dao; }
        @Override protected SePayPaymentDAO paymentDao() { return dao; }
        void invoke(HttpServletRequest req, HttpServletResponse resp) throws Exception { super.doPost(req,resp); }
    }

    private static final class Reply {
        int status = 200;
        String redirect;
        final StringWriter body = new StringWriter();
        HttpServletResponse response() {
            return (HttpServletResponse) Proxy.newProxyInstance(SePayPaymentTest.class.getClassLoader(),
                    new Class<?>[]{HttpServletResponse.class}, (proxy, method, args) -> {
                        if (method.getName().equals("setStatus")) status = (Integer) args[0];
                        if (method.getName().equals("sendRedirect")) redirect = (String) args[0];
                        if (method.getName().equals("getWriter")) return new PrintWriter(body);
                        return null;
                    });
        }
    }

    private static void check(boolean value, String description) {
        checks++;
        if (!value) throw new AssertionError(description);
    }
}
