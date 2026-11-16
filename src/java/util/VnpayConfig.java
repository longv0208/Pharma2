package util;

import java.net.URI;

/** Merchant credentials come from the environment or JVM, never from source. */
public final class VnpayConfig {

    public static final String VERSION = "2.1.0";

    private VnpayConfig() {
    }

    public static String tmnCode() {
        return setting("VNPAY_TMN_CODE", "vnpay.tmnCode");
    }

    public static String hashSecret() {
        return setting("VNPAY_HASH_SECRET", "vnpay.hashSecret");
    }

    public static String environment() {
        String value = setting("VNPAY_ENVIRONMENT", "vnpay.environment");
        if (value == null) {
            return "sandbox";
        }
        return value;
    }

    public static String paymentUrl() {
        if ("production".equals(environment())) {
            return "https://pay.vnpay.vn/vpcpay.html";
        }
        return "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
    }

    /** A fixed public URL also works when Tomcat sits behind an HTTPS proxy. */
    public static String returnUrl() {
        return setting("VNPAY_RETURN_URL", "vnpay.returnUrl");
    }

    /** Leave unset to let the customer choose QR or card at VNPAY. */
    public static String bankCode() {
        return setting("VNPAY_BANK_CODE", "vnpay.bankCode");
    }

    public static boolean isConfigured() {
        if (tmnCode() == null || hashSecret() == null) {
            return false;
        }
        String mode = environment();
        if (!"sandbox".equals(mode) && !"production".equals(mode)) {
            return false;
        }
        if (returnUrl() == null) {
            return "sandbox".equals(mode);
        }
        try {
            URI uri = URI.create(returnUrl());
            if (uri.getHost() == null || uri.getUserInfo() != null
                    || uri.getFragment() != null || uri.getQuery() != null) {
                return false;
            }
            if ("https".equals(uri.getScheme())) {
                return true;
            }
            return "sandbox".equals(mode) && "http".equals(uri.getScheme());
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    private static String setting(String environmentName, String propertyName) {
        String value = System.getenv(environmentName);
        if (value == null || value.trim().isEmpty()) {
            value = System.getProperty(propertyName);
        }
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
