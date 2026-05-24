CREATE DATABASE warehouse;

CREATE TABLE dim_province (
    province_key INT PRIMARY KEY IDENTITY(1,1),
    province_id INT NOT NULL,
    province_name VARCHAR(255) NOT NULL,
    valid_from DATE,
    valid_to DATE
);

CREATE TABLE dim_order_status (
    order_status_id INT PRIMARY KEY,
    status_code VARCHAR(50) NOT NULL
);

CREATE TABLE dim_product_categories (
        category_key INT PRIMARY KEY IDENTITY(1,1),
        parent_category_key INT NULL,
        category_id INT NOT NULL,
        category_name VARCHAR(255) NOT NULL,
        valid_from DATE,
        valid_to DATE,

        CONSTRAINT FK_category_parent FOREIGN KEY (parent_category_key) REFERENCES dim_product_categories(category_key)
);

CREATE TABLE dim_products (
    product_key INT PRIMARY KEY IDENTITY(1,1),
    category_key INT NOT NULL,  
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    is_active INT NOT NULL,
    valid_from DATE,
    valid_to DATE,

    CONSTRAINT FK_dim_products_category FOREIGN KEY (category_key) REFERENCES dim_product_categories(category_key)  -- Referensi ke primary key
);

CREATE TABLE dim_users (
    user_key INT PRIMARY KEY IDENTITY(1,1),
    province_key INT NOT NULL,
    user_id INT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    farm_name VARCHAR(255),
    status VARCHAR(20) NOT NULL,
    valid_from DATE,
    valid_to DATE,

    CONSTRAINT FK_dim_users_province FOREIGN KEY (province_key) REFERENCES dim_province(province_key)
);

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_week INT NOT NULL,
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);

CREATE TABLE fact_negotiations (
    negotiations_id INT PRIMARY KEY IDENTITY(1,1),
    buyer_key INT NOT NULL,
    seller_key INT NOT NULL,
    product_key INT NOT NULL,
    initial_offered_price DECIMAL(18,2),
    agreed_price DECIMAL(18,2),
    final_status VARCHAR(50),
    price_difference DECIMAL(18,2),
    agreed_quantity_kg DECIMAL(18,2),
    total_chat_turns INT,

    CONSTRAINT FK_fact_negotiations_buyer FOREIGN KEY (buyer_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_negotiations_seller FOREIGN KEY (seller_key) REFERENCES dim_users(user_key),
    CONSTRAINT FK_fact_negotiations_product FOREIGN KEY (product_key) REFERENCES dim_products(product_key)
);

CREATE TABLE dim_contract_status (
    contract_status_id INT PRIMARY KEY,
    status_code VARCHAR(50) NOT NULL,
);

CREATE TABLE fact_order_items (
    order_item_id BIGINT PRIMARY KEY,           
    date_id INT NOT NULL,
    buyer_key INT NOT NULL,
    seller_key INT NOT NULL,
    destination_province_key INT NOT NULL,
    origin_province_key INT NOT NULL,
    product_key INT NOT NULL,
    order_status_id INT NOT NULL,
    quantity_kg DECIMAL(18,2),
    unit_price DECIMAL(18,2),
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
        FOREIGN KEY (order_status_id) REFERENCES dim_order_status(order_status_id)
);

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
