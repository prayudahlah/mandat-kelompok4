-- =====================================================
-- DATABASE STAGING
-- =====================================================
CREATE DATABASE StagingDB;
USE StagingDB;
GO

-- =====================================================
-- 1. STAGING PROVINSI
-- =====================================================
CREATE TABLE stg_provinces (
    province_id BIGINT PRIMARY KEY,
    province_name VARCHAR(255) NOT NULL,
    deleted_at DATETIME2
);
GO

-- =====================================================
-- 2. STAGING USERS
-- =====================================================
CREATE TABLE stg_users (
    user_id BIGINT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    deleted_at DATETIME2,
    
    CONSTRAINT chk_users_role CHECK (role IN ('seller', 'buyer', 'admin')),
    CONSTRAINT chk_users_status CHECK (status IN ('active', 'inactive', 'suspended'))
);
GO

-- =====================================================
-- 3. STAGING SELLER PROFILES
-- =====================================================
CREATE TABLE stg_seller_profiles (
    user_id BIGINT PRIMARY KEY,
    farm_name VARCHAR(255) NOT NULL,
    province_id BIGINT NOT NULL,
    deleted_at DATETIME2,
    
    CONSTRAINT fk_seller_profile_user 
        FOREIGN KEY (user_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_seller_profile_province 
        FOREIGN KEY (province_id) REFERENCES stg_provinces(province_id)
);
GO

-- =====================================================
-- 4. STAGING KATEGORI PRODUK
-- =====================================================
CREATE TABLE stg_product_categories (
    category_id BIGINT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    parent_id BIGINT,
    deleted_at DATETIME2,
    
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_id) REFERENCES stg_product_categories(category_id)
);
GO


-- =====================================================
-- 4,5. UNIT
-- =====================================================
CREATE TABLE stg_units (
    id         INT PRIMARY KEY,
    name       VARCHAR(30) UNIQUE NOT NULL,
    deleted_at DATETIME2
);


-- =====================================================
-- 5. STAGING PRODUK
-- =====================================================
CREATE TABLE stg_products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category_id BIGINT NOT NULL,
    unit_id INT NOT NULL,
    seller_id BIGINT NOT NULL,
    price_per_unit DECIMAL(12, 2) NOT NULL,
    deleted_at DATETIME2,
    
    CONSTRAINT fk_product_category 
        FOREIGN KEY (category_id) REFERENCES stg_product_categories(category_id),
    CONSTRAINT fk_product_seller 
        FOREIGN KEY (seller_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_product_unit 
        FOREIGN KEY (unit_id) REFERENCES stg_units(id),
    CONSTRAINT chk_products_price CHECK (price_per_unit > 0)
);
GO

-- =====================================================
-- 6. STAGING SHIPMENT
-- =====================================================
CREATE TABLE stg_shipments (
    shipment_id BIGINT PRIMARY KEY,
    destination_province_id BIGINT NOT NULL,
    shipped_at DATETIME2,
    delivered_at DATETIME2,
    
    CONSTRAINT fk_shipment_destination_province 
        FOREIGN KEY (destination_province_id) REFERENCES stg_provinces(province_id),
    CONSTRAINT chk_shipment_dates CHECK (
        delivered_at IS NULL OR 
        shipped_at IS NULL OR 
        delivered_at >= shipped_at
    )
);
GO

-- =====================================================
-- 7. STAGING ORDER
-- =====================================================
CREATE TABLE stg_orders (
    order_id BIGINT PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL,
    shipment_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    created_at DATETIME2 NOT NULL,

    CONSTRAINT fk_order_shipment 
        FOREIGN KEY (shipment_id) REFERENCES stg_shipments(shipment_id),
    CONSTRAINT fk_order_seller 
        FOREIGN KEY (seller_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_order_buyer
        FOREIGN KEY (buyer_id) REFERENCES stg_users(user_id),
    CONSTRAINT uq_orders_number UNIQUE (order_number),
    CONSTRAINT uq_orders_shipment UNIQUE (shipment_id)
);
GO

-- =====================================================
-- 8. STAGING ORDER ITEMS
-- =====================================================
CREATE TABLE stg_order_items (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    unit_id INT NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    discount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(14, 2) NOT NULL,
    order_item_status_id BIGINT NOT NULL,

    CONSTRAINT fk_order_item_order 
        FOREIGN KEY (order_id) REFERENCES stg_orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_product 
        FOREIGN KEY (product_id) REFERENCES stg_products(product_id),
    CONSTRAINT fk_order_item_unit
        FOREIGN KEY (unit_id) REFERENCES stg_units(id),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price > 0),
    CONSTRAINT chk_order_items_discount CHECK (discount >= 0),
    CONSTRAINT chk_order_items_subtotal CHECK (subtotal >= 0)
);
GO

-- =====================================================
-- 9. STAGING NEGOSIASI
-- =====================================================
CREATE TABLE stg_negotiations (
    negotiation_id BIGINT PRIMARY KEY,
    seller_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    product_id BIGINT,
    agreed_price DECIMAL(12, 2) NOT NULL,
    agreed_unit_id INT NOT NULL,
    agreed_quantity DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    initial_offer_price DECIMAL(12, 2),

    CONSTRAINT fk_negotiation_seller 
        FOREIGN KEY (seller_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_negotiation_buyer 
        FOREIGN KEY (buyer_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_negotiation_product 
        FOREIGN KEY (product_id) REFERENCES stg_products(product_id),
    CONSTRAINT fk_negotiation_agreed_unit 
        FOREIGN KEY (agreed_unit_id) REFERENCES stg_units(id),
    CONSTRAINT chk_negotiations_agreed_price CHECK (agreed_price > 0),
    CONSTRAINT chk_negotiations_agreed_quantity CHECK (agreed_quantity > 0),
    CONSTRAINT chk_negotiations_status CHECK (status IN ('accepted', 'canceled', 'rejected', 'ongoing')),
    CONSTRAINT chk_negotiations_initial_price CHECK (initial_offer_price > 0),
    CONSTRAINT chk_negotiations_buyer_seller CHECK (buyer_id <> seller_id)
);
GO

-- =====================================================
-- 10. STAGING CONTRACT
-- =====================================================
CREATE TABLE stg_contracts (
    contract_id BIGINT PRIMARY KEY,
    buyer_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL,
    total_amount DECIMAL(14, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    frequency VARCHAR(50) NOT NULL,
    contract_status_id BIGINT NOT NULL,

    CONSTRAINT fk_contract_buyer 
        FOREIGN KEY (buyer_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_contract_seller 
        FOREIGN KEY (seller_id) REFERENCES stg_users(user_id),
    CONSTRAINT fk_contract_shipment 
        FOREIGN KEY (shipment_id) REFERENCES stg_shipments(shipment_id),
    CONSTRAINT uq_contracts_shipment UNIQUE (shipment_id),
    CONSTRAINT chk_contracts_total_amount CHECK (total_amount > 0),
    CONSTRAINT chk_contracts_frequency CHECK (frequency IN ('daily', 'weekly', 'specific_dates')),
    CONSTRAINT chk_contracts_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_contracts_buyer_seller CHECK (buyer_id <> seller_id)
);
GO
