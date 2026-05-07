CREATE SCHEMA IF NOT EXISTS transaction;

-- 1. Negosiasi
-- FK: seller_id -> master.users.id
-- FK: buyer_id -> master.users.id
-- FK: product_id -> master.products.id (nullable)
DO $$
BEGIN
    SET LOCAL search_path TO transaction;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'negotiation_status_enum') THEN
        CREATE TYPE transaction.negotiation_status_enum AS ENUM ('accepted', 'canceled', 'rejected', 'ongoing');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS transaction.negotiations (
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    seller_id             BIGINT                              NOT NULL,
    buyer_id              BIGINT                              NOT NULL,
    product_id            BIGINT                              NULL,
    agreed_price_offer    DECIMAL(10, 2)                      NOT NULL,
    agreed_unit_id        INT                                 NOT NULL,
    agreed_quantity_offer DECIMAL(10, 2)                      NOT NULL,
    valid_until           TIMESTAMP                           NOT NULL,
    status                transaction.negotiation_status_enum NOT NULL DEFAULT 'ongoing',
    created_at            TIMESTAMP                                    DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP                                    DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_negotiations_seller FOREIGN KEY (seller_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_negotiations_buyer FOREIGN KEY (buyer_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_negotiations_product FOREIGN KEY (product_id)
        REFERENCES master.products (id),
    CONSTRAINT fk_negotiations_unit FOREIGN KEY (agreed_unit_id)
        REFERENCES reference.units (id),

    -- seller dan buyer tidak boleh sama
    CONSTRAINT chk_negotiation_buyer_seller_diff CHECK (buyer_id <> seller_id),

    -- agreed_quantity_offer > 0
    CONSTRAINT chk_negotiation_quantity CHECK (agreed_quantity_offer > 0),

    -- agreed_price_offer > 0
    CONSTRAINT chk_negotiation_price CHECK (agreed_price_offer > 0)
);

-- 2. Chat Negosiasi
-- FK: negotiation_id -> transaction.negotiations.id
DO $$
BEGIN
    SET LOCAL search_path TO transaction;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'turn_owner_enum') THEN
        CREATE TYPE transaction.turn_owner_enum AS ENUM ('seller', 'buyer');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS transaction.negotiation_chats (
    id             BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    negotiation_id BIGINT                      NOT NULL,
    turn_order     INT                         NOT NULL,
    turn_owner     transaction.turn_owner_enum NOT NULL,
    offer_price    DECIMAL(10, 2)              NOT NULL,
    unit_id        INT                         NOT NULL,
    quantity_offer DECIMAL(10, 2)              NOT NULL,
    description    TEXT                        NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_nd_negotiation FOREIGN KEY (negotiation_id)
        REFERENCES transaction.negotiations (id) ON DELETE CASCADE,
    CONSTRAINT fk_nd_unit FOREIGN KEY (unit_id)
        REFERENCES reference.units (id),

    -- offer_price > 0
    CONSTRAINT chk_nd_offer_price CHECK (offer_price > 0),

    -- quantity_offer > 0
    CONSTRAINT chk_nd_quantity_offer CHECK (quantity_offer > 0)
);

-- 3. Keranjang
-- FK: buyer_id -> master.users.id
CREATE TABLE IF NOT EXISTS transaction.carts (
    id         BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    buyer_id   BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_carts_buyer FOREIGN KEY (buyer_id)
        REFERENCES master.users (id) ON DELETE CASCADE
);

-- 4. Item Keranjang
-- FK: cart_id -> transaction.carts.id
-- FK: product_id -> reference.products.id
-- FK: unit_id -> reference.units.id
CREATE TABLE IF NOT EXISTS transaction.cart_items (
    id         BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    cart_id    BIGINT         NOT NULL,
    product_id BIGINT         NOT NULL,
    quantity   DECIMAL(10, 2) NOT NULL,
    unit_id    INT            NOT NULL,
    added_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id)
        REFERENCES transaction.carts (id) ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id)
        REFERENCES master.products (id),
    CONSTRAINT fk_cart_items_unit FOREIGN KEY (unit_id)
        REFERENCES reference.units (id),

    CONSTRAINT unique_cart_product_unit UNIQUE (cart_id, product_id)
);

