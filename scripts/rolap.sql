USE warehouse;
GO

/* ============================================================
   0.0 DIMENSI MONTH UNTUK SLICER POWER BI
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_dim_month AS
SELECT
    d.[year],
    d.[month],
    d.[year] * 100 + d.[month] AS year_month_key,
    CONCAT(d.[year], '-', RIGHT('0' + CAST(d.[month] AS VARCHAR(2)), 2)) AS year_month_label,
    DATENAME(MONTH, MIN(d.full_date)) AS month_name
FROM dbo.dim_date d
WHERE EXISTS (
    SELECT 1 FROM dbo.fact_order_items foi WHERE foi.date_id = d.date_id
)
GROUP BY 
    d.[year], 
    d.[month];
GO
/* ============================================================
   0.1 DIMENSI KATEGORI UNTUK SLICER POWER BI
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_dim_category AS
SELECT DISTINCT pc.category_name
FROM dbo.dim_product_categories pc
WHERE EXISTS (
    SELECT 1
    FROM dbo.fact_order_items foi
    INNER JOIN dbo.dim_products p ON foi.product_key = p.product_key
    WHERE p.category_key = pc.category_key
      AND ISNULL(foi.is_interprovince, 0) = 1
)
AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE));

/* ============================================================
   1.1 NERACA MUTASI DISTRIBUSI PANGAN PER WILAYAH
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_neraca_surplus_defisit AS
WITH keluar AS (
    SELECT
        d.[year],
        d.[month],
        d.[year] * 100 + d.[month] AS year_month_key,
        pc.category_name,
        origin.province_key,
        origin.province_name,
        SUM(ISNULL(foi.quantity_kg, 0)) AS volume_keluar,
        SUM(ISNULL(foi.total_amount, 0)) AS nilai_keluar
    FROM dbo.fact_order_items foi
    INNER JOIN dbo.dim_province origin
        ON foi.origin_province_key = origin.province_key
    INNER JOIN dbo.dim_products p
        ON foi.product_key = p.product_key
    INNER JOIN dbo.dim_product_categories pc
        ON p.category_key = pc.category_key
    INNER JOIN dbo.dim_date d
        ON foi.date_id = d.date_id
    WHERE
        (origin.valid_to IS NULL OR origin.valid_to >= CAST(GETDATE() AS DATE))
        AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
        AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
        AND ISNULL(foi.is_interprovince, 0) = 1
    GROUP BY
        d.[year],
        d.[month],
        pc.category_name,
        origin.province_key,
        origin.province_name
),
masuk AS (
    SELECT
        d.[year],
        d.[month],
        d.[year] * 100 + d.[month] AS year_month_key,
        pc.category_name,
        dest.province_key,
        dest.province_name,
        SUM(ISNULL(foi.quantity_kg, 0)) AS volume_masuk,
        SUM(ISNULL(foi.total_amount, 0)) AS nilai_masuk
    FROM dbo.fact_order_items foi
    INNER JOIN dbo.dim_province dest
        ON foi.destination_province_key = dest.province_key
    INNER JOIN dbo.dim_products p
        ON foi.product_key = p.product_key
    INNER JOIN dbo.dim_product_categories pc
        ON p.category_key = pc.category_key
    INNER JOIN dbo.dim_date d
        ON foi.date_id = d.date_id
    WHERE
        (dest.valid_to IS NULL OR dest.valid_to >= CAST(GETDATE() AS DATE))
        AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
        AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
        AND ISNULL(foi.is_interprovince, 0) = 1
    GROUP BY
        d.[year],
        d.[month],
        pc.category_name,
        dest.province_key,
        dest.province_name
)
SELECT
    COALESCE(k.[year], m.[year]) AS [year],
    COALESCE(k.[month], m.[month]) AS [month],
    COALESCE(k.year_month_key, m.year_month_key) AS year_month_key,
    COALESCE(k.category_name, m.category_name) AS category_name,
    COALESCE(k.province_key, m.province_key) AS province_key,
    COALESCE(k.province_name, m.province_name) AS province_name,

    ISNULL(k.volume_keluar, 0) AS volume_keluar,
    ISNULL(m.volume_masuk, 0) AS volume_masuk,

    ISNULL(k.nilai_keluar, 0) AS nilai_keluar,
    ISNULL(m.nilai_masuk, 0) AS nilai_masuk,

    ISNULL(k.volume_keluar, 0) - ISNULL(m.volume_masuk, 0) AS net_volume_kg,
    ISNULL(k.nilai_keluar, 0) - ISNULL(m.nilai_masuk, 0) AS net_value,

    ISNULL(k.volume_keluar, 0) + ISNULL(m.volume_masuk, 0) AS total_volume_mutasi,
    ABS(ISNULL(k.volume_keluar, 0) - ISNULL(m.volume_masuk, 0)) AS absolute_net_volume_kg,

    CASE
        WHEN ISNULL(k.volume_keluar, 0) - ISNULL(m.volume_masuk, 0) > 0
            THEN 'Net Pemasok'
        WHEN ISNULL(k.volume_keluar, 0) - ISNULL(m.volume_masuk, 0) < 0
            THEN 'Net Penerima'
        ELSE 'Seimbang'
    END AS status_neraca
FROM keluar k
FULL OUTER JOIN masuk m
    ON k.year_month_key = m.year_month_key
   AND k.category_name = m.category_name
   AND k.province_key = m.province_key;
GO


/* ============================================================
   1.2 ALIRAN PANGAN ANTARWILAYAH
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_aliran_pangan AS
SELECT
    d.[year],
    d.[month],
    d.[year] * 100 + d.[month] AS year_month_key,

    origin.province_name AS province_asal,
    dest.province_name AS province_tujuan,
    pc.category_name,

    SUM(ISNULL(foi.quantity_kg, 0)) AS total_volume_kg,
    SUM(ISNULL(foi.total_amount, 0)) AS total_nilai,
    COUNT(foi.order_item_id) AS jumlah_transaksi
FROM dbo.fact_order_items foi
INNER JOIN dbo.dim_province origin
    ON foi.origin_province_key = origin.province_key
INNER JOIN dbo.dim_province dest
    ON foi.destination_province_key = dest.province_key
INNER JOIN dbo.dim_products p
    ON foi.product_key = p.product_key
INNER JOIN dbo.dim_product_categories pc
    ON p.category_key = pc.category_key
INNER JOIN dbo.dim_date d
    ON foi.date_id = d.date_id
WHERE
    (origin.valid_to IS NULL OR origin.valid_to >= CAST(GETDATE() AS DATE))
    AND (dest.valid_to IS NULL OR dest.valid_to >= CAST(GETDATE() AS DATE))
    AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
    AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
    AND ISNULL(foi.is_interprovince, 0) = 1
GROUP BY
    d.[year],
    d.[month],
    origin.province_name,
    dest.province_name,
    pc.category_name;
GO


/* ============================================================
   1.3 DEPENDENCY INDEX PASOKAN
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_dependency_index AS
WITH pasokan AS (
    SELECT
        d.[year],
        d.[month],
        d.[year] * 100 + d.[month] AS year_month_key,
        pc.category_name,
        dest.province_name AS province_tujuan,
        origin.province_name AS province_asal,
        SUM(ISNULL(foi.quantity_kg, 0)) AS pasokan_volume
    FROM dbo.fact_order_items foi
    INNER JOIN dbo.dim_province origin
        ON foi.origin_province_key = origin.province_key
    INNER JOIN dbo.dim_province dest
        ON foi.destination_province_key = dest.province_key
    INNER JOIN dbo.dim_products p
        ON foi.product_key = p.product_key
    INNER JOIN dbo.dim_product_categories pc
        ON p.category_key = pc.category_key
    INNER JOIN dbo.dim_date d
        ON foi.date_id = d.date_id
    WHERE
        (origin.valid_to IS NULL OR origin.valid_to >= CAST(GETDATE() AS DATE))
        AND (dest.valid_to IS NULL OR dest.valid_to >= CAST(GETDATE() AS DATE))
        AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
        AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
        AND ISNULL(foi.is_interprovince, 0) = 1
    GROUP BY
        d.[year],
        d.[month],
        pc.category_name,
        dest.province_name,
        origin.province_name
),
total_pasokan AS (
    SELECT
        year_month_key,
        category_name,
        province_tujuan,
        SUM(pasokan_volume) AS total_volume
    FROM pasokan
    GROUP BY
        year_month_key,
        category_name,
        province_tujuan
)
SELECT
    p.[year],
    p.[month],
    p.year_month_key,
    p.category_name,
    p.province_tujuan,
    p.province_asal,
    p.pasokan_volume,
    t.total_volume,

    CAST(
        ROUND(
            100.0 * p.pasokan_volume / NULLIF(t.total_volume, 0),
            2
        ) AS DECIMAL(10,2)
    ) AS dependency_pct,

    CASE
        WHEN 100.0 * p.pasokan_volume / NULLIF(t.total_volume, 0) > 80
            THEN 'KRITIS (>80%)'
        WHEN 100.0 * p.pasokan_volume / NULLIF(t.total_volume, 0) > 50
            THEN 'Tinggi (>50%)'
        ELSE 'Normal'
    END AS tingkat_ketergantungan
FROM pasokan p
INNER JOIN total_pasokan t
    ON p.year_month_key = t.year_month_key
   AND p.category_name = t.category_name
   AND p.province_tujuan = t.province_tujuan
WHERE p.pasokan_volume > 0;
GO


/* ============================================================
   2.1 VOLATILITAS HARGA BULANAN
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_volatilitas_harga AS
SELECT
    d.[year],
    d.[month],
    d.[year] * 100 + d.[month] AS year_month_key,
    pc.category_name,

    AVG(foi.price_per_kg) AS avg_price,
    ISNULL(STDEV(foi.price_per_kg), 0) AS std_dev_price,

    AVG(foi.price_per_kg) - ISNULL(STDEV(foi.price_per_kg), 0) AS lower_band,
    AVG(foi.price_per_kg) + ISNULL(STDEV(foi.price_per_kg), 0) AS upper_band,

    COUNT(foi.order_item_id) AS sample_count
FROM dbo.fact_order_items foi
INNER JOIN dbo.dim_products p
    ON foi.product_key = p.product_key
INNER JOIN dbo.dim_product_categories pc
    ON p.category_key = pc.category_key
INNER JOIN dbo.dim_date d
    ON foi.date_id = d.date_id
WHERE
    foi.price_per_kg IS NOT NULL
    AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
    AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
GROUP BY
    d.[year],
    d.[month],
    pc.category_name;
GO


/* ============================================================
   2.2 DISPARITAS / RENTANG HARGA ANTARWILAYAH
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_disparitas_harga AS
SELECT
    d.[year],
    d.[month],
    d.[year] * 100 + d.[month] AS year_month_key,
    dest.province_key,
    dest.province_name,
    pc.category_key,
    pc.category_name,

    MIN(foi.price_per_kg) AS min_price,
    AVG(foi.price_per_kg) AS avg_price,
    MAX(foi.price_per_kg) AS max_price,

    MAX(foi.price_per_kg) - MIN(foi.price_per_kg) AS price_range,

    COUNT(foi.order_item_id) AS transaction_count
FROM dbo.fact_order_items foi
INNER JOIN dbo.dim_province dest
    ON foi.destination_province_key = dest.province_key
INNER JOIN dbo.dim_products p
    ON foi.product_key = p.product_key
INNER JOIN dbo.dim_product_categories pc
    ON p.category_key = pc.category_key
INNER JOIN dbo.dim_date d
    ON foi.date_id = d.date_id
WHERE
    foi.price_per_kg IS NOT NULL
    AND (dest.valid_to IS NULL OR dest.valid_to >= CAST(GETDATE() AS DATE))
    AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
    AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
GROUP BY
    d.[year],
    d.[month],
    dest.province_key,
    dest.province_name,
    pc.category_key,
    pc.category_name;
GO


/* ============================================================
   2.3 PROFIL NEGOSIASI VS TRANSAKSI PER KATEGORI
   ============================================================ */
