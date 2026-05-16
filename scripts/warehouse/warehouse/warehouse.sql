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
