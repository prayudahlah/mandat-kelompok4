-- =====================================================
-- SCHEMA STAGING
-- =====================================================
CREATE SCHEMA IF NOT EXISTS staging;

-- =====================================================
-- 1. STAGING PROVINSI
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_provinces (
    province_id BIGINT PRIMARY KEY,
    province_name VARCHAR(255) NOT NULL,
    deleted_at TIMESTAMP
);

-- =====================================================
-- 2. STAGING USERS
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_users (
    user_id BIGINT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('seller', 'buyer', 'admin')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'inactive', 'suspended')),
    deleted_at TIMESTAMP
);

-- =====================================================
-- 3. STAGING SELLER PROFILES
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_seller_profiles (
    user_id BIGINT PRIMARY KEY,
    farm_name VARCHAR(255) NOT NULL,
    province_id BIGINT NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_seller_profile_user 
        FOREIGN KEY (user_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT fk_seller_profile_province 
        FOREIGN KEY (province_id) REFERENCES staging.stg_provinces(province_id)
);

-- =====================================================
-- 4. STAGING KATEGORI PRODUK
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_product_categories (
    category_id BIGINT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    parent_id BIGINT,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_id) REFERENCES staging.stg_product_categories(category_id)
);

-- =====================================================
-- 5. STAGING PRODUK
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    price_per_unit DECIMAL(12, 2) NOT NULL CHECK (price_per_unit > 0),
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_product_category 
        FOREIGN KEY (category_id) REFERENCES staging.stg_product_categories(category_id),
    CONSTRAINT fk_product_seller 
        FOREIGN KEY (seller_id) REFERENCES staging.stg_users(user_id)
);

-- =====================================================
-- 6. STAGING SHIPMENT (dibuat dulu karena order dan contract membutuhkannya)
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_shipments (
    shipment_id BIGINT PRIMARY KEY,
    destination_province_id BIGINT NOT NULL,
    origin_province_id BIGINT NOT NULL,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_shipment_destination_province 
        FOREIGN KEY (destination_province_id) REFERENCES staging.stg_provinces(province_id),
    CONSTRAINT fk_shipment_origin_province 
        FOREIGN KEY (origin_province_id) REFERENCES staging.stg_provinces(province_id),
    CONSTRAINT chk_shipment_dates CHECK (
        delivered_at IS NULL OR 
        shipped_at IS NULL OR 
        delivered_at >= shipped_at
    )
);

-- =====================================================
-- 7. STAGING ORDER (memiliki shipment_id)
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_orders (
    order_id BIGINT PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    shipment_id BIGINT NOT NULL UNIQUE,
    seller_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_order_shipment 
        FOREIGN KEY (shipment_id) REFERENCES staging.stg_shipments(shipment_id),
    CONSTRAINT fk_order_seller 
        FOREIGN KEY (seller_id) REFERENCES staging.stg_users(user_id)
);

-- =====================================================
-- 8. STAGING ORDER ITEMS
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_order_items (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12, 2) NOT NULL CHECK (unit_price > 0),
    discount DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
    subtotal DECIMAL(14, 2) NOT NULL CHECK (subtotal >= 0),
    order_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_order_item_order 
        FOREIGN KEY (order_id) REFERENCES staging.stg_orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_product 
        FOREIGN KEY (product_id) REFERENCES staging.stg_products(product_id),
    CONSTRAINT fk_order_item_seller 
        FOREIGN KEY (seller_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT fk_order_item_buyer 
        FOREIGN KEY (buyer_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT chk_order_item_subtotal CHECK (subtotal = (quantity * unit_price) - discount)
);

-- =====================================================
-- 9. STAGING NEGOSIASI
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_negotiations (
    negotiation_id BIGINT PRIMARY KEY,
    seller_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    product_id BIGINT,
    agreed_price DECIMAL(12, 2) NOT NULL CHECK (agreed_price > 0),
    agreed_quantity_kg DECIMAL(10, 2) NOT NULL CHECK (agreed_quantity_kg > 0),
    status VARCHAR(50) NOT NULL CHECK (status IN ('accepted', 'canceled', 'rejected', 'ongoing')),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    initial_offer_price DECIMAL(12, 2) CHECK (initial_offer_price > 0),
    total_chat_turns INT NOT NULL DEFAULT 0 CHECK (total_chat_turns >= 0),
    duration_hours DECIMAL(10, 2) CHECK (duration_hours >= 0),
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_negotiation_seller 
        FOREIGN KEY (seller_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT fk_negotiation_buyer 
        FOREIGN KEY (buyer_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT fk_negotiation_product 
        FOREIGN KEY (product_id) REFERENCES staging.stg_products(product_id),
    CONSTRAINT chk_negotiation_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_negotiation_buyer_seller CHECK (buyer_id <> seller_id)
);

-- =====================================================
-- 10. STAGING NEGOSIASI CHAT
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_negotiation_chats (
    chat_id BIGINT PRIMARY KEY,
    negotiation_id BIGINT NOT NULL,
    turn_order INT NOT NULL CHECK (turn_order >= 1),
    turn_owner VARCHAR(20) NOT NULL CHECK (turn_owner IN ('seller', 'buyer')),
    offer_price DECIMAL(12, 2) NOT NULL CHECK (offer_price > 0),
    quantity_offer DECIMAL(10, 2) NOT NULL CHECK (quantity_offer > 0),
    created_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_chat_negotiation 
        FOREIGN KEY (negotiation_id) REFERENCES staging.stg_negotiations(negotiation_id) ON DELETE CASCADE
);

-- =====================================================
-- 11. STAGING CONTRACT (memiliki shipment_id)
-- =====================================================
CREATE TABLE IF NOT EXISTS staging.stg_contracts (
    contract_id BIGINT PRIMARY KEY,
    buyer_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL UNIQUE,
    total_amount DECIMAL(14, 2) NOT NULL CHECK (total_amount > 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    frequency VARCHAR(50) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'specific_dates')),
    contract_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT fk_contract_buyer 
        FOREIGN KEY (buyer_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT fk_contract_seller 
        FOREIGN KEY (seller_id) REFERENCES staging.stg_users(user_id),
    CONSTRAINT fk_contract_shipment 
        FOREIGN KEY (shipment_id) REFERENCES staging.stg_shipments(shipment_id),
    CONSTRAINT chk_contract_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_contract_buyer_seller CHECK (buyer_id <> seller_id)
);
