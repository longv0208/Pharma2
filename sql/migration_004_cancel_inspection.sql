-- Customer in-transit cancellation waits for shipper recovery and staff inspection
-- before stock is put back. Safe to re-run: MODIFY ENUM is idempotent.
ALTER TABLE online_orders
  MODIFY COLUMN order_status ENUM(
    'CHO_XU_LY','DA_XAC_NHAN','DANG_CHUAN_BI','SAN_SANG','DANG_GIAO','HOAN_TAT',
    'DA_HUY','TU_CHOI','YEU_CAU_HOAN','DA_HOAN',
    'YEU_CAU_HUY','CHO_KIEM_HUY','HUY_CO_VAN_DE'
  ) NOT NULL DEFAULT 'CHO_XU_LY';
