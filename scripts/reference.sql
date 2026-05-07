CREATE SCHEMA reference;

CREATE TABLE reference.units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE reference.order_statuses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE reference.payment_statuses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE reference.shipment_statuses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE reference.payment_methods (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE reference.product_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT,
    FOREIGN KEY (parent_id) REFERENCES reference.product_categories(id) ON DELETE SET NULL
);

CREATE TABLE reference.provinces (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE reference.cities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL,
    province_id BIGINT NOT NULL,
    FOREIGN KEY (province_id) REFERENCES reference.provinces(id) ON DELETE RESTRICT
);
