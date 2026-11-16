package util;

import java.math.BigDecimal;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** SePay signing, bank notification decoding and per-order references. */
public final class SePayUtil {
    private static final Pattern ORDER_CODE = Pattern.compile(
            "(?<![A-Z0-9])PFSP([1-9][0-9]{0,18})(?![A-Z0-9])", Pattern.CASE_INSENSITIVE);

    private SePayUtil() {
    }

    public static String paymentCode(long orderId) {
        if (orderId <= 0) throw new IllegalArgumentException("Invalid order");
        return "PFSP" + orderId;
    }

    public static long parsePaymentCode(String content) {
        if (content == null) return -1;
        Matcher matcher = ORDER_CODE.matcher(content);
        if (!matcher.find()) return -1;
        String id = matcher.group(1);
        if (matcher.find()) return -1;
        try {
            return Long.parseLong(id);
        } catch (NumberFormatException ex) {
            return -1;
        }
    }

    public static boolean verifySignature(String timestamp, String signature, byte[] body) {
        if (!SePayConfig.isConfigured() || timestamp == null || signature == null
                || !timestamp.matches("[0-9]{1,12}") || !signature.matches("sha256=[0-9a-fA-F]{64}")) {
            return false;
        }
        long sentAt = Long.parseLong(timestamp);
        long now = Instant.now().getEpochSecond();
        if (sentAt < now - 300 || sentAt > now + 300) return false;
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(SePayConfig.webhookSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            mac.update((timestamp + ".").getBytes(StandardCharsets.UTF_8));
            byte[] digest = mac.doFinal(body);
            String expected = "sha256=" + java.util.HexFormat.of().formatHex(digest);
            return MessageDigest.isEqual(expected.getBytes(StandardCharsets.US_ASCII),
                    signature.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.US_ASCII));
        } catch (java.security.GeneralSecurityException ex) {
            throw new IllegalStateException("Unable to verify payment notification", ex);
        }
    }

    /** Use form encoding in the SePay dashboard; rejects repeated field names. */
    public static Map<String, String> parseForm(byte[] body) {
        Map<String, String> values = new LinkedHashMap<>();
        for (String pair : new String(body, StandardCharsets.UTF_8).split("&", -1)) {
            if (pair.isEmpty()) continue;
            String[] parts = pair.split("=", 2);
            if (parts.length != 2) throw new IllegalArgumentException("Invalid form");
            String name = URLDecoder.decode(parts[0], StandardCharsets.UTF_8);
            String value = URLDecoder.decode(parts[1], StandardCharsets.UTF_8);
            if (!name.matches("[A-Za-z][A-Za-z0-9_]*") || values.putIfAbsent(name, value) != null) {
                throw new IllegalArgumentException("Duplicate or invalid field");
            }
        }
        return values;
    }

    /** SePay bank payloads are flat JSON objects; preserve numeric text exactly. */
    public static Map<String, String> parseJson(byte[] body) {
        if (body == null || body.length > 16384) throw new IllegalArgumentException("Invalid JSON size");
        try {
            String text = StandardCharsets.UTF_8.newDecoder().decode(ByteBuffer.wrap(body)).toString();
            return new BankJsonReader(text).readObject();
        } catch (CharacterCodingException ex) {
            throw new IllegalArgumentException("Invalid UTF-8 JSON", ex);
        }
    }

    /** Bounded reader for the documented flat webhook schema, without new JARs. */
    private static final class BankJsonReader {
        private final String text;
        private int position;

        BankJsonReader(String text) {
            this.text = text;
        }

        Map<String, String> readObject() {
            Map<String, String> values = new LinkedHashMap<>();
            expect('{');
            if (!take('}')) {
                do {
                    String name = readString();
                    if (!name.matches("[A-Za-z][A-Za-z0-9_]*") || values.containsKey(name)
                            || values.size() >= 64) throw invalid();
                    expect(':');
                    values.put(name, readValue());
                    if (take('}')) break;
                    expect(',');
                } while (true);
            }
            whitespace();
            if (position != text.length()) throw invalid();
            return values;
        }

        private String readValue() {
            whitespace();
            if (position < text.length() && text.charAt(position) == '"') return readString();
            int start = position;
            while (position < text.length()) {
                char current = text.charAt(position);
                if (current == ',' || current == '}' || isWhitespace(current)) break;
                position++;
            }
            String value = text.substring(start, position);
            if (value.equals("null")) return null;
            if (value.equals("true") || value.equals("false")) return value;
            if (!value.matches("-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?")) throw invalid();
            return value;
        }

        private String readString() {
            expect('"');
            StringBuilder value = new StringBuilder();
            while (position < text.length()) {
                char current = text.charAt(position++);
                if (current == '"') {
                    String result = value.toString();
                    for (int index = 0; index < result.length(); index++) {
                        char character = result.charAt(index);
                        if (Character.isHighSurrogate(character)) {
                            index++;
                            if (index >= result.length() || !Character.isLowSurrogate(result.charAt(index))) throw invalid();
                        } else if (Character.isLowSurrogate(character)) throw invalid();
                    }
                    return result;
                }
                if (current < 0x20) throw invalid();
                if (current != '\\') {
                    value.append(current);
                    continue;
                }
                if (position >= text.length()) throw invalid();
                char escaped = text.charAt(position++);
                switch (escaped) {
                    case '"', '\\', '/' -> value.append(escaped);
                    case 'b' -> value.append('\b');
                    case 'f' -> value.append('\f');
                    case 'n' -> value.append('\n');
                    case 'r' -> value.append('\r');
                    case 't' -> value.append('\t');
                    case 'u' -> {
                        if (position + 4 > text.length()) throw invalid();
                        int code = 0;
                        for (int count = 0; count < 4; count++) {
                            char digit = text.charAt(position++);
                            int hex = "0123456789abcdef".indexOf(Character.toLowerCase(digit));
                            if (hex < 0) throw invalid();
                            code = code * 16 + hex;
                        }
                        value.append((char) code);
                    }
                    default -> throw invalid();
                }
            }
            throw invalid();
        }

        private void expect(char expected) {
            if (!take(expected)) throw invalid();
        }

        private boolean take(char expected) {
            whitespace();
            if (position >= text.length() || text.charAt(position) != expected) return false;
            position++;
            return true;
        }

        private void whitespace() {
            while (position < text.length() && isWhitespace(text.charAt(position))) position++;
        }

        private boolean isWhitespace(char value) {
            return value == ' ' || value == '\t' || value == '\r' || value == '\n';
        }

        private IllegalArgumentException invalid() {
            return new IllegalArgumentException("Invalid or duplicate JSON field");
        }
    }

    public static BigDecimal transferAmount(String value) {
        if (value == null || !value.matches("[0-9]{1,13}(\\.[0-9]{1,2})?")) {
            throw new IllegalArgumentException("Invalid transfer amount");
        }
        BigDecimal amount = new BigDecimal(value);
        if (amount.signum() <= 0) throw new IllegalArgumentException("Invalid transfer amount");
        return amount;
    }

    public static String qrUrl(long orderId, BigDecimal amount) {
        if (!SePayConfig.isConfigured() || amount == null || amount.signum() <= 0) return null;
        // VietQR amounts are whole VND. Never round a customer's amount.
        String vnd = amount.setScale(0, java.math.RoundingMode.UNNECESSARY).toPlainString();
        return "https://vietqr.app/img?acc=" + encode(SePayConfig.qrAccountNumber())
                + "&bank=" + encode(SePayConfig.bankCode()) + "&amount=" + vnd
                + "&des=" + paymentCode(orderId) + "&template=compact";
    }

    private static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
