package flows;

import dao.DeliveryDAO;
import dao.GoodsReceiptDAO;
import dao.LocationDAO;
import dao.OnlineFulfillmentDAO;
import dao.OnlineOrderDAO;
import dao.ProductDAO;
import db.DBContext;
import model.OnlineOrder;
import model.Product;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;

/**
 * Regression for the customer/staff/shipper flows touched in this change,
 * plus catalog and invoice checks. Synthetic rows are named FLOWTEST and
 * removed at the end, including when a check fails.
 */
public final class FlowRegression {

    private static final long CUSTOMER_ID = 1L;
    private static final long CUSTOMER_USER_ID = 1L;
    private static final long STAFF_USER_ID = 8L;
    private static final long BATCH_ID = 1L;
    private static final long BIN_ID = 1L;
    private static int failed;

    public static void main(String[] args) throws Exception {
        try {
            listsAndCatalog();
            invoices();
            immediateCancel();
            onlinePaymentCannotCancel();
            inTransitCancelThenRecover();
            wrongCustomerAndBadStatus();
            inspectWithoutReservation();
            releaseHeldStock();
            restockShippedGoods();
            problemDoesNotRestock();
            staffStillListsRealOrders();
        } finally {
            cleanup();
        }
        if (failed > 0) {
            System.out.println("FAILED " + failed);
            System.exit(1);
        }
        System.out.println("ALL PASSED");
    }

    private static void listsAndCatalog() {
        OnlineOrderDAO orders = new OnlineOrderDAO();
        int total = orders.countOrders(CUSTOMER_ID);
        check("customer count > 0", total > 0);
        List<OnlineOrder> page = orders.findOrders(CUSTOMER_ID, 0, 50);
        check("customer page size", page.size() == Math.min(total, 50));
        boolean own = true;
        for (OnlineOrder order : page) {
            if (order.getCustomerId() == null || order.getCustomerId() != CUSTOMER_ID) {
                own = false;
            }
            if (order.getStatusLabel() == null || order.getStatusLabel().isEmpty()) {
                own = false;
            }
        }
        check("customer rows owned and labeled", own && !page.isEmpty());

        OnlineFulfillmentDAO staff = new OnlineFulfillmentDAO();
        int staffTotal = staff.countOrders("", "");
        List<OnlineOrder> staffPage = staff.findOrders("", "", 0, 50);
        check("staff list not empty", staffTotal > 0 && !staffPage.isEmpty());
        check("staff page matches count", staffPage.size() == Math.min(staffTotal, 50));
        List<OnlineOrder> waiting = staff.findOrders("CHO_XU_LY", "", 0, 50);
        boolean onlyWaiting = true;
        for (OnlineOrder order : waiting) {
            if (!"CHO_XU_LY".equals(order.getOrderStatus())) {
                onlyWaiting = false;
            }
        }
        check("staff status filter", staff.countOrders("NO_SUCH", "") == 0 && onlyWaiting);

        DeliveryDAO delivery = new DeliveryDAO();
        List<OnlineOrder> queue = delivery.findDeliveryOrders("", "", 0, 50);
        boolean deliveryStates = true;
        for (OnlineOrder order : queue) {
            String status = order.getOrderStatus();
            if (!"SAN_SANG".equals(status) && !"DANG_GIAO".equals(status)
                    && !"HOAN_TAT".equals(status) && !"YEU_CAU_HUY".equals(status)) {
                deliveryStates = false;
            }
        }
        check("shipper queue statuses", deliveryStates);
        check("shipper filter outside the queue is empty",
                delivery.countDeliveryOrders("CHO_XU_LY", "") == 0);

        ProductDAO products = new ProductDAO();
        int catalog = products.countCatalog("", null, null, null, false);
        List<Product> cards = products.findCatalog("", null, null, null, false, 12, 0);
        check("catalog loads", catalog > 0 && !cards.isEmpty());
        Product one = products.findStorefrontById(cards.get(0).getProductId());
        check("product detail", one != null && one.getProductName() != null);
        List<Product> search = products.findAll("a", null, null, null, 5, 0);
        check("admin product search without barcode", search != null);
    }

