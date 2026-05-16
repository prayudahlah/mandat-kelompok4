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
    total_chat_turns INT
);

CREATE TABLE fact_sales (
    sales_id INT IDENTITY(1,1) PRIMARY KEY,
    date_id INT NOT NULL,
    buyer_id INT NOT NULL,
    destination_province_id INT NOT NULL,
    origin_province_id INT NOT NULL,
    seller_id INT NOT NULL,
    product_id INT NOT NULL,
    order_status_id INT NOT NULL,
    quantity_kg DECIMAL(18,2),
    unit_price DECIMAL(18,2),
    discount DECIMAL(18,2),
    total_amount DECIMAL(18,2),
    is_interprovince INT
);
