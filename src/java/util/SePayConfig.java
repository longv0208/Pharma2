package util;

/** Bank transfer configuration for SePay Webhooks; no credentials in source. */
public final class SePayConfig {
    private SePayConfig() {
    }

    public static String webhookSecret() {
        return setting("SEPAY_WEBHOOK_SECRET", "sepay.webhookSecret");
    }

    public static String accountNumber() {
        return setting("SEPAY_ACCOUNT_NUMBER", "sepay.accountNumber");
    }

    public static String accountName() {
        return setting("SEPAY_ACCOUNT_NAME", "sepay.accountName");
    }

    public static String vaAccount() {
        return setting("SEPAY_VA_ACCOUNT", "sepay.vaAccount");
    }

    /** QR points to the selected VA while notifications retain the main account. */
    public static String qrAccountNumber() {
        String va = vaAccount();
        if (va != null) return va;
        return accountNumber();
    }

    public static String bankCode() {
        String value = setting("SEPAY_BANK_CODE", "sepay.bankCode");
        if (value == null) return "MB";
        return value;
    }

    public static String gateway() {
        String value = setting("SEPAY_GATEWAY", "sepay.gateway");
        if (value == null) return "MBBank";
        return value;
    }

    public static boolean isConfigured() {
        String secret = webhookSecret();
        String account = accountNumber();
        return secret != null && secret.length() >= 32
                && account != null && account.matches("[A-Za-z0-9]{1,19}")
                && (vaAccount() == null || vaAccount().matches("[A-Za-z0-9]{1,19}"));
    }

    private static String setting(String name, String property) {
        String value = System.getenv(name);
        if (value == null || value.trim().isEmpty()) value = System.getProperty(property);
        if (value == null || value.trim().isEmpty()) return null;
        return value.trim();
    }
}