    private static void invoices() throws Exception {
        GoodsReceiptDAO receipts = new GoodsReceiptDAO();
        check("known invoice", receipts.existsInvoiceNumber("123", 0));
        check("invoice trim and case", receipts.existsInvoiceNumber("  123  ", 0));
        check("own invoice excluded", !receipts.existsInvoiceNumber("123", 1));
        check("unknown invoice", !receipts.existsInvoiceNumber("NO-SUCH-INVOICE-ZZ", 0));

        long id = insertReceipt("ZZ-CANCELLED-INV", "DA_HUY");
        check("cancelled invoice is free", !receipts.existsInvoiceNumber("ZZ-CANCELLED-INV", 0));
        exec("UPDATE goods_receipts SET status='BAN_NHAP' WHERE goods_receipt_id=" + id);
        check("draft invoice blocks duplicate", receipts.existsInvoiceNumber("zz-cancelled-inv", 0));
        check("editing same receipt is allowed", !receipts.existsInvoiceNumber("ZZ-CANCELLED-INV", id));
        exec("DELETE FROM goods_receipts WHERE goods_receipt_id=" + id);
    }

    private static void immediateCancel() throws Exception {
        long id = insertOrder("CHO_XU_LY", "THANH_TOAN_KHI_NHAN_HANG");
        OnlineOrderDAO.OrderResult result = new OnlineOrderDAO().cancelOrder(CUSTOMER_USER_ID, CUSTOMER_ID, id);
        check("COD waiting cancel", result.ok && "DA_HUY".equals(statusOf(id)));
    }

    private static void onlinePaymentCannotCancel() throws Exception {
        long id = insertOrder("CHO_XU_LY", "THANH_TOAN_TRUC_TUYEN");
        OnlineOrderDAO.OrderResult result = new OnlineOrderDAO().cancelOrder(CUSTOMER_USER_ID, CUSTOMER_ID, id);
        check("online payment not cancellable",
                !result.ok && "ONLINE_PAYMENT_NOT_CANCELLABLE".equals(result.error)
                        && "CHO_XU_LY".equals(statusOf(id)));
    }

    private static void inTransitCancelThenRecover() throws Exception {
        long id = insertOrder("SAN_SANG", "THANH_TOAN_KHI_NHAN_HANG");
        OnlineOrderDAO.OrderResult requested = new OnlineOrderDAO().requestInTransitCancel(CUSTOMER_ID, id);
        check("ready order becomes cancel request", requested.ok && "YEU_CAU_HUY".equals(statusOf(id)));
        OnlineOrderDAO.OrderResult again = new OnlineOrderDAO().requestInTransitCancel(CUSTOMER_ID, id);
        check("second cancel request rejected", !again.ok && "NOT_CANCELLABLE".equals(again.error));
        DeliveryDAO.DeliveryResult recovered = new DeliveryDAO().recoverCancellation(id);
        check("shipper recovers cancel", recovered.ok && "CHO_KIEM_HUY".equals(statusOf(id)));
        DeliveryDAO.DeliveryResult twice = new DeliveryDAO().recoverCancellation(id);
        check("second recover rejected", !twice.ok && "INVALID_STATUS".equals(twice.error));
        check("recovered order leaves shipper cancel queue",
                !containsOrder(new DeliveryDAO().findDeliveryOrders("YEU_CAU_HUY", "", 0, 50), id));
        check("staff sees inspection order",
                containsOrder(new OnlineFulfillmentDAO().findOrders("CHO_KIEM_HUY", "", 0, 50), id));
    }

