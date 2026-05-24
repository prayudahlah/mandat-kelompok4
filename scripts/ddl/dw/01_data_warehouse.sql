-- ==============================================================================
-- Penjelasan Tipe Slowly Changing Dimension (SCD):
-- ==============================================================================
-- SCD Type 0: Data statis (static dimension), data tidak pernah berubah sejak dibuat.
--             Contoh: Dimensi Date dan Dimensi Status.
-- SCD Type 1: Data historis ditimpa (overwrite) dengan data baru. Sejarah perubahan hilang.
-- SCD Type 2: Menyimpan sejarah perubahan dengan menyisipkan baris (record) baru.
--             SCD Type 2 di Pentaho diimplementasikan menggunakan:
--             1. Surrogate Key (auto-increment)
--             2. Kolom 'version' (versi ke-1, 2, 3)
--             3. Kolom 'valid_from' (tanggal mulai aktif)
--             4. Kolom 'valid_to' (tanggal tidak aktif/kadaluwarsa)
-- ==============================================================================

CREATE DATABASE warehouse;
GO
USE warehouse;
GO

-- ==========================================
-- DROP ALL TABLES (Hapus tabel lama jika ada)
-- Harus urut: Fact Tables dihapus duluan karena ada Foreign Key
-- ==========================================
DROP TABLE IF EXISTS fact_contracts;
DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS fact_negotiations;

DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_product_categories;
DROP TABLE IF EXISTS dim_users;
DROP TABLE IF EXISTS dim_province;
DROP TABLE IF EXISTS dim_order_item_status;
DROP TABLE IF EXISTS dim_contract_status;
DROP TABLE IF EXISTS dim_date;
GO

-- ==========================================
-- SCD Type 2
-- ==========================================
CREATE TABLE dim_province (
    province_key INT PRIMARY KEY IDENTITY(0,1),
    province_id INT NOT NULL DEFAULT 0,
    province_name VARCHAR(255) NOT NULL DEFAULT 'Unknown',
    version INT,
    valid_from DATE DEFAULT '1900-01-01',
    valid_to DATE DEFAULT '2200-01-01'
);

-- ==========================================
-- SCD Type 0 (Static Dimension)
-- ==========================================
CREATE TABLE dim_order_item_status (
    order_item_status_id INT PRIMARY KEY,
    status_code VARCHAR(50) NOT NULL
);

-- ==========================================
-- SCD Type 2
-- ==========================================
CREATE TABLE dim_product_categories (
        category_key INT PRIMARY KEY IDENTITY(0,1),
        parent_category_key INT NULL,
        category_id INT NOT NULL DEFAULT 0,
        category_name VARCHAR(255) NOT NULL DEFAULT 'Unknown',
        version INT,
        valid_from DATE DEFAULT '1900-01-01',
        valid_to DATE DEFAULT '2200-01-01'

        CONSTRAINT FK_category_parent FOREIGN KEY (parent_category_key) REFERENCES dim_product_categories(category_key)
);

-- ==========================================
-- SCD Type 2
-- ==========================================
CREATE TABLE dim_products (
    product_key INT PRIMARY KEY IDENTITY(0,1),
    category_key INT NOT NULL DEFAULT 0,  
    product_id INT NOT NULL DEFAULT 0,
    product_name VARCHAR(255) NOT NULL DEFAULT 'Unknown',
    version INT,
    valid_from DATE DEFAULT '1900-01-01',
    valid_to DATE DEFAULT '2200-01-01'

    CONSTRAINT FK_dim_products_category FOREIGN KEY (category_key) REFERENCES dim_product_categories(category_key)
);

-- ==========================================
-- SCD Type 2
-- ==========================================
CREATE TABLE dim_users (
    user_key INT PRIMARY KEY IDENTITY(0,1),
    province_key INT DEFAULT 0,
    user_id INT NOT NULL DEFAULT 0,
    full_name VARCHAR(255) NOT NULL DEFAULT 'Unknown',
    role VARCHAR(50) NOT NULL DEFAULT 'Unknown',
    farm_name VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'Unknown',
    version INT,
    valid_from DATE DEFAULT '1900-01-01',
    valid_to DATE DEFAULT '2200-01-01'

    CONSTRAINT FK_dim_users_province FOREIGN KEY (province_key) REFERENCES dim_province(province_key)
);

