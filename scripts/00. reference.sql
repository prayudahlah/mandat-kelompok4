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


--- INSERT DATA REFERENSI ----
-- 1. units
INSERT INTO reference.units (name) VALUES
    ('Kilogram'),
    ('Gram'),
    ('Ton'),
    ('Kuintal'),
    ('Karung'),
    ('Ikat'),
    ('Ekor'),
    ('Liter'),
    ('Ons'),
    ('Butir'),       
    ('Sisir'),      
    ('Pohon');       

-- 2. order_statuses 
INSERT INTO reference.order_statuses (code) VALUES
    ('pending'),
    ('confirmed'),
    ('processed'),
    ('shipped'),
    ('delivered'),
    ('cancelled'),
    ('returned'),
    ('on_hold'),
    ('awaiting_payment'),
    ('partially_shipped');

-- 3. payment_statuses 
INSERT INTO reference.payment_statuses (code) VALUES
    ('unpaid'),
    ('paid'),
    ('refunded'),
    ('pending_verification'),
    ('failed'),
    ('expired'),
    ('partial'),
    ('refunding'),
    ('cancelled'),
    ('chargeback');

-- 4. shipment_statuses 
INSERT INTO reference.shipment_statuses (code) VALUES
    ('pending'),
    ('picked_up'),
    ('in_transit'),
    ('delivered'),
    ('returned'),
    ('processing'),
    ('on_hold'),
    ('out_for_delivery'),
    ('failed_attempt'),
    ('lost');

-- 5. payment_methods 
INSERT INTO reference.payment_methods (name, is_active) VALUES
    ('Transfer Bank', TRUE),
    ('QRIS', TRUE),
    ('Virtual Account', TRUE),
    ('GoPay', TRUE),
    ('OVO', TRUE),
    ('Dana', TRUE),
    ('Kartu Kredit', FALSE),
    ('Debit Online', TRUE);

-- 6. product_categories 
-- Induk
INSERT INTO reference.product_categories (name, parent_id) VALUES
    ('Sayuran', NULL),
    ('Buah-buahan', NULL),
    ('Biji-bijian', NULL),
    ('Umbi-umbian', NULL),
    ('Kacang-kacangan', NULL),
    ('Rempah-rempah', NULL),
    ('Tanaman Hias', NULL),
    ('Hasil Olahan', NULL);

-- Anak 
INSERT INTO reference.product_categories (name, parent_id) VALUES
    ('Sayuran Daun', (SELECT id FROM reference.product_categories WHERE name = 'Sayuran')),
    ('Sayuran Buah', (SELECT id FROM reference.product_categories WHERE name = 'Sayuran')),
    ('Sayuran Akar', (SELECT id FROM reference.product_categories WHERE name = 'Sayuran')),
    ('Buah Tropis', (SELECT id FROM reference.product_categories WHERE name = 'Buah-buahan')),
    ('Buah Subtropis', (SELECT id FROM reference.product_categories WHERE name = 'Buah-buahan')),
    ('Serealia', (SELECT id FROM reference.product_categories WHERE name = 'Biji-bijian'));

-- 7. provinces 
INSERT INTO reference.provinces (name) VALUES
    ('Jawa Barat'),
    ('Jawa Tengah'),
    ('Jawa Timur'),
    ('DKI Jakarta'),
    ('Banten'),
    ('Sumatera Utara'),
    ('Sumatera Selatan'),
    ('Lampung'),
    ('Bali'),
    ('Nusa Tenggara Barat'),
    ('Kalimantan Selatan'),
    ('Sulawesi Selatan');

-- 8. cities 
INSERT INTO reference.cities (name, province_id) VALUES
    ('Bandung', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Bogor', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Depok', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Semarang', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Solo', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Yogyakarta', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')), -- asumsikan DIY masukkan ke Jateng utk kemudahan
    ('Surabaya', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Malang', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Kediri', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Jakarta Pusat', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Jakarta Selatan', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Jakarta Timur', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Tangerang', (SELECT id FROM reference.provinces WHERE name = 'Banten')),
    ('Serang', (SELECT id FROM reference.provinces WHERE name = 'Banten')),
    ('Medan', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Utara')),
    ('Palembang', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Selatan')),
    ('Bandar Lampung', (SELECT id FROM reference.provinces WHERE name = 'Lampung')),
    ('Denpasar', (SELECT id FROM reference.provinces WHERE name = 'Bali')),
    ('Mataram', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Barat')),
    ('Makassar', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Selatan'));