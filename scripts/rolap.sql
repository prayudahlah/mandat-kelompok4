-- 1.1
CREATE OR ALTER VIEW v_neraca_surplus_defisit AS
WITH neraca AS (
    SELECT 
        origin.name AS province_name,
        origin.province_key,
        SUM(foi.quantity_kg) AS volume_keluar,
        SUM(foi.total_amount) AS nilai_keluar
    FROM fact_order_items foi
    INNER JOIN dim_province origin ON foi.origin_province_key = origin.province_key
    WHERE origin.valid_to IS NULL
    GROUP BY origin.name, origin.province_key
    
    UNION ALL
    
    SELECT 
        dest.name AS province_name,
        dest.province_key,
        -SUM(foi.quantity_kg) AS volume_keluar,
        -SUM(foi.total_amount) AS nilai_keluar
    FROM fact_order_items foi
    INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
    WHERE dest.valid_to IS NULL
    GROUP BY dest.name, dest.province_key
)
SELECT 
    province_name,
    SUM(volume_keluar) AS net_volume_kg,
    SUM(nilai_keluar) AS net_value,
    CASE 
        WHEN SUM(volume_keluar) > 0 THEN 'Surplus'
        WHEN SUM(volume_keluar) < 0 THEN 'Defisit'
        ELSE 'Seimbang'
    END AS status_neraca,
    ABS(SUM(volume_keluar)) AS total_volume_mutasi
FROM neraca
GROUP BY province_name, province_key;

-- 1.2
CREATE OR ALTER VIEW v_aliran_pangan AS
SELECT 
    origin.name AS province_asal,
    dest.name AS province_tujuan,
    pc.category_name AS komoditas,
    d.year,
    SUM(foi.quantity_kg) AS total_volume_kg,
    SUM(foi.total_amount) AS total_nilai,
    COUNT(foi.order_item_id) AS jumlah_transaksi
FROM fact_order_items foi
INNER JOIN dim_province origin ON foi.origin_province_key = origin.province_key
INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
INNER JOIN dim_products p ON foi.product_key = p.product_key
INNER JOIN dim_product_categories pc ON p.category_key = pc.category_key
INNER JOIN dim_date d ON foi.date_id = d.date_id
WHERE origin.valid_to IS NULL 
  AND dest.valid_to IS NULL
  AND p.valid_to IS NULL
GROUP BY origin.name, dest.name, pc.category_name, d.year;

-- 1.3
CREATE OR ALTER VIEW v_dependency_index AS
WITH pasokan AS (
    SELECT 
        dest.name AS province_tujuan,
        origin.name AS province_asal,
        SUM(foi.quantity_kg) AS pasokan_volume
    FROM fact_order_items foi
    INNER JOIN dim_province origin ON foi.origin_province_key = origin.province_key
    INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
    WHERE origin.valid_to IS NULL AND dest.valid_to IS NULL
    GROUP BY dest.name, origin.name
),
total_pasokan AS (
    SELECT 
        province_tujuan,
        SUM(pasokan_volume) AS total_volume
    FROM pasokan
    GROUP BY province_tujuan
)
SELECT 
    p.province_tujuan,
    p.province_asal,
    p.pasokan_volume,
    t.total_volume,
    CAST(ROUND(100.0 * p.pasokan_volume / NULLIF(t.total_volume, 0), 2) AS DECIMAL(10,2)) AS dependency_pct,
    CASE 
        WHEN 100.0 * p.pasokan_volume / NULLIF(t.total_volume, 0) > 80 THEN 'KRITIS (>80%)'
        WHEN 100.0 * p.pasokan_volume / NULLIF(t.total_volume, 0) > 50 THEN 'Tinggi (>50%)'
        ELSE 'Normal'
    END AS tingkat_ketergantungan
FROM pasokan p
INNER JOIN total_pasokan t ON p.province_tujuan = t.province_tujuan
WHERE p.pasokan_volume > 0;

