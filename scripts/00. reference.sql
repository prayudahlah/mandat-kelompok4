CREATE SCHEMA IF NOT EXISTS reference;

-- 1. Satuan
CREATE TABLE IF NOT EXISTS reference.units (
    id         INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name       VARCHAR(30) UNIQUE NOT NULL,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- 2. Status Checkout
CREATE TABLE IF NOT EXISTS reference.checkout_statuses (
    id   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    code VARCHAR(20) UNIQUE NOT NULL
);

-- 3. Status Pesanan
CREATE TABLE IF NOT EXISTS reference.order_statuses (
    id   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    code VARCHAR(20) UNIQUE NOT NULL
);

-- 4. Status Pembayaran
CREATE TABLE IF NOT EXISTS reference.payment_statuses (
    id   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    code VARCHAR(20) UNIQUE NOT NULL
);

-- 5. Status Pengiriman
CREATE TABLE IF NOT EXISTS reference.shipment_statuses (
    id   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    code VARCHAR(20) UNIQUE NOT NULL
);

-- 6. Status Kontrak Kemitraan
CREATE TABLE IF NOT EXISTS reference.contract_statuses (
    id   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    code VARCHAR(20) UNIQUE NOT NULL
);

-- 7. Metode Pembayaran
CREATE TABLE IF NOT EXISTS reference.payment_methods (
    id         INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name       VARCHAR(50) UNIQUE NOT NULL,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- 8. Kategori Produk (dengan struktur hirarki)
-- FK: parent_id -> id (self-referential)
CREATE TABLE reference.product_categories (
    id         BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name       VARCHAR(100) NOT NULL,
    parent_id  BIGINT,
    deleted_at TIMESTAMP DEFAULT NULL,

    FOREIGN KEY (parent_id) REFERENCES reference.product_categories (id) ON DELETE RESTRICT
);

-- 9. Provinsi
CREATE TABLE reference.provinces (
    id         BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name       VARCHAR(50) UNIQUE NOT NULL,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- 10. Kota
-- FK: province_id -> reference.provinces.id
CREATE TABLE reference.cities (
    id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name        VARCHAR(50) NOT NULL,
    province_id BIGINT      NOT NULL,

    FOREIGN KEY (province_id) REFERENCES reference.provinces (id) ON DELETE RESTRICT
);