-- ==========================================
-- SCD Type 0 (Static Dimension)
-- ==========================================
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_week INT NOT NULL,
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);

-- ==========================================
-- FACT TABLE
-- ==========================================
CREATE TABLE fact_negotiations (
    negotiation_id INT PRIMARY KEY,
    buyer_key INT NOT NULL,
    seller_key INT NOT NULL,
    product_key INT NOT NULL,
    initial_offered_price_per_kg DECIMAL(18,2),
    agreed_price_per_kg          DECIMAL(18,2),
    status                VARCHAR(50),
    price_difference_per_kg      DECIMAL(18,2),
    agreed_quantity_kg DECIMAL(18,2),

    CONSTRAINT FK_fact_negotiations_buyer FOREIGN KEY (buyer_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_negotiations_seller FOREIGN KEY (seller_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_negotiations_product FOREIGN KEY (product_key) REFERENCES dim_products(product_key)
);

-- ==========================================
-- SCD Type 0 (Static Dimension)
-- ==========================================
CREATE TABLE dim_contract_status (
    contract_status_id INT PRIMARY KEY,
    status_code VARCHAR(50) NOT NULL
);

-- ==========================================
-- FACT TABLE
-- ==========================================
CREATE TABLE fact_order_items (
    order_item_id BIGINT PRIMARY KEY,           
    date_id INT NOT NULL,
    buyer_key INT NOT NULL,
    seller_key INT NOT NULL,
    destination_province_key INT NOT NULL,
    origin_province_key INT NOT NULL,
    product_key INT NOT NULL,
    order_item_status_id INT NOT NULL,
    quantity_kg DECIMAL(18,2),
    price_per_kg DECIMAL(18,2),
    discount DECIMAL(18,2),
    total_amount DECIMAL(18,2),
    is_interprovince INT,

    CONSTRAINT FK_fact_order_items_date 
        FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_order_items_buyer 
        FOREIGN KEY (buyer_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_order_items_seller 
        FOREIGN KEY (seller_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_order_items_dest_province 
        FOREIGN KEY (destination_province_key) REFERENCES dim_province(province_key),
    CONSTRAINT FK_fact_order_items_origin_province 
        FOREIGN KEY (origin_province_key) REFERENCES dim_province(province_key),
    CONSTRAINT FK_fact_order_items_product 
        FOREIGN KEY (product_key) REFERENCES dim_products(product_key),
    CONSTRAINT FK_fact_order_items_order_status 
        FOREIGN KEY (order_item_status_id) REFERENCES dim_order_item_status(order_item_status_id)
);

-- ==========================================
-- FACT TABLE
-- ==========================================
CREATE TABLE fact_contracts (
    contract_id BIGINT PRIMARY KEY,             
    start_date_id INT NOT NULL,
    end_date_id INT NOT NULL,
    buyer_key INT NOT NULL,
    seller_key INT NOT NULL,
    destination_province_key INT NOT NULL,
    origin_province_key INT NOT NULL,
    total_amount DECIMAL(18,2),
    contract_status_id INT NOT NULL,            

    CONSTRAINT FK_fact_contracts_start_date 
        FOREIGN KEY (start_date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_contracts_end_date 
        FOREIGN KEY (end_date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_contracts_buyer 
        FOREIGN KEY (buyer_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_contracts_seller 
        FOREIGN KEY (seller_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_contracts_dest_province 
        FOREIGN KEY (destination_province_key) REFERENCES dim_province(province_key),
    CONSTRAINT FK_fact_contracts_origin_province 
        FOREIGN KEY (origin_province_key) REFERENCES dim_province(province_key),
    CONSTRAINT FK_fact_contracts_status 
        FOREIGN KEY (contract_status_id) REFERENCES dim_contract_status(contract_status_id)
);
GO

-- ==========================================
-- INDEXES (Natural Key Lookup)
-- ==========================================
CREATE INDEX IX_dim_users_user_id ON dim_users(user_id);
CREATE INDEX IX_dim_province_province_id ON dim_province(province_id);
CREATE INDEX IX_dim_products_product_id ON dim_products(product_id);
GO