-- 2.1
CREATE OR ALTER VIEW v_volatilitas_harga AS
SELECT 
    d.year,
    d.month,
    pc.category_name,
    AVG(foi.unit_price) AS avg_price,
    STDEV(foi.unit_price) AS std_dev_price,
    AVG(foi.unit_price) - STDEV(foi.unit_price) AS lower_band,
    AVG(foi.unit_price) + STDEV(foi.unit_price) AS upper_band,
    COUNT(foi.order_item_id) AS sample_count
FROM fact_order_items foi
INNER JOIN dim_products p ON foi.product_key = p.product_key
INNER JOIN dim_product_categories pc ON p.category_key = pc.category_key
INNER JOIN dim_date d ON foi.date_id = d.date_id
WHERE p.valid_to IS NULL
  AND pc.valid_to IS NULL
GROUP BY d.year, d.month, pc.category_name;

-- 2.2
CREATE OR ALTER VIEW v_disparitas_harga AS
SELECT 
    dest.name AS province_name,
    pc.category_name,
    MIN(foi.unit_price) AS min_price,
    AVG(foi.unit_price) AS avg_price,
    MAX(foi.unit_price) AS max_price,
    COUNT(foi.order_item_id) AS transaction_count
FROM fact_order_items foi
INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
INNER JOIN dim_products p ON foi.product_key = p.product_key
INNER JOIN dim_product_categories pc ON p.category_key = pc.category_key
WHERE dest.valid_to IS NULL
GROUP BY dest.name, pc.category_name;
-- 3.1
CREATE OR ALTER VIEW v_early_warning AS
WITH monthly_nego AS (
    SELECT 
        d.year,
        d.month,
        COUNT(fn.negotiations_id) AS total_negotiations,
        AVG(fn.duration_hours) AS avg_negotiation_hours
    FROM fact_negotiations fn
    INNER JOIN dim_date d ON fn.start_date_id = d.date_id
    GROUP BY d.year, d.month
),
monthly_sales AS (
    SELECT 
        d.year,
        d.month,
        SUM(foi.quantity_kg) AS total_volume_kg,
        SUM(foi.total_amount) AS total_sales_value,
        COUNT(foi.order_item_id) AS total_transactions
    FROM fact_order_items foi
    INNER JOIN dim_date d ON foi.date_id = d.date_id
    GROUP BY d.year, d.month
)
SELECT 
    n.year,
    n.month,
    n.total_negotiations,
    n.avg_negotiation_hours,
    s.total_volume_kg,
    s.total_sales_value,
    s.total_transactions,
    CASE 
        WHEN n.total_negotiations > LAG(n.total_negotiations) OVER (ORDER BY n.year, n.month)
         AND s.total_volume_kg < LAG(s.total_volume_kg) OVER (ORDER BY n.year, n.month)
        THEN 'SINYAL KELANGKAAN'
        WHEN n.total_negotiations > LAG(n.total_negotiations) OVER (ORDER BY n.year, n.month) * 1.2
        THEN 'Peningkatan Negosiasi'
        WHEN s.total_volume_kg < LAG(s.total_volume_kg) OVER (ORDER BY n.year, n.month) * 0.8
        THEN 'Penurunan Volume'
        ELSE 'Normal'
    END AS early_warning_signal
FROM monthly_nego n
LEFT JOIN monthly_sales s ON n.year = s.year AND n.month = s.month;

