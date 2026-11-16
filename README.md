# Pharma_Flow

Pharmacy management + online store. Plain Servlet/JSP on Tomcat 10, MySQL 8.

## Stack

- Java 17, Jakarta EE 10 — `jakarta.*` namespace
- JSP 3.x + JSTL 3.x, JDBC via MySQL Connector/J
- NetBeans Java Web project (Ant)

## Layout

```
├── lib/                           compile-only jars (NOT deployed)
│   └── jakarta.servlet-api.jar    provided by Tomcat at runtime
├── nbproject/                     NetBeans web project descriptor
├── src/java/
│   ├── controller/                HomeServlet, AuthenController, ProfileServlet,
│   │                              AdminServlet, StaffServlet, PosServlet
│   ├── dao/                       CategoryDAO, ProductDAO, UserDAO,
│   │                              CustomerProfileDAO, SupplierDAO (extends DBContext)
│   ├── db/                        DBContext — edit credentials here
│   ├── model/                     Category, Product, ProductType, User,
│   │                              CustomerProfile, Supplier
│   └── util/                      PasswordUtil (salted SHA-256)
└── web/                           webroot
    ├── WEB-INF/web.xml
    ├── WEB-INF/views/             JSPs (servlet-forwarded only)
    │   ├── home.jsp, error.jsp
    │   ├── auth/{login,register}.jsp
    │   ├── customer/profile.jsp
    │   ├── admin/dashboard.jsp    (stub)
    │   ├── staff/dashboard.jsp    (stub)
    │   └── pos/dashboard.jsp      (stub)
    ├── WEB-INF/jspf/              header, footer, product-card fragments
    ├── WEB-INF/lib/               runtime jars bundled into WAR (mysql + jstl)
    ├── css/, js/, images/
    └── index.jsp                  redirects to /home
```

## DB config

Single file: `src/java/db/DBContext.java` — edit `DB_URL` / `DB_USER` / `DB_PWD` directly.
Pattern follows the team's DBContext template (fresh `Connection` per call, driver loaded in ctor).

## Setup

