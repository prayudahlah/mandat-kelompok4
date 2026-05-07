CREATE SCHEMA transaction;

CREATE TABLE transaction.orders (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_number VARCHAR(30) NOT NULL UNIQUE,
    buyer_id BIGINT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    order_status_id INT NOT NULL,
    payment_status_id INT NOT NULL,
    
    CONSTRAINT fk_orders_buyer FOREIGN KEY (buyer_id) REFERENCES users(id),
    CONSTRAINT fk_orders_order_status FOREIGN KEY (order_status_id) REFERENCES order_statuses(id),
    CONSTRAINT fk_orders_payment_status FOREIGN KEY (payment_status_id) REFERENCES payment_statuses(id)
);

CREATE TABLE transaction.order_items (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    unit_id INT NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    discount DECIMAL(12, 2) DEFAULT 0,
    subtotal DECIMAL(12, 2) NOT NULL,
    
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_order_items_unit FOREIGN KEY (unit_id) REFERENCES units(id)
);

CREATE TABLE transaction.payments (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    payment_method_id INT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    payment_status_id INT NOT NULL,
    transaction_id VARCHAR(100) NULL,
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT,
    CONSTRAINT fk_payments_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
    CONSTRAINT fk_payments_payment_status FOREIGN KEY (payment_status_id) REFERENCES payment_statuses(id)
);

CREATE TABLE transaction.shipments (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    courier_name VARCHAR(50) NULL,
    shipment_status_id INT NOT NULL,
    shipped_date TIMESTAMP NULL,
    delivered_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT,
    CONSTRAINT fk_shipments_shipment_status FOREIGN KEY (shipment_status_id) REFERENCES shipment_statuses(id),
    
    -- delivered_date tidak boleh lebih kecil dari shipped_date
    CONSTRAINT chk_shipment_dates CHECK (
        delivered_date IS NULL OR 
        shipped_date IS NULL OR 
        delivered_date >= shipped_date
    )
);

CREATE TYPE frequency_enum AS ENUM ('daily', 'weekly', 'monthly');

CREATE TYPE contract_status_enum AS ENUM ('open', 'closed', 'cancelled', 'rejected');

CREATE TABLE transaction.contracts (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    buyer_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    delivery_location VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    frequency frequency_enum NOT NULL DEFAULT 'weekly',
    shipping_amount INT NOT NULL DEFAULT 0,
    description TEXT NULL,
    status contract_status_enum NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_contracts_buyer FOREIGN KEY (buyer_id) REFERENCES users(id),
    CONSTRAINT fk_contracts_seller 
        FOREIGN KEY (seller_id) REFERENCES users(id),
    
    -- end_date harus >= start_date
    CONSTRAINT chk_contract_dates CHECK (end_date >= start_date),
    
    -- buyer dan seller tidak boleh sama
    CONSTRAINT chk_contract_buyer_seller_diff CHECK (buyer_id <> seller_id),
    
    -- total_amount harus positif
    CONSTRAINT chk_contract_total_amount CHECK (total_amount > 0)
);

CREATE TYPE contract_product_status_enum AS ENUM ('open', 'closed', 'cancelled', 'rejected');

CREATE TABLE transaction.contract_products (
    contract_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    unit_id BIGINT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    total_quantity DECIMAL(10, 2) NULL,
    status contract_product_status_enum NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_contract_products PRIMARY KEY (contract_id, product_id),
    
    CONSTRAINT fk_cp_contract FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_cp_unit FOREIGN KEY (unit_id) REFERENCES units(id),
    
    -- Validasi quantity > 0
    CONSTRAINT chk_cp_quantity CHECK (quantity > 0),
    
    -- Validasi total_amount > 0
    CONSTRAINT chk_cp_total_amount CHECK (total_amount > 0)
);

CREATE TYPE negotiation_status_enum AS ENUM ('submitted', 'accepted', 'canceled', 'rejected', 'ongoing');

CREATE TABLE transaction.negotiations (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    seller_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    product_id BIGINT NULL,
    agreed_offer_price DECIMAL(10, 2) NOT NULL,
    agreed_unit_id INT NOT NULL,
    agreed_quantity_offer DECIMAL(10, 2) NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    status negotiation_status_enum NOT NULL DEFAULT 'submitted',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_negotiations_seller FOREIGN KEY (seller_id) REFERENCES users(id),
    CONSTRAINT fk_negotiations_buyer FOREIGN KEY (buyer_id) REFERENCES users(id),
    CONSTRAINT fk_negotiations_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_negotiations_unit FOREIGN KEY (agreed_unit_id) REFERENCES units(id),
    
    -- seller dan buyer tidak boleh sama
    CONSTRAINT chk_negotiation_buyer_seller_diff CHECK (buyer_id <> seller_id),
    
    -- agreed_quantity_offer > 0
    CONSTRAINT chk_negotiation_quantity CHECK (agreed_quantity_offer > 0),
    
    -- agreed_offer_price > 0
    CONSTRAINT chk_negotiation_price CHECK (agreed_offer_price > 0),
);

CREATE TYPE turn_owner_enum AS ENUM ('seller', 'buyer');

CREATE TABLE transaction.negotiation_details (
    negotiation_id BIGINT NOT NULL,
    turn_order INT NOT NULL,
    turn_owner turn_owner_enum NOT NULL,
    offer_price DECIMAL(10, 2) NOT NULL,
    unit_id INT NOT NULL,
    quantity_offer DECIMAL(10, 2) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_negotiation_details PRIMARY KEY (negotiation_id, turn_order),
    
    CONSTRAINT fk_nd_negotiation FOREIGN KEY (negotiation_id) REFERENCES negotiations(id) ON DELETE CASCADE,
    CONSTRAINT fk_nd_unit FOREIGN KEY (unit_id) REFERENCES units(id),
    
    -- offer_price > 0
    CONSTRAINT chk_nd_offer_price CHECK (offer_price > 0),
    
    -- quantity_offer > 0
    CONSTRAINT chk_nd_quantity_offer CHECK (quantity_offer > 0)
);