-- 4.1
CREATE OR ALTER VIEW v_kontrak_vs_spot AS
WITH spot_by_region AS (
    SELECT 
        dest.name AS province_name,
        SUM(foi.total_amount) AS spot_value,
        SUM(foi.quantity_kg) AS spot_volume
    FROM fact_order_items foi
    INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
    WHERE dest.valid_to IS NULL
    GROUP BY dest.name
),
contract_by_region AS (
    SELECT 
        dest.name AS province_name,
        SUM(fc.total_amount) AS contract_value,
        COUNT(fc.contract_id) AS contract_count
    FROM fact_contracts fc
    INNER JOIN dim_province dest ON fc.destination_province_key = dest.province_key
    WHERE dest.valid_to IS NULL
    GROUP BY dest.name
)
SELECT 
    COALESCE(s.province_name, c.province_name) AS province_name,
    ISNULL(s.spot_value, 0) AS spot_total_value,
    ISNULL(s.spot_volume, 0) AS spot_total_volume_kg,
    ISNULL(c.contract_value, 0) AS contract_total_value,
    ISNULL(c.contract_count, 0) AS contract_count,
    CASE 
        WHEN ISNULL(s.spot_value, 0) + ISNULL(c.contract_value, 0) > 0 
        THEN CAST(ROUND(100.0 * ISNULL(c.contract_value, 0) / 
             (ISNULL(s.spot_value, 0) + ISNULL(c.contract_value, 0)), 2) AS DECIMAL(10,2))
        ELSE 0
    END AS contract_percentage,
    CASE 
        WHEN ISNULL(c.contract_value, 0) > ISNULL(s.spot_value, 0) 
        THEN 'Kontrak Dominan (Stabil)'
        WHEN ISNULL(c.contract_value, 0) > ISNULL(s.spot_value, 0) * 0.5 
        THEN 'Cukup Stabil'
        ELSE 'Spot Dominan (Tidak Stabil)'
    END AS stability_status
FROM spot_by_region s
FULL OUTER JOIN contract_by_region c ON s.province_name = c.province_name;

-- 4.4a
CREATE OR ALTER VIEW v_diversifikasi_detail AS
WITH consumption AS (
    SELECT 
        dest.name AS province_name,
        pc.category_name,
        SUM(foi.total_amount) AS expenditure
    FROM fact_order_items foi
    INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
    INNER JOIN dim_products p ON foi.product_key = p.product_key
    INNER JOIN dim_product_categories pc ON p.category_key = pc.category_key
    WHERE dest.valid_to IS NULL
      AND pc.parent_category_key IS NULL  
    GROUP BY dest.name, pc.category_name
),
total_exp AS (
    SELECT 
        province_name,
        SUM(expenditure) AS total_expenditure
    FROM consumption
    GROUP BY province_name
)
SELECT 
    c.province_name,
    c.category_name,
    c.expenditure,
    t.total_expenditure,
    CAST(ROUND(100.0 * c.expenditure / NULLIF(t.total_expenditure, 0), 2) AS DECIMAL(10,2)) AS share_percentage,
    CAST(ROUND(10000.0 * POWER(1.0 * c.expenditure / NULLIF(t.total_expenditure, 0), 2), 2) AS DECIMAL(10,2)) AS hhi_contribution
FROM consumption c
INNER JOIN total_exp t ON c.province_name = t.province_name;

-- 4.4b
CREATE OR ALTER VIEW v_hhi_score AS
WITH consumption AS (
    SELECT 
        dest.name AS province_name,
        pc.category_name,
        SUM(foi.total_amount) AS expenditure
    FROM fact_order_items foi
    INNER JOIN dim_province dest ON foi.destination_province_key = dest.province_key
    INNER JOIN dim_products p ON foi.product_key = p.product_key
    INNER JOIN dim_product_categories pc ON p.category_key = pc.category_key
    WHERE dest.valid_to IS NULL
      AND pc.parent_category_key IS NULL  
    GROUP BY dest.name, pc.category_name
),
total_exp AS (
    SELECT 
        province_name,
        SUM(expenditure) AS total_expenditure
    FROM consumption
    GROUP BY province_name
)
SELECT 
    c.province_name,
    SUM(CAST(10000.0 * POWER(1.0 * c.expenditure / NULLIF(t.total_expenditure, 0), 2) AS DECIMAL(10,2))) AS hhi_score,
    CASE 
        WHEN SUM(CAST(10000.0 * POWER(1.0 * c.expenditure / NULLIF(t.total_expenditure, 0), 2) AS DECIMAL(10,2))) > 2500 
            THEN 'Kurang Diversifikasi (Terpusat)'
        WHEN SUM(CAST(10000.0 * POWER(1.0 * c.expenditure / NULLIF(t.total_expenditure, 0), 2) AS DECIMAL(10,2))) > 1500 
            THEN 'Cukup Diversifikasi'
        ELSE 'Sangat Diversifikasi'
    END AS diversifikasi_status
FROM consumption c
INNER JOIN total_exp t ON c.province_name = t.province_name
GROUP BY c.province_name;
