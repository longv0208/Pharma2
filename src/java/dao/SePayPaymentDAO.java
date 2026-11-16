package dao;

import db.DBContext;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Records verified incoming transfers without changing physical/reserved stock. */
public class SePayPaymentDAO extends DBContext {
    private static final Logger LOG = Logger.getLogger(SePayPaymentDAO.class.getName());

    /** Same receipt is serialized across all orders, including concurrent retries. */
    public String confirmTransfer(long orderId, String eventId, BigDecimal amount) {
        if (orderId <= 0 || eventId == null || !eventId.matches("[1-9][0-9]{0,18}")
                || amount == null || amount.signum() <= 0) return "INVALID";
        String reference = "SEPAY:" + eventId;
        String lockName = "PharmaFlow:SePay:" + eventId;
        Connection conn = null;
        boolean locked = false;
        try {
            conn = getConnection();
            if (conn == null) return "DB_ERROR";
            try (PreparedStatement ps = conn.prepareStatement("SELECT GET_LOCK(?, 5)")) {
                ps.setString(1, lockName);
                try (ResultSet rs = ps.executeQuery()) {
                    locked = rs.next() && rs.getInt(1) == 1;
                }
            }
            if (!locked) return "DB_ERROR";
            conn.setAutoCommit(false);

            // The named receipt lock prevents the same event paying two orders.
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT online_order_id, amount, payment_status FROM online_payments "
                    + "WHERE provider = 'SEPAY' AND transaction_reference = ?")) {
                ps.setString(1, reference);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        if (rs.getLong(1) == orderId && rs.getBigDecimal(2).compareTo(amount) == 0
                                && "THANH_CONG".equals(rs.getString(3))) {
                            // Reconcile payments captured before automatic confirmation existed.
                            try (PreparedStatement update = conn.prepareStatement(
                                    "UPDATE online_orders SET order_status = 'DA_XAC_NHAN' "
                                    + "WHERE online_order_id = ? AND payment_method = 'THANH_TOAN_TRUC_TUYEN' "
                                    + "AND payment_status = 'DA_THANH_TOAN' AND order_status = 'CHO_XU_LY' "
                                    + "AND total_amount = ?")) {
                                update.setLong(1, orderId);
                                update.setBigDecimal(2, amount);
                                update.executeUpdate();
                            }
                            conn.commit();
                            return "ALREADY_SUCCESS";
                        }
                        return "RECEIPT_ALREADY_USED";
                    }
                }
            }

            BigDecimal total;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT payment_method, payment_status, order_status, total_amount "
                    + "FROM online_orders WHERE online_order_id = ? FOR UPDATE")) {
                ps.setLong(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return "ORDER_NOT_FOUND";
                    if (!"THANH_TOAN_TRUC_TUYEN".equals(rs.getString(1))
                            || !"CHO_THANH_TOAN".equals(rs.getString(2))
                            || !"CHO_XU_LY".equals(rs.getString(3))) return "INVALID_STATE";
                    total = rs.getBigDecimal(4);
                }
            }
            if (total.compareTo(amount) != 0) return "AMOUNT_MISMATCH";

            long paymentId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT payment_id, provider, payment_status, amount FROM online_payments "
                    + "WHERE online_order_id = ? ORDER BY payment_id FOR UPDATE")) {
                ps.setLong(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return "PAYMENT_NOT_FOUND";
                    paymentId = rs.getLong(1);
                    if (!"SEPAY".equals(rs.getString(2)) || !"CHO_XU_LY".equals(rs.getString(3))
                            || total.compareTo(rs.getBigDecimal(4)) != 0 || rs.next()) return "INVALID_STATE";
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE online_payments SET payment_status = 'THANH_CONG', "
                    + "transaction_reference = ?, paid_at = CURRENT_TIMESTAMP WHERE payment_id = ?")) {
                ps.setString(1, reference);
                ps.setLong(2, paymentId);
                if (ps.executeUpdate() != 1) throw new SQLException("Payment update failed");
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE online_orders SET payment_status = 'DA_THANH_TOAN', "
                    + "order_status = 'DA_XAC_NHAN' WHERE online_order_id = ?")) {
                ps.setLong(1, orderId);
                if (ps.executeUpdate() != 1) throw new SQLException("Order update failed");
            }
            conn.commit();
            return "SUCCESS";
        } catch (SQLException ex) {
            LOG.log(Level.SEVERE, "Unable to record SePay transfer", ex);
            return "DB_ERROR";
        } finally {
            if (conn != null) {
                try {
                    if (!conn.getAutoCommit()) conn.rollback();
                    if (locked) {
                        try (PreparedStatement ps = conn.prepareStatement("SELECT RELEASE_LOCK(?)")) {
                            ps.setString(1, lockName);
                            try (ResultSet ignored = ps.executeQuery()) { /* release connection lock */ }
                        }
                    }
                    conn.setAutoCommit(true);
                } catch (SQLException ex) {
                    LOG.log(Level.WARNING, "Unable to release SePay transaction resources", ex);
                } finally {
                    try { conn.close(); }
                    catch (SQLException ex) { LOG.log(Level.WARNING, "Unable to close payment connection", ex); }
                }
            }
        }
    }
}