1. JDK 17, Tomcat 10.1, MySQL 8.4.
2. Import `Pharmaflow3_full.sql` from the database transfer package.
   See the [Pharmaflow3 transfer guide](../DataBase/README.md#chuyển-pharmaflow3-sang-máy-mới).
   The dump creates `Pharmaflow3` with the application data and the warehouse
   location schema. Run the dump once on the destination server.
3. Place jars:
   - `lib/jakarta.servlet-api.jar` — copy from `$CATALINA_HOME/lib/servlet-api.jar` (compile-only, already present)
   - `web/WEB-INF/lib/mysql-connector-j.jar` — `com.mysql:mysql-connector-j:8.x`
   - `web/WEB-INF/lib/jakarta.servlet.jsp.jstl-api.jar` — `jakarta.servlet.jsp.jstl:jakarta.servlet.jsp.jstl-api:3.0.0`
   - `web/WEB-INF/lib/jakarta.servlet.jsp.jstl.jar` — `org.glassfish.web:jakarta.servlet.jsp.jstl:3.0.1`
4. Set the host, port and credentials in `src/java/db/DBContext.java` for the
   destination MySQL server. The default URL selects `Pharmaflow3`.
5. Back up the destination database, stop the application and run
   [the order return migration](sql/migration_002_order_returns.sql) on that
   schema before deploying this update. The migration adds return states,
   the return reason and return stock movements.

Important: keep `jakarta.servlet-api.jar` out of `web/WEB-INF/lib/` — anything physically
in that folder is copied into the WAR, and shipping Tomcat's servlet API inside
the webapp breaks classloading.

## Build & run

Open in NetBeans → Clean & Build → produces `dist/Pharma_Flow.war` → deploy on Tomcat 10.

Open `http://localhost:8080/Pharma_Flow/`.

## Endpoints

| Path | Type | Purpose |
|------|------|---------|
| `/` | HTML | redirects to `/home` |
| `/home` | HTML | customer home page |
| `/about` | HTML | public pharmacy introduction, regulations, purchase policies and privacy information |
| `/products` | HTML | catalog grid, filters `?q=&category=&type=&page=` |
| `/products/{id}` | HTML | product detail (404 unless HOAT_DONG+online_sale_allowed) |
| `/authen?action=login` | HTML | sign-in form / POST login |
| `/authen?action=register` | HTML | register form / POST register |
| `/authen?action=logout` | — | invalidate session, redirect /home |
| `/profile` | HTML | customer self-profile (session-gated, KHACH_HANG only) |
| `/admin` | HTML | CHU_QUAN_QUAN_TRI dashboard (session-gated) |
| `/admin?action=categories` | HTML | admin: list all categories |
| `/admin?action=category-new` | HTML | admin: create form / POST `category-create` |
| `/admin?action=category-edit&id=N` | HTML | admin: edit form / POST `category-update` |
| `/admin?action=category-delete` (POST) | — | admin: soft-delete → status=NGUNG_HOAT_DONG |
| `/admin?action=suppliers` | HTML | admin: list all suppliers |
| `/admin?action=supplier-new` | HTML | admin: create form / POST `supplier-create` |
| `/admin?action=supplier-edit&id=N` | HTML | admin: edit form / POST `supplier-update` |
| `/admin?action=supplier-delete` (POST) | — | admin: soft-delete → status=NGUNG_HOAT_DONG |
| `/admin?action=products` | HTML | admin: list products (q/categoryId/type/status/page filters) |
| `/admin?action=product-new` | HTML | admin: create form / POST `product-create` |
| `/admin?action=product-edit&id=N` | HTML | admin: edit form / POST `product-update` |
| `/admin?action=product-delete` (POST) | — | admin: soft-delete → status=NGUNG_HOAT_DONG |
| `/staff` | HTML | STAFF landing (session-gated stub) |
| `/pos` | HTML | STAFF POS stub (session-gated, real POS in a later phase) |

## Verified catalog data

The [20-product import notes](docs/catalog-products-20261028.md) list verified
medicine facts, public prices, image provenance and filter behavior. Apply
`sql/20261028_catalog_details_schema.sql` before the matching product migration
and before deploying the updated Java code. Images and per-product source notes
are in `sql/IMG Product`; website copies are included under `web/images/products`.
No inventory batches or store promotions were invented. Prescription entries
remain reference-only. The catalog now supports topic and promotion filters.

## Payments

Checkout offers COD and bank transfer QR through SePay. New VNPAY checkout
has been removed from the page and is rejected by the controller and DAO.
Existing VNPAY history and signed callbacks remain available for old orders;
[the VNPAY integration notes](docs/vnpay-payments.md) describe that legacy code.

## Notes

- `/about` provides Vietnamese pharmacy information, legal references checked on
  2026-11-11, purchase policies, privacy information, section navigation and a
  print/PDF action. Header, footer and registration pages link to it.
- Actual operator identity, pharmacy address, professional/operating license
  details and an official privacy/contact channel have not been supplied. The
  page discloses that gap; it does not invent licenses or certify GPP, national
  database integration, encryption or legal compliance. Confirm and publish
  those details before using the page for a real pharmacy operation.
- This informational change does not implement consent capture, marketing,
  automated data deletion or a privacy request submission workflow. The page
  distinguishes the existing profile editor from rights requiring an official
  contact channel. See `docs/pharmacy-information-policies.md` for source notes.

Bank transfer QR with automatic confirmation is available via SePay
Webhooks. See [SePay setup and validation](docs/sepay-payments.md) and
`config/sepay.env.example`. It stays disabled until the receiving bank account
and webhook secret are configured. COD is available independently.

For the local Windows preview, `tools/start-local-preview.ps1` creates an
isolated Tomcat base under `build/tomcat-preview`. Run `tools/configure-sepay.ps1`
to save the webhook secret with Windows DPAPI outside Git; the profile stays
disabled until the matching SePay webhook is confirmed. Enable it and restart
the owned preview as described in the SePay guide. For public callbacks, see
[HTTPS setup and current limitations](docs/sepay-https.md).

- JSPs under `WEB-INF/views/` only reachable via servlet forward.
- Read-only catalog: no auth, no writes — no CSRF needed.
- Featured/HealthCare split is positional (first 8 by `product_id`, split 4+4) —
  schema has no "health care" flag.
- Purchasable rule: `product_type='KHONG_KE_DON'` AND `online_sale_allowed=1` AND in stock.
  KE_DON/HAN_CHE products render but with disabled Add-to-Cart.
- No JSON API for now — only JSP-rendered pages. Add `util/JsonUtil` when an API is needed.
- Auth: session-based, `currentUser` in `HttpSession`. Login accepts email or username.
  Public registration always forces `role=KHACH_HANG` and `status=HOAT_DONG` server-side.
  Passwords stored as `salt:hash` (SHA-256) via `util/PasswordUtil` — never plain text.