    private static void wrongCustomerAndBadStatus() throws Exception {
        long id = insertOrder("DANG_GIAO", "THANH_TOAN_KHI_NHAN_HANG");
        OnlineOrderDAO.OrderResult other = new OnlineOrderDAO().requestInTransitCancel(99999L, id);
        check("other customer cannot cancel", !other.ok && "ORDER_NOT_FOUND".equals(other.error));
        OnlineOrderDAO.OrderResult waiting = new OnlineOrderDAO().requestInTransitCancel(CUSTOMER_ID,
                insertOrder("CHO_XU_LY", "THANH_TOAN_KHI_NHAN_HANG"));
        check("waiting order is not an in-transit cancel", !waiting.ok);
        DeliveryDAO.DeliveryResult early = new DeliveryDAO().recoverCancellation(id);
        check("recover before request fails", !early.ok && "INVALID_STATUS".equals(early.error)
                && "DANG_GIAO".equals(statusOf(id)));
    }

    private static void inspectWithoutReservation() throws Exception {
        long id = insertOrder("CHO_KIEM_HUY", "THANH_TOAN_KHI_NHAN_HANG");
        OnlineFulfillmentDAO staff = new OnlineFulfillmentDAO();
        OnlineFulfillmentDAO.FulfillmentResult missing = staff.acceptCancelInspection(id, STAFF_USER_ID);
        check("inspect without reservation fails",
                !missing.ok && "RESERVATION_NOT_FOUND".equals(missing.error)
                        && "CHO_KIEM_HUY".equals(statusOf(id)));
        OnlineFulfillmentDAO.FulfillmentResult blank = staff.rejectCancelInspection(id, "  ");
        check("empty problem reason rejected", !blank.ok && "REASON_REQUIRED".equals(blank.error));
        OnlineFulfillmentDAO.FulfillmentResult problem = staff.rejectCancelInspection(id, "Vỡ hộp");
        check("problem status saved", problem.ok && "HUY_CO_VAN_DE".equals(statusOf(id))
                && "Vỡ hộp".equals(reasonOf(id)));
    }

    private static void releaseHeldStock() throws Exception {
        int[] before = stock();
        reserveOne();
        long id = insertOrder("CHO_KIEM_HUY", "THANH_TOAN_KHI_NHAN_HANG");
        long itemId = insertItem(id, 1);
        insertReservation(id, itemId, "DANG_GIU");
        OnlineFulfillmentDAO.FulfillmentResult result =
                new OnlineFulfillmentDAO().acceptCancelInspection(id, STAFF_USER_ID);
        int[] after = stock();
        check("held stock released", result.ok && "DA_HUY".equals(statusOf(id))
                && "DA_GIAI_PHONG".equals(reservationStatus(id))
                && after[0] == before[0] && after[1] == before[1]);
    }

    private static void restockShippedGoods() throws Exception {
        int[] before = stock();
        adjustOnHand(-1);
        long id = insertOrder("CHO_KIEM_HUY", "THANH_TOAN_KHI_NHAN_HANG");
        long itemId = insertItem(id, 1);
        insertReservation(id, itemId, "DA_HOAN_TAT");
        OnlineFulfillmentDAO.FulfillmentResult result =
                new OnlineFulfillmentDAO().acceptCancelInspection(id, STAFF_USER_ID);
        int[] after = stock();
        check("shipped goods return to stock", result.ok && "DA_HUY".equals(statusOf(id))
                && after[0] == before[0]);
        check("restock movement written", countMovements(id, "HOAN_HANG") == 1);
    }

    private static void problemDoesNotRestock() throws Exception {
        int[] before = stock();
        adjustOnHand(-1);
        long id = insertOrder("CHO_KIEM_HUY", "THANH_TOAN_KHI_NHAN_HANG");
        long itemId = insertItem(id, 1);
        insertReservation(id, itemId, "DA_HOAN_TAT");
        OnlineFulfillmentDAO.FulfillmentResult result =
                new OnlineFulfillmentDAO().rejectCancelInspection(id, "Hàng móp");
        int[] after = stock();
        check("problem keeps stock out", result.ok && "HUY_CO_VAN_DE".equals(statusOf(id))
                && after[0] == before[0] - 1);
        adjustOnHand(1);
        int[] restored = stock();
        check("problem test stock restored", restored[0] == before[0] && restored[1] == before[1]);
    }

