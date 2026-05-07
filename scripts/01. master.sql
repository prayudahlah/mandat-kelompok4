CREATE SCHEMA IF NOT EXISTS master;

-- 1. Users
DO $$
BEGIN
    SET LOCAL search_path TO master;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE master.user_role AS ENUM ('seller', 'buyer', 'admin');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE master.user_status AS ENUM ('active', 'inactive', 'suspended');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS master.users (
    id            BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    full_name     VARCHAR(100)       NOT NULL,
    email         VARCHAR(100)       NOT NULL UNIQUE,
    phone         VARCHAR(20)        NOT NULL,
    password_hash VARCHAR(255)       NOT NULL,
    role          master.user_role   NOT NULL,
    status        master.user_status NOT NULL DEFAULT 'active',
    deleted_at    TIMESTAMP                   DEFAULT NULL,
    created_at    TIMESTAMP                   DEFAULT CURRENT_TIMESTAMP
);

-- 2. Seller Profiles
-- FK: user_id -> master.users.id
-- FK: city_id -> reference.cities.id
-- FK: province_id -> reference.provinces.id

DO $$
BEGIN
    SET LOCAL search_path TO master;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'seller_profile_status') THEN
        CREATE TYPE master.seller_profile_status AS ENUM ('active', 'inactive', 'suspended');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS master.seller_profiles (
    id               BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id          BIGINT                       NOT NULL UNIQUE,
    farm_name        VARCHAR(150)                 NOT NULL,
    land_certificate VARCHAR(100),
    address          TEXT                         NOT NULL,
    city_id          BIGINT                       NOT NULL,
    province_id      BIGINT                       NOT NULL,
    status           master.seller_profile_status NOT NULL DEFAULT 'active',
    deleted_at       TIMESTAMP                             DEFAULT NULL,
    created_at       TIMESTAMP                             DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sp_user FOREIGN KEY (user_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_sp_city FOREIGN KEY (city_id)
        REFERENCES reference.cities (id),
    CONSTRAINT fk_sp_province FOREIGN KEY (province_id)
        REFERENCES reference.provinces (id)
);

-- 3. Products
-- FK: seller_id -> master.users.id
-- FK: category_id -> reference.product_categories.id
-- FK: unit_id -> reference.units.id
CREATE TABLE IF NOT EXISTS master.products (
    id             BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    seller_id      BIGINT         NOT NULL,
    category_id    BIGINT         NOT NULL,
    name           VARCHAR(150)   NOT NULL,
    description    TEXT,
    unit_id        INT            NOT NULL,
    min_order_qty  DECIMAL(10, 2) NOT NULL DEFAULT 1,
    price_per_unit DECIMAL(12, 2) NOT NULL,
    stock_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
    is_negotiable  BOOLEAN        NOT NULL DEFAULT FALSE,
    deleted_at     TIMESTAMP               DEFAULT NULL,
    created_at     TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_prod_seller FOREIGN KEY (seller_id)
        REFERENCES master.users (id),
    CONSTRAINT fk_prod_category FOREIGN KEY (category_id)
        REFERENCES reference.product_categories (id),
    CONSTRAINT fk_prod_unit FOREIGN KEY (unit_id)
        REFERENCES reference.units (id)
);