package catalog;

import dao.ProductDAO;
import db.DBContext;
import model.Product;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/** Isolated query checks: temporary tables shadow real catalog tables on one connection. */
public final class CatalogFilterTest {
    private static int checks;

    public static void main(String[] args) throws Exception {
        try (Connection connection = new DBContext().getConnection()) {
            if (connection == null) throw new IllegalStateException("Database unavailable");
            try (Statement sql = connection.createStatement()) {
                for (String table : new String[]{"products", "categories", "inventory_batches", "product_catalog_details",
                        "sale_transactions", "sale_items", "online_orders", "online_order_items"}) {
                    String temporary = "catalog_test_" + table;
                    sql.execute("CREATE TEMPORARY TABLE " + temporary + " LIKE " + table);
                    sql.execute("ALTER TABLE " + temporary + " RENAME TO " + table);
                }
                sql.execute("INSERT INTO categories (category_id,category_name,status) VALUES "
                        + "(1,'Pain','HOAT_DONG'),(2,'Vitamin và thực phẩm bổ sung','HOAT_DONG'),"
                        + "(3,'Hidden category','NGUNG_HOAT_DONG')");
                for (int id = 1; id <= 13; id++) {
                    String type = "KHONG_KE_DON";
                    int online = 1;
                    if (id == 3 || id == 5) { type = "KE_DON"; online = 0; }
                    if (id == 4) { type = "HAN_CHE"; online = 0; }
                    if (id == 8) online = 0;
                    int category = 1;
                    if (id == 7) category = 3;
                    if (id == 13) category = 2;
                    String status = "HOAT_DONG";
                    if (id == 6) status = "NGUNG_HOAT_DONG";
                    String name = "Item " + id;
                    if (id == 1) name = "Alpha medicine";
                    if (id == 2) name = "Beta medicine";
                    sql.execute("INSERT INTO products (product_id,category_id,product_name,sku,"
                            + "active_ingredient,manufacturer,product_type,selling_unit,selling_price,online_sale_allowed,status) "
                            + "VALUES (" + id + "," + category + ",'" + name + "','CAT" + id + "',"
                            + "'Ingredient " + id + "','Maker " + id + "','" + type + "','Box',100," + online + ",'" + status + "')");
                    if (id != 5 && id != 13) {
                        int health = 0;
                        if (id == 2 || id == 3 || id == 9) health = 1;
                        int mother = 0;
                        if (id == 2 || id == 4) mother = 1;
                        int visible = 1;
                        if (id == 8) visible = 0;
                        sql.execute("INSERT INTO product_catalog_details (product_id,image_path,catalog_visible,"
                                + "health_care,mother_baby,source_url,price_source_url,verified_at) VALUES ("
                                + id + ",'/images/products/CAT" + id + ".png'," + visible + "," + health + "," + mother
                                + ",'https://source.example/medicine','https://source.example/price',CURDATE())");
                    }
                }
                // A valid promotion, an expired one, a future one, and one without evidence.
                sql.execute("UPDATE product_catalog_details SET promotion_label='TEST ONLY',"
                        + "promotion_source_url='https://source.example/campaign',"
                        + "promotion_from=DATE_SUB(CURDATE(),INTERVAL 1 DAY),"
                        + "promotion_until=DATE_ADD(CURDATE(),INTERVAL 1 DAY) WHERE product_id IN (3,9,10,11,12)");
                sql.execute("UPDATE product_catalog_details SET promotion_until=DATE_SUB(CURDATE(),INTERVAL 1 DAY) WHERE product_id=10");
                sql.execute("UPDATE product_catalog_details SET promotion_from=DATE_ADD(CURDATE(),INTERVAL 1 DAY),"
                        + "promotion_until=DATE_ADD(CURDATE(),INTERVAL 2 DAY) WHERE product_id=11");
                sql.execute("UPDATE product_catalog_details SET promotion_source_url=NULL WHERE product_id=12");
                for (int id : new int[]{1,3,4,9}) {
                    sql.execute("INSERT INTO inventory_batches (product_id,batch_number,expiry_date,on_hand_quantity,reserved_quantity,status) "
                            + "VALUES (" + id + ",'TEST-" + id + "','2099-01-01',8,0,'CO_SAN')");
                }
            }
            Connection testConnection = connection;
            ProductDAO dao = new ProductDAO() {
                @Override public Connection getConnection() { return testConnection; }
                @Override public void closeResources() {
                    // Keep the temporary-table connection open until this test finishes.
                    try {
                        if (resultSet != null) resultSet.close();
                        if (statement != null) statement.close();
                    } catch (SQLException error) {
                        throw new IllegalStateException(error);
                    }
                }
            };
            expect(dao, "", null, null, null, false, 9);
            expect(dao, "Alpha", null, null, null, false, 1);
            expect(dao, "Ingredient 2", null, null, null, false, 1);
            expect(dao, "Maker 4", null, null, null, false, 1);
            expect(dao, "", 1L, null, null, false, 8);
            expect(dao, "", 2L, null, null, false, 1);
            expect(dao, "", 3L, null, null, false, 0);
            expect(dao, "", null, "KE_DON", null, false, 1);
            expect(dao, "", null, "HAN_CHE", null, false, 1);
            expect(dao, "", null, "KHONG_KE_DON", null, false, 7);
            expect(dao, "", null, null, "health", false, 4);
            expect(dao, "", null, null, "mother-baby", false, 2);
            expect(dao, "Beta", 1L, "KHONG_KE_DON", "health", false, 1);
            expect(dao, "", 1L, "KE_DON", "mother-baby", false, 0);
            expect(dao, "", null, null, null, true, 1);
            expect(dao, "", null, "KE_DON", null, true, 0);
            expect(dao, "", null, null, "health", true, 1);
            expect(dao, "", null, null, "mother-baby", true, 0);
            expect(dao, "' OR 1=1 --", null, null, null, false, 0);
            expect(dao, "", null, null, "health' OR 1=1", false, 0);
            check(dao.findCatalog("", null, null, "health", false, 2, 0).size() == 2, "First page limited");
            check(dao.findCatalog("", null, null, "health", false, 2, 2).size() == 2, "Second page uses same topic");
            check(dao.findCatalog("", null, null, "health", false, 2, 4).isEmpty(), "Paging ends correctly");
            Product otc = dao.findStorefrontById(1);
            check(otc != null && otc.isPurchasable(), "Normal stocked OTC stays purchasable");
            check("/images/products/CAT1.png".equals(otc.getImagePath()), "Image loaded from MySQL metadata");
            check(!dao.findStorefrontById(2).isPurchasable(), "No inventory does not invent saleable stock");
            check(!dao.findStorefrontById(3).isPurchasable(), "Stocked prescription reference cannot be bought online");
            check(!dao.findStorefrontById(4).isPurchasable(), "Stocked restricted reference cannot be bought online");
            check(dao.findStorefrontById(5) == null, "Unlisted prescription stays hidden");
            check(dao.findStorefrontById(6) == null, "Inactive product stays hidden");
            check(dao.findStorefrontById(7) == null, "Inactive category stays hidden");
            check(dao.findStorefrontById(8) == null, "Explicit hidden metadata stays hidden");
            check(dao.findById(3) != null, "Admin detail query remains compatible");
            check(dao.findAll("", null, null, null, 100, 0).size() == 13, "Admin list retains all records");
            check(dao.countAll("", null, null, null) == 13, "Admin total remains consistent");
            check(!dao.findOnlineSaleable(100, null).isEmpty(), "Home query loads metadata correctly");

            List<Product> featured = dao.findTopSellingOnline(4);
            check(featured.size() == 4, "Top selling home query retains catalog metadata join");
            check("/images/products/CAT1.png".equals(featured.get(0).getImagePath()),
                    "Top selling query returns the local catalog image");
            List<Product> healthCare = dao.findOnlineSaleableExcluding(4, List.of(1L));
            check(healthCare.size() == 4, "Second home strip query loads local catalog metadata");
            check(healthCare.stream().noneMatch(p -> p.getProductId() == 1L),
                    "Second home strip excludes featured products");
            check("/images/products/CAT2.png".equals(healthCare.get(0).getImagePath()),
                    "Second home strip preserves catalog images");
        }
        System.out.println("PASS " + checks + " catalog checks; only connection-local temporary tables were changed");
    }

    private static void expect(ProductDAO dao, String keyword, Long category, String type,
            String topic, boolean promo, int expected) {
        int count = dao.countCatalog(keyword, category, type, topic, promo);
        List<Product> rows = dao.findCatalog(keyword, category, type, topic, promo, 100, 0);
        check(count == expected, "Expected count " + expected + " for " + keyword + "/" + type + "/" + topic + "/" + promo);
        check(rows.size() == expected, "List agrees with count for combined filters");
    }

    private static void check(boolean condition, String message) {
        checks++;
        if (!condition) throw new AssertionError(message);
    }
}
