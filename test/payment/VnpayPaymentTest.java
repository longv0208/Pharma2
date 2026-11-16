package payment;

import controller.VnpayIpnServlet;
import controller.VnpayPaymentServlet;
import dao.VnpayPaymentDAO;
import db.DBContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.net.URI;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import util.VnpayConfig;
import util.VnpayUtil;

/** Standalone tests; --database uses connection-local TEMPORARY tables only. */
public final class VnpayPaymentTest {
    private static final String SECRET = "test-only-not-a-merchant-secret";
    private static int checks;

    public static void main(String[] args) throws Exception {
        if (System.getenv("VNPAY_TMN_CODE") != null || System.getenv("VNPAY_HASH_SECRET") != null) {
            throw new IllegalStateException("Run tests without real merchant environment credentials");
        }
        check(!VnpayConfig.isConfigured(), "Missing credentials must disable checkout");
        System.setProperty("vnpay.tmnCode", "TESTCODE");
        System.setProperty("vnpay.hashSecret", SECRET);
        System.setProperty("vnpay.bankCode", "VNPAYQR");
        System.setProperty("vnpay.environment", "production");
        check(!VnpayConfig.isConfigured(), "Production requires a fixed public return URL");
        System.setProperty("vnpay.returnUrl", "http://merchant.example/Pharma_Flow/payment/vnpay/return");
        check(!VnpayConfig.isConfigured(), "Production rejects HTTP return URL");
        System.setProperty("vnpay.returnUrl", "https://merchant.example/Pharma_Flow/payment/vnpay/return");
        check(VnpayConfig.isConfigured(), "HTTPS production configuration");
        check(VnpayConfig.paymentUrl().equals("https://pay.vnpay.vn/vpcpay.html"), "Production gateway");
        System.setProperty("vnpay.environment", "sandbox");

        String url = VnpayUtil.buildPaymentUrl(901, new BigDecimal("100000.00"),
                VnpayConfig.returnUrl(), "127.0.0.1");
        Map<String, String> outgoing = query(url);
        check(outgoing.get("vnp_Amount").equals("10000000"), "VND amount multiplied by 100");
        check(outgoing.get("vnp_TxnRef").equals("PF901"), "Order reference");
        check(outgoing.get("vnp_BankCode").equals("VNPAYQR"), "Merchant QR payment option");
        check(sign(outgoing).equals(outgoing.get("vnp_SecureHash")), "Independent HMAC verifies payment URL");
        Map<String, String> signed = callback("00", "00", "10000000", "123456");
        check(VnpayUtil.verifyReturnSignature(signed), "Valid callback signature");
        signed.put("vnp_SecureHash", signed.get("vnp_SecureHash").toUpperCase(Locale.ROOT));
        check(VnpayUtil.verifyReturnSignature(signed), "Uppercase hexadecimal signature");
        signed.put("vnp_Amount", "1");
        check(!VnpayUtil.verifyReturnSignature(signed), "Amount tampering rejected");
        check(VnpayUtil.parseTxnRef("PF+901") < 0 && VnpayUtil.parseTxnRef("PF0901") < 0,
                "Ambiguous order references rejected");
        check(VnpayUtil.parseTxnRef("PF9999999999999999999") < 0, "Overflowing order reference rejected");
        Map<String, String[]> ambiguousNames = parameters(callback("00", "00", "10000000", "123456"));
        ambiguousNames.put("vnp_Fake&vnp_Amount", new String[]{"1"});
        check(VnpayUtil.callbackParameters(ambiguousNames) == null, "Invalid parameter names rejected");

        if (args.length > 0 && "--database".equals(args[0])) {
            testSuccessAndBrowserReturn();
            testFailureAndRelease();
            testInvalidNotifications();
            testDatabaseGuards();
        }
        System.out.println("PASS " + checks + " checks; no real bank payment was initiated");
    }