CREATE OR ALTER VIEW dbo.v_profil_negosiasi_transaksi_kategori AS
WITH negosiasi_kategori AS (
    SELECT
        pc.category_key,
        pc.category_name,

        COUNT(fn.negotiation_id) AS total_negotiations,
        SUM(ISNULL(fn.agreed_quantity_kg, 0)) AS total_agreed_quantity_kg,

        AVG(fn.initial_offered_price_per_kg) AS avg_initial_offered_price_per_kg,
        AVG(fn.agreed_price_per_kg) AS avg_agreed_price_per_kg,
        AVG(fn.price_difference_per_kg) AS avg_price_difference_per_kg,

        MIN(fn.price_difference_per_kg) AS min_price_difference_per_kg,
        MAX(fn.price_difference_per_kg) AS max_price_difference_per_kg
    FROM dbo.fact_negotiations fn
    INNER JOIN dbo.dim_products p
        ON fn.product_key = p.product_key
    INNER JOIN dbo.dim_product_categories pc
        ON p.category_key = pc.category_key
    WHERE
        (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
        AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
    GROUP BY
        pc.category_key,
        pc.category_name
),
transaksi_kategori AS (
    SELECT
        pc.category_key,
        pc.category_name,

        COUNT(foi.order_item_id) AS total_order_items,
        SUM(ISNULL(foi.quantity_kg, 0)) AS total_transaction_volume_kg,
        SUM(ISNULL(foi.total_amount, 0)) AS total_transaction_value,

        AVG(foi.price_per_kg) AS avg_transaction_price_per_kg,
        MIN(foi.price_per_kg) AS min_transaction_price_per_kg,
        MAX(foi.price_per_kg) AS max_transaction_price_per_kg
    FROM dbo.fact_order_items foi
    INNER JOIN dbo.dim_products p
        ON foi.product_key = p.product_key
    INNER JOIN dbo.dim_product_categories pc
        ON p.category_key = pc.category_key
    WHERE
        (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
        AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE))
    GROUP BY
        pc.category_key,
        pc.category_name
),
base AS (
    SELECT
        COALESCE(n.category_key, t.category_key) AS category_key,
        COALESCE(n.category_name, t.category_name) AS category_name,

        ISNULL(n.total_negotiations, 0) AS total_negotiations,
        ISNULL(n.total_agreed_quantity_kg, 0) AS total_agreed_quantity_kg,

        n.avg_initial_offered_price_per_kg,
        n.avg_agreed_price_per_kg,
        n.avg_price_difference_per_kg,
        n.min_price_difference_per_kg,
        n.max_price_difference_per_kg,

        ISNULL(t.total_order_items, 0) AS total_order_items,
        ISNULL(t.total_transaction_volume_kg, 0) AS total_transaction_volume_kg,
        ISNULL(t.total_transaction_value, 0) AS total_transaction_value,

        t.avg_transaction_price_per_kg,
        t.min_transaction_price_per_kg,
        t.max_transaction_price_per_kg,

        CAST(
            ROUND(
                1.0 * ISNULL(n.total_negotiations, 0)
                / NULLIF(ISNULL(t.total_order_items, 0), 0),
                4
            ) AS DECIMAL(18,4)
        ) AS negotiation_to_order_ratio,

        CAST(
            ROUND(
                1.0 * ISNULL(n.total_agreed_quantity_kg, 0)
                / NULLIF(ISNULL(t.total_transaction_volume_kg, 0), 0),
                4
            ) AS DECIMAL(18,4)
        ) AS negotiated_to_transaction_volume_ratio,

        CAST(
            ROUND(
                100.0 * ABS(ISNULL(n.avg_price_difference_per_kg, 0))
                / NULLIF(n.avg_initial_offered_price_per_kg, 0),
                2
            ) AS DECIMAL(10,2)
        ) AS price_gap_pct
    FROM negosiasi_kategori n
    FULL OUTER JOIN transaksi_kategori t
        ON n.category_key = t.category_key
)
SELECT
    category_key,
    category_name,

    total_negotiations,
    total_agreed_quantity_kg,

    avg_initial_offered_price_per_kg,
    avg_agreed_price_per_kg,
    avg_price_difference_per_kg,
    min_price_difference_per_kg,
    max_price_difference_per_kg,

    total_order_items,
    total_transaction_volume_kg,
    total_transaction_value,

    avg_transaction_price_per_kg,
    min_transaction_price_per_kg,
    max_transaction_price_per_kg,

    negotiation_to_order_ratio,
    negotiated_to_transaction_volume_ratio,
    price_gap_pct,

    CAST(
        ROUND(
            ISNULL(negotiation_to_order_ratio, 0) * 100
            + ISNULL(price_gap_pct, 0),
            2
        ) AS DECIMAL(10,2)
    ) AS market_pressure_score,

    CASE
        WHEN ISNULL(negotiation_to_order_ratio, 0) >= 0.50
             AND ISNULL(price_gap_pct, 0) >= 10
            THEN 'Tekanan Tinggi'
        WHEN ISNULL(negotiation_to_order_ratio, 0) >= 0.25
             OR ISNULL(price_gap_pct, 0) >= 5
            THEN 'Perlu Dipantau'
        ELSE 'Normal'
    END AS market_pressure_status