    private static void staffStillListsRealOrders() {
        OnlineFulfillmentDAO staff = new OnlineFulfillmentDAO();
        int total = staff.countOrders("", "");
        List<OnlineOrder> page = staff.findOrders("", "", 0, 20);
        check("staff list still readable", total >= page.size() && !page.isEmpty());
        check("customer history still readable", new OnlineOrderDAO().countOrders(CUSTOMER_ID) > 0);
    }

    private static void cleanup() throws Exception {
        try (Connection connection = new DBContext().getConnection();
                Statement sql = connection.createStatement()) {
            ResultSet ids = sql.executeQuery(
                    "SELECT online_order_id FROM online_orders WHERE customer_name='FLOWTEST'");
            StringBuilder in = new StringBuilder();
            while (ids.next()) {
                if (in.length() > 0) {
                    in.append(',');
                }
                in.append(ids.getLong(1));
            }
            ids.close();
            if (in.length() > 0) {
                sql.execute("DELETE FROM inventory_movements WHERE reference_type='DON_HANG_ONLINE' "
                        + "AND reference_id IN (" + in + ")");
                sql.execute("DELETE FROM inventory_reservations WHERE online_order_id IN (" + in + ")");
                sql.execute("DELETE FROM online_order_items WHERE online_order_id IN (" + in + ")");
                sql.execute("DELETE FROM online_orders WHERE online_order_id IN (" + in + ")");
            }
            sql.execute("DELETE FROM goods_receipts WHERE invoice_number='ZZ-CANCELLED-INV'");
        }
    }

    private static long insertOrder(String status, String payment) throws Exception {
        String sql = "INSERT INTO online_orders (customer_id, customer_name, customer_phone, "
                + "province_city, district, ward, detailed_address, payment_method, payment_status, "
                + "total_amount, order_status) VALUES (?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection connection = new DBContext().getConnection();
                PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, CUSTOMER_ID);
            ps.setString(2, "FLOWTEST");
            ps.setString(3, "0900000000");
            ps.setString(4, "HCM");
            ps.setString(5, "1");
            ps.setString(6, "1");
            ps.setString(7, "test");
            ps.setString(8, payment);
            ps.setString(9, "THANH_TOAN_KHI_NHAN_HANG".equals(payment) ? "KHONG_YEU_CAU" : "DA_THANH_TOAN");
            ps.setBigDecimal(10, new BigDecimal("10000"));
            ps.setString(11, status);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getLong(1);
            }
        }
    }

    private static long insertItem(long orderId, int quantity) throws Exception {
        String sql = "INSERT INTO online_order_items (online_order_id, product_id, quantity, "
                + "selling_unit, unit_price, subtotal) VALUES (?,1,?,?,?,?)";
        try (Connection connection = new DBContext().getConnection();
                PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, orderId);
            ps.setInt(2, quantity);
            ps.setString(3, "Hộp");
            ps.setBigDecimal(4, new BigDecimal("10000"));
            ps.setBigDecimal(5, new BigDecimal("10000").multiply(BigDecimal.valueOf(quantity)));
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getLong(1);
            }
        }
    }

    private static void insertReservation(long orderId, long itemId, String status) throws Exception {
        String sql = "INSERT INTO inventory_reservations (online_order_id, online_order_item_id, "
                + "batch_id, bin_id, reserved_quantity, status) VALUES (?,?,?,?,1,?)";
        try (Connection connection = new DBContext().getConnection();
                PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            ps.setLong(2, itemId);
            ps.setLong(3, BATCH_ID);
            ps.setLong(4, BIN_ID);
            ps.setString(5, status);
            ps.executeUpdate();
        }
    }

    private static long insertReceipt(String invoice, String status) throws Exception {
        String sql = "INSERT INTO goods_receipts (supplier_id, purchase_order_id, received_by, "
                + "receipt_date, invoice_number, status) VALUES (3,1,2,CURDATE(),?,?)";
        try (Connection connection = new DBContext().getConnection();
                PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, invoice);
            ps.setString(2, status);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getLong(1);
            }
        }
    }

    private static void reserveOne() throws Exception {
        try (Connection connection = new DBContext().getConnection()) {
            connection.setAutoCommit(false);
            new LocationDAO().increaseReservedAtBin(connection, BATCH_ID, BIN_ID, 1);
            connection.commit();
        }
    }

    private static void adjustOnHand(int delta) throws Exception {
        try (Connection connection = new DBContext().getConnection();
                Statement sql = connection.createStatement()) {
            if (delta < 0) {
                sql.execute("UPDATE inventory_batch_locations SET on_hand_quantity = on_hand_quantity - 1 "
                        + "WHERE batch_id=1 AND bin_id=1 AND on_hand_quantity - reserved_quantity >= 1");
            } else {
                sql.execute("UPDATE inventory_batch_locations SET on_hand_quantity = on_hand_quantity + 1 "
                        + "WHERE batch_id=1 AND bin_id=1");
            }
            sql.execute("UPDATE inventory_batches b SET on_hand_quantity = "
                    + "(SELECT COALESCE(SUM(on_hand_quantity),0) FROM inventory_batch_locations l "
                    + "WHERE l.batch_id=b.batch_id) WHERE b.batch_id=1");
        }
    }

    /** [onHand, reserved] of batch 1. */
    private static int[] stock() throws Exception {
        try (Connection connection = new DBContext().getConnection();
                Statement sql = connection.createStatement();
                ResultSet rs = sql.executeQuery(
                        "SELECT on_hand_quantity, reserved_quantity FROM inventory_batches WHERE batch_id=1")) {
            rs.next();
            return new int[]{rs.getInt(1), rs.getInt(2)};
        }
    }

    private static String statusOf(long orderId) throws Exception {
        return scalar("SELECT order_status FROM online_orders WHERE online_order_id=" + orderId);
    }

    private static String reasonOf(long orderId) throws Exception {
        return scalar("SELECT return_reason FROM online_orders WHERE online_order_id=" + orderId);
    }

    private static String reservationStatus(long orderId) throws Exception {
        return scalar("SELECT status FROM inventory_reservations WHERE online_order_id=" + orderId);
    }

    private static int countMovements(long orderId, String type) throws Exception {
        try (Connection connection = new DBContext().getConnection();
                PreparedStatement ps = connection.prepareStatement(
                        "SELECT COUNT(*) FROM inventory_movements WHERE reference_type='DON_HANG_ONLINE' "
                                + "AND reference_id=? AND movement_type=?")) {
            ps.setLong(1, orderId);
            ps.setString(2, type);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private static String scalar(String sql) throws Exception {
        try (Connection connection = new DBContext().getConnection();
                Statement statement = connection.createStatement();
                ResultSet rs = statement.executeQuery(sql)) {
            return rs.next() ? rs.getString(1) : null;
        }
    }

    private static void exec(String sql) throws Exception {
        try (Connection connection = new DBContext().getConnection();
                Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }
    }

    private static boolean containsOrder(List<OnlineOrder> orders, long id) {
        for (OnlineOrder order : orders) {
            if (order.getOnlineOrderId() != null && order.getOnlineOrderId() == id) {
                return true;
            }
        }
        return false;
    }

    private static void check(String name, boolean ok) {
        System.out.println((ok ? "PASS " : "FAIL ") + name);
        if (!ok) {
            failed++;
        }
    }
}