-- 5. Checkouts
-- FK: buyer_id -> master.users.id
-- FK: checkout_status_id -> reference.checkout_statuses.id
CREATE TABLE IF NOT EXISTS transaction.checkouts (
    id                 BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    buyer_id           BIGINT         NOT NULL,
    total_amount       DECIMAL(12, 2) NOT NULL DEFAULT 0,
    shipping_address   TEXT           NOT NULL,
    checkout_status_id INT            NOT NULL,
    created_at         TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_checkouts_buyer FOREIGN KEY (buyer_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_checkouts_checkout_status FOREIGN KEY (checkout_status_id)
        REFERENCES reference.checkout_statuses (id)
);

-- 6. Pesanan
-- FK: buyer_id -> master.users.id
-- FK: order_status_id -> reference.order_statuses.id
-- FK: payment_status_id -> reference.payment_statuses.id
CREATE TABLE IF NOT EXISTS transaction.orders (
    id              BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    checkout_id     BIGINT         NOT NULL,
    order_number    VARCHAR(30)    NOT NULL UNIQUE,
    buyer_id        BIGINT         NOT NULL,
    seller_id       BIGINT         NOT NULL,
    subtotal        DECIMAL(12, 2) NOT NULL,
    order_status_id INT            NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_checkout FOREIGN KEY (checkout_id)
        REFERENCES transaction.checkouts (id) ON DELETE CASCADE,
    CONSTRAINT fk_orders_buyer FOREIGN KEY (buyer_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_orders_seller FOREIGN KEY (seller_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_orders_order_status FOREIGN KEY (order_status_id)
        REFERENCES reference.order_statuses (id)
);

-- 7. Item Pesanan
-- FK: order_id -> transaction.orders.id
-- FK: product_id -> reference.products.id
-- FK: unit_id -> reference.units.id
-- FK: negotiation_id -> transaction.negotiations.id (nullable)
CREATE TABLE IF NOT EXISTS transaction.order_items (
    id             BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id       BIGINT         NOT NULL,
    product_id     BIGINT         NOT NULL,
    quantity       DECIMAL(10, 2) NOT NULL,
    unit_id        INT            NOT NULL,
    price_per_unit DECIMAL(12, 2) NOT NULL,
    discount       DECIMAL(12, 2) DEFAULT 0,
    subtotal       DECIMAL(12, 2) NOT NULL,
    negotiation_id BIGINT         NULL,

    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES transaction.orders (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
        REFERENCES master.products (id),
    CONSTRAINT fk_order_items_unit FOREIGN KEY (unit_id)
        REFERENCES reference.units (id),
    CONSTRAINT fk_order_items_negotiation FOREIGN KEY (negotiation_id)
        REFERENCES transaction.negotiations (id)
);

-- 8. Pembayaran
-- FK: checkout_id -> transaction.checkouts.id
-- FK: payment_method_id -> reference.payment_methods.id
-- FK: payment_status_id -> reference.payment_statuses.id
CREATE TABLE IF NOT EXISTS transaction.payments (
    id                BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    checkout_id       BIGINT         NOT NULL,
    payment_method_id INT            NOT NULL,
    amount            DECIMAL(12, 2) NOT NULL,
    payment_status_id INT            NOT NULL,
    transaction_id    VARCHAR(100)   NULL,
    paid_at           TIMESTAMP      NULL,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_checkout FOREIGN KEY (checkout_id)
        REFERENCES transaction.checkouts (id),
    CONSTRAINT fk_payments_payment_method FOREIGN KEY (payment_method_id)
        REFERENCES reference.payment_methods (id),
    CONSTRAINT fk_payments_payment_status FOREIGN KEY (payment_status_id)
        REFERENCES reference.payment_statuses (id)
);

-- 9. Pengiriman
-- FK: order_id -> transaction.orders.id
-- FK: shipment_status_id -> reference.shipment_statuses.id
CREATE TABLE IF NOT EXISTS transaction.shipments (
    id                 BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id           BIGINT      NOT NULL,
    courier_name       VARCHAR(50) NULL,
    shipment_status_id INT         NOT NULL,
    shipped_date       TIMESTAMP   NULL,
    delivered_date     TIMESTAMP   NULL,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES transaction.orders (id) ON DELETE RESTRICT,
    CONSTRAINT fk_shipments_shipment_status FOREIGN KEY (shipment_status_id)
        REFERENCES reference.shipment_statuses (id),

    -- delivered_date tidak boleh lebih kecil dari shipped_date
    CONSTRAINT chk_shipment_dates CHECK (
        delivered_date IS NULL OR
        shipped_date IS NULL OR
        delivered_date >= shipped_date
        )
);

-- 10. Kontrak Kemitraan
-- FK: buyer_id -> master.users.id
-- FK: seller_id -> master.users.id
-- FK: contract_status_id -> reference.contract_statuses.id

DO $$
BEGIN
    SET LOCAL search_path TO transaction;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contract_schedule_type') THEN
        CREATE TYPE transaction.contract_schedule_type AS ENUM ('daily', 'weekly', 'specific_dates');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS transaction.contracts (
    id                 BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    buyer_id           BIGINT                             NOT NULL,
    seller_id          BIGINT                             NOT NULL,
    total_amount       DECIMAL(10, 2)                     NOT NULL,
    delivery_location  VARCHAR(255)                       NOT NULL,
    start_date         DATE                               NOT NULL,
    end_date           DATE                               NOT NULL,
    frequency          transaction.contract_schedule_type NOT NULL DEFAULT 'weekly',
    total_shipping     INT                                NOT NULL DEFAULT 0,
    description        TEXT                               NULL,
    contract_status_id INT                                NOT NULL,
    created_at         TIMESTAMP                                   DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP                                   DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_contracts_buyer FOREIGN KEY (buyer_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_contracts_seller FOREIGN KEY (seller_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_contracts_status FOREIGN KEY (contract_status_id)
        REFERENCES reference.contract_statuses (id),

    -- end_date harus >= start_date
    CONSTRAINT chk_contract_dates CHECK (end_date >= start_date),

    -- buyer dan seller tidak boleh sama
    CONSTRAINT chk_contract_buyer_seller_diff CHECK (buyer_id <> seller_id),

    -- total_amount harus positif
    CONSTRAINT chk_contract_total_amount CHECK (total_amount > 0)
);

-- 11. Produk dalam Kontrak
-- FK: contract_id -> transaction.contracts.id
-- FK: product_id -> master.products.id
-- FK: unit_id -> reference.units.id
CREATE TABLE IF NOT EXISTS transaction.contract_products (
    id             BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    contract_id    BIGINT         NOT NULL,
    product_id     BIGINT         NOT NULL,
    quantity       DECIMAL(10, 2) NOT NULL,
    unit_id        INT            NOT NULL,
    subtotal       DECIMAL(10, 2) NOT NULL,
    total_quantity DECIMAL(10, 2) NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_contract_product UNIQUE (product_id, contract_id),

    CONSTRAINT fk_cp_contract FOREIGN KEY (contract_id)
        REFERENCES transaction.contracts (id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_product FOREIGN KEY (product_id)
        REFERENCES master.products (id),
    CONSTRAINT fk_cp_unit FOREIGN KEY (unit_id)
        REFERENCES reference.units (id),

    -- Validasi quantity > 0
    CONSTRAINT chk_cp_quantity CHECK (quantity > 0),

    -- Validasi total_amount > 0
    CONSTRAINT chk_cp_total_amount CHECK (subtotal > 0)
);

-- 12. Jadwal dari Kontrak
-- FK: contract_id -> transaction.contracts.id
DO $$
BEGIN
    SET LOCAL search_path TO transaction;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contract_delivery_day') THEN
        CREATE TYPE transaction.contract_delivery_day AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS transaction.contract_schedules (
    id            BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    contract_id   BIGINT NOT NULL,
    delivery_day  transaction.contract_delivery_day,
    delivery_date DATE,
    delivery_time TIME,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cs_contract FOREIGN KEY (contract_id)
        REFERENCES transaction.contracts (id) ON DELETE CASCADE
);