FROM base;
GO

CREATE OR ALTER VIEW dbo.v_boxplot_harga_wilayah AS
SELECT
    d.[year],
    d.[month],
    d.[year] * 100 + d.[month] AS year_month_key,

    dest.province_key,
    dest.province_name,

    pc.category_key,
    pc.category_name,

    foi.order_item_id,
    foi.price_per_kg,
    foi.quantity_kg,
    foi.total_amount
FROM dbo.fact_order_items foi
INNER JOIN dbo.dim_province dest
    ON foi.destination_province_key = dest.province_key
INNER JOIN dbo.dim_products p
    ON foi.product_key = p.product_key
INNER JOIN dbo.dim_product_categories pc
    ON p.category_key = pc.category_key
INNER JOIN dbo.dim_date d
    ON foi.date_id = d.date_id
WHERE
    foi.price_per_kg IS NOT NULL
    AND (dest.valid_to IS NULL OR dest.valid_to >= CAST(GETDATE() AS DATE))
    AND (p.valid_to IS NULL OR p.valid_to >= CAST(GETDATE() AS DATE))
    AND (pc.valid_to IS NULL OR pc.valid_to >= CAST(GETDATE() AS DATE));
GO


SELECT TOP 10 * FROM dbo.v_volatilitas_harga;
SELECT TOP 10 * FROM dbo.v_profil_negosiasi_transaksi_kategori;
SELECT TOP 10 * FROM dbo.v_neraca_surplus_defisit;
SELECT TOP 10 * FROM dbo.v_aliran_pangan;
SELECT TOP 10 * FROM dbo.v_dependency_index;
SELECT TOP 10 * FROM dbo.v_dim_month;


