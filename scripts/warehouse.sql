CREATE TABLE dim_user (
    user_id INT PRIMARY KEY,
    province_id INT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    farm_name VARCHAR(255),
    status VARCHAR(20) NOT NULL
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    category_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    is_active INT NOT NULL  
);

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day_of_week INT NOT NULL,
    is_holiday BOOLEAN NOT NULL,
);

CREATE TABLE fact_negotiations (
    negotiations_id INT IDENTITY(1,1) PRIMARY KEY,
    start_date_id INT NOT NULL,
    end_date_id INT NOT NULL,
    buyer_id INT NOT NULL,
    seller_id INT NOT NULL,
    product_id INT NOT NULL,
    initial_offered_price DECIMAL(18,2),
    agreed_price DECIMAL(18,2),
    final_status VARCHAR(50),
    price_difference DECIMAL(18,2),
    agreed_quantity_kg DECIMAL(18,2),
    negotiations_duration_hours DECIMAL(10,2),
    total_chat_turns INT,
    
    CONSTRAINT FK_fact_negotiations_start_date FOREIGN KEY (start_date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_negotiations_end_date FOREIGN KEY (end_date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_negotiations_buyer FOREIGN KEY (buyer_id) REFERENCES dim_user(user_id),
    CONSTRAINT FK_fact_negotiations_seller FOREIGN KEY (seller_id) REFERENCES dim_user(user_id),
    CONSTRAINT FK_fact_negotiations_product FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

CREATE TABLE fact_sales (
    sales_id INT IDENTITY(1,1) PRIMARY KEY,
    date_id INT NOT NULL,
    buyer_id INT NOT NULL,
    seller_id INT NOT NULL,
    destination_province_id INT NOT NULL,
    origin_province_id INT NOT NULL,
    product_id INT NOT NULL,
    order_status_id INT NOT NULL,
    quantity_kg DECIMAL(18,2),
    unit_price DECIMAL(18,2),
    discount DECIMAL(18,2),
    total_amount DECIMAL(18,2),
    is_interprovince INT,  
    
    CONSTRAINT FK_fact_sales_date FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_sales_buyer FOREIGN KEY (buyer_id) REFERENCES dim_user(user_id),
    CONSTRAINT FK_fact_sales_seller FOREIGN KEY (seller_id) REFERENCES dim_user(user_id),
    CONSTRAINT FK_fact_sales_product FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
);