    private static void testSuccessAndBrowserReturn() throws Exception {
        try (Fixture fixture = new Fixture()) {
            Map<String, String> success = callback("00", "00", "10000000", "123456");
            Reply browser = returned(fixture, success);
            check(browser.redirect.endsWith("&payment=pending"), "Browser return waits for IPN");
            check(fixture.scalar("SELECT payment_status FROM online_payments").equals("CHO_XU_LY"),
                    "Browser return cannot mark payment successful");
            Reply ipn = notified(fixture, success);
            check(ipn.body.toString().contains("\"RspCode\":\"00\""), "IPN accepted");
            check(fixture.scalar("SELECT payment_status FROM online_payments").equals("THANH_CONG"), "Payment succeeds");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("DA_THANH_TOAN"), "Order paid");
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("CHO_XU_LY"), "Delivery not auto-completed");
            check(fixture.scalar("SELECT transaction_reference FROM online_payments").equals("123456"), "Provider reference stored");
            check(fixture.scalar("SELECT paid_at IS NOT NULL FROM online_payments").equals("1"), "Payment timestamp stored");
            check(fixture.scalar("SELECT on_hand_quantity FROM inventory_batches").equals("10"), "On-hand stock preserved");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("3"), "Reservation preserved");
            check(fixture.scalar("SELECT status FROM inventory_reservations").equals("DANG_GIU"), "Stock remains held for delivery");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("0"), "No stock movement on success");
            check(notified(fixture, success).body.toString().contains("\"RspCode\":\"02\""), "Repeated success is idempotent");
            check(returned(fixture, success).redirect.endsWith("&ok=paid"), "Browser shows persisted success");
            check(notified(fixture, callback("00", "00", "10000000", "654321")).body.toString()
                    .contains("\"RspCode\":\"99\""), "Conflicting transaction reference rejected");
            notified(fixture, callback("24", "02", "10000000", "0"));
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("DA_THANH_TOAN"),
                    "Later failure cannot undo captured payment");
        }
    }

    private static void testFailureAndRelease() throws Exception {
        try (Fixture fixture = new Fixture()) {
            Map<String, String> failure = callback("24", "02", "10000000", "0");
            check(notified(fixture, failure).body.toString().contains("\"RspCode\":\"00\""), "Cancellation IPN accepted");
            check(fixture.scalar("SELECT payment_status FROM online_payments").equals("THAT_BAI"), "Failure recorded");
            check(fixture.scalar("SELECT order_status FROM online_orders").equals("DA_HUY"), "Failed order cancelled");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("0"), "Held stock released");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batch_locations").equals("0"),
                    "Held stock released at the reserved bin");
            check(fixture.scalar("SELECT on_hand_quantity FROM inventory_batches").equals("10"), "Failure never reduces on-hand");
            check(fixture.scalar("SELECT status FROM inventory_reservations").equals("DA_GIAI_PHONG"), "Reservation released");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("1"), "One release audit movement");
            check(notified(fixture, failure).body.toString().contains("\"RspCode\":\"02\""), "Repeated failure acknowledged");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("1"), "Repeated IPN cannot release twice");
            check(returned(fixture, failure).redirect.endsWith("&err=payment_failed"), "Browser shows persisted failure");
            notified(fixture, callback("00", "00", "10000000", "123456"));
            check(fixture.scalar("SELECT payment_status FROM online_payments").equals("THAT_BAI"),
                    "Released order cannot become paid from a late callback");
        }
    }

    private static void testInvalidNotifications() throws Exception {
        try (Fixture fixture = new Fixture()) {
            Map<String, String> bad = callback("00", "00", "10000000", "123456");
            bad.put("vnp_Amount", "1");
            check(notified(fixture, bad).body.toString().contains("\"RspCode\":\"97\""), "Bad signature IPN rejected");
            check(notified(fixture, callback("00", "00", "1", "123456")).body.toString()
                    .contains("\"RspCode\":\"04\""), "Signed wrong amount rejected");
            bad = callback("00", "00", "10000000", "123456");
            bad.put("vnp_TmnCode", "OTHERONE");
            bad.put("vnp_SecureHash", sign(bad));
            check(notified(fixture, bad).body.toString().contains("\"RspCode\":\"97\""), "Different merchant rejected");
            bad = callback("00", "00", "10000000", "123456");
            bad.remove("vnp_TransactionStatus");
            bad.put("vnp_SecureHash", sign(bad));
            check(notified(fixture, bad).body.toString().contains("\"RspCode\":\"99\""), "Incomplete signed callback rejected");
            for (String state : new String[]{"01", "04", "05", "06", "07", "09"}) {
                check(notified(fixture, callback("07", state, "10000000", "123456")).body.toString()
                        .contains("\"RspCode\":\"99\""), "Unsettled transfer not accepted or cancelled: " + state);
            }
            Map<String, String[]> repeated = parameters(callback("00", "00", "10000000", "123456"));
            repeated.put("vnp_Amount", new String[]{"10000000", "1"});
            Reply duplicate = new Reply();
            new Ipn(fixture.dao).invoke(request(repeated), duplicate.response());
            check(duplicate.body.toString().contains("\"RspCode\":\"97\""), "Repeated parameters rejected");
            bad = callback("00", "00", "10000000", "123456");
            bad.put("vnp_TxnRef", "PF902");
            bad.put("vnp_SecureHash", sign(bad));
            check(notified(fixture, bad).body.toString().contains("\"RspCode\":\"01\""), "Missing order rejected");
            check(notified(fixture, callback("00", "00", "10000000", "0")).body.toString()
                    .contains("\"RspCode\":\"99\""), "Zero success transaction reference rejected");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("CHO_THANH_TOAN"), "Invalid callbacks never pay order");
            check(fixture.scalar("SELECT reserved_quantity FROM inventory_batches").equals("3"), "Invalid callbacks preserve stock");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("0"), "Invalid callbacks leave no stock writes");
        }
    }

    private static void testDatabaseGuards() throws Exception {
        try (Fixture fixture = new Fixture()) {
            fixture.execute("UPDATE online_orders SET payment_method = 'THANH_TOAN_KHI_NHAN_HANG'");
            check(fixture.dao.processSuccess(901, 10000000, "123456").code.equals("INVALID_PAYMENT_STATE"), "COD cannot be paid by IPN");
        }
        try (Fixture fixture = new Fixture()) {
            fixture.execute("UPDATE online_payments SET provider = 'OTHER'");
            check(fixture.dao.processSuccess(901, 10000000, "123456").code.equals("INVALID_PAYMENT_STATE"), "Wrong provider rejected");
        }
        try (Fixture fixture = new Fixture()) {
            fixture.execute("UPDATE inventory_batches SET reserved_quantity = 2");
            check(fixture.dao.processFailure(901, 10000000, "0").code.equals("DB_ERROR"), "Inconsistent reservation rolls back");
            check(fixture.scalar("SELECT payment_status FROM online_orders").equals("CHO_THANH_TOAN"), "Rollback preserves order");
            check(fixture.scalar("SELECT COUNT(*) FROM inventory_movements").equals("0"), "Rollback preserves audit count");
        }
    }

    private static Map<String, String> callback(String response, String state, String amount, String reference) throws Exception {
        Map<String, String> values = new LinkedHashMap<>();
        values.put("vnp_TmnCode", "TESTCODE");
        values.put("vnp_TxnRef", "PF901");
        values.put("vnp_Amount", amount);
        values.put("vnp_TransactionNo", reference);
        values.put("vnp_ResponseCode", response);
        values.put("vnp_TransactionStatus", state);
        values.put("vnp_OrderInfo", "Thanh toan PF901");
        values.put("vnp_BankCode", "NCB");
        values.put("vnp_SecureHash", sign(values));
        return values;
    }

    private static String sign(Map<String, String> values) throws Exception {
        StringBuilder data = new StringBuilder();
        for (Map.Entry<String, String> entry : new TreeMap<>(values).entrySet()) {
            if (!entry.getKey().startsWith("vnp_") || entry.getKey().equals("vnp_SecureHash")
                    || entry.getKey().equals("vnp_SecureHashType") || entry.getValue().isEmpty()) continue;
            if (data.length() > 0) data.append('&');
            data.append(entry.getKey()).append('=').append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
        }
        Mac mac = Mac.getInstance("HmacSHA512");
        mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
        return java.util.HexFormat.of().formatHex(mac.doFinal(data.toString().getBytes(StandardCharsets.UTF_8)));
    }

    private static Map<String, String> query(String url) {
        Map<String, String> values = new LinkedHashMap<>();
        for (String pair : URI.create(url).getRawQuery().split("&")) {
            String[] parts = pair.split("=", 2);
            values.put(parts[0], URLDecoder.decode(parts[1], StandardCharsets.US_ASCII));
        }
        return values;
    }

    private static Map<String, String[]> parameters(Map<String, String> values) {
        Map<String, String[]> result = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry : values.entrySet()) result.put(entry.getKey(), new String[]{entry.getValue()});
        return result;
    }

    private static HttpServletRequest request(Map<String, String[]> values) {
        return (HttpServletRequest) Proxy.newProxyInstance(VnpayPaymentTest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class}, (proxy, method, args) -> {
                    if (method.getName().equals("getParameterMap")) return values;
                    if (method.getName().equals("getContextPath")) return "/Pharma_Flow";
                    return null;
                });
    }

    private static Reply notified(Fixture fixture, Map<String, String> values) throws Exception {
        Reply result = new Reply();
        new Ipn(fixture.dao).invoke(request(parameters(values)), result.response());
        return result;
    }

    private static Reply returned(Fixture fixture, Map<String, String> values) throws Exception {
        Reply result = new Reply();
        new BrowserReturn(fixture.dao).invoke(request(parameters(values)), result.response());
        return result;
    }

    private static void check(boolean value, String label) {
        checks++;
        if (!value) throw new AssertionError(label);
    }

    private static final class Reply {
        final StringWriter body = new StringWriter();
        String redirect;
        HttpServletResponse response() {
            return (HttpServletResponse) Proxy.newProxyInstance(VnpayPaymentTest.class.getClassLoader(),
                    new Class<?>[]{HttpServletResponse.class}, (proxy, method, args) -> {
                        if (method.getName().equals("getWriter")) return new PrintWriter(body);
                        if (method.getName().equals("sendRedirect")) redirect = (String) args[0];
                        return null;
                    });
        }
    }

    private static final class Ipn extends VnpayIpnServlet {
        private final VnpayPaymentDAO dao;
        Ipn(VnpayPaymentDAO dao) { this.dao = dao; }
        @Override protected VnpayPaymentDAO paymentDao() { return dao; }
        void invoke(HttpServletRequest req, HttpServletResponse resp) throws Exception { super.doGet(req, resp); }
    }

    private static final class BrowserReturn extends VnpayPaymentServlet {
        private final VnpayPaymentDAO dao;
        BrowserReturn(VnpayPaymentDAO dao) { this.dao = dao; }
        @Override protected VnpayPaymentDAO paymentDao() { return dao; }
        void invoke(HttpServletRequest req, HttpServletResponse resp) throws Exception { super.doGet(req, resp); }
    }

    static final class Fixture implements AutoCloseable {
        final Connection connection;
        final VnpayPaymentDAO dao;
        Fixture() throws Exception {
            connection = new DBContext().getConnection();
            if (connection == null) throw new IllegalStateException("Test database connection unavailable");
            for (String table : new String[]{"online_orders", "online_payments", "inventory_batches",
                    "inventory_reservations", "inventory_movements", "storage_zones",
                    "storage_racks", "storage_bins", "inventory_batch_locations"}) {
                createTemporaryTable(table);
            }
            execute("INSERT INTO online_orders (online_order_id, customer_id, customer_name, customer_phone, "
                    + "province_city, district, ward, detailed_address, payment_method, payment_status, total_amount, order_status) "
                    + "VALUES (901,999,'PAYMENT TEST','0000000000','TEST','TEST','TEST','TEST',"
                    + "'THANH_TOAN_TRUC_TUYEN','CHO_THANH_TOAN',100000,'CHO_XU_LY')");
            execute("INSERT INTO online_payments (payment_id, online_order_id, provider, amount, payment_status) "
                    + "VALUES (901,901,'VNPAY',100000,'CHO_XU_LY')");
            execute("INSERT INTO inventory_batches (batch_id, product_id, batch_number, expiry_date, "
                    + "on_hand_quantity, reserved_quantity) VALUES (901,1,'PAYMENT-TEST','2099-01-01',10,3)");
            execute("INSERT INTO storage_zones (zone_id, zone_code, zone_name) VALUES (901,'PAYMENT','Payment test')");
            execute("INSERT INTO storage_racks (rack_id, zone_id, rack_code, rack_name) "
                    + "VALUES (901,901,'RACK','Payment test')");
            execute("INSERT INTO storage_bins (bin_id, rack_id, bin_code) VALUES (901,901,'BIN')");
            execute("INSERT INTO inventory_batch_locations (batch_id, bin_id, on_hand_quantity, reserved_quantity) "
                    + "VALUES (901,901,10,3)");
            execute("INSERT INTO inventory_reservations (reservation_id, online_order_id, online_order_item_id, "
                    + "batch_id, bin_id, reserved_quantity, status) VALUES (901,901,901,901,901,3,'DANG_GIU')");
            Connection borrowed = (Connection) Proxy.newProxyInstance(VnpayPaymentTest.class.getClassLoader(),
                    new Class<?>[]{Connection.class}, (proxy, method, args) -> {
                        if (method.getName().equals("close")) return null;
                        try { return method.invoke(connection, args); }
                        catch (InvocationTargetException error) { throw error.getCause(); }
                    });
            dao = new VnpayPaymentDAO() {
                @Override public Connection getConnection() { return borrowed; }
            };
        }
        void createTemporaryTable(String table) throws Exception {
            String schema = connection.getCatalog();
            if (!schema.matches("[a-zA-Z0-9_]+") || !table.matches("[a-zA-Z0-9_]+")) {
                throw new IllegalStateException("Unexpected schema identifier");
            }
            String definition;
            try (PreparedStatement statement = connection.prepareStatement("SHOW CREATE TABLE " + schema + "." + table);
                    ResultSet rows = statement.executeQuery()) {
                rows.next();
                definition = rows.getString(2);
            }
            StringBuilder temporaryDefinition = new StringBuilder();
            for (String line : definition.split("\\R")) {
                if (!line.contains("FOREIGN KEY")) temporaryDefinition.append(line).append('\n');
            }
            execute(temporaryDefinition.toString().replace("CREATE TABLE `" + table + "`",
                    "CREATE TEMPORARY TABLE `" + table + "`").replaceAll(",\\s*\\)", "\n)"));
        }
        void execute(String sql) throws Exception {
            try (PreparedStatement statement = connection.prepareStatement(sql)) { statement.executeUpdate(); }
        }
        String scalar(String sql) throws Exception {
            try (PreparedStatement statement = connection.prepareStatement(sql); ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) return null;
                return rows.getString(1);
            }
        }
        @Override public void close() throws Exception { connection.close(); }
    }
}
