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
--- 1. units
INSERT INTO reference.units (name) VALUES
    ('Kilogram'), 
    ('Gram'), 
    ('Ton'), 
    ('Kuintal'), 
    ('Liter'), 
    ('Ons'); 

-- 2. checkout_statuses
INSERT INTO reference.checkout_statuses (code) VALUES
    ('pending'),
    ('failed'),
    ('cancelled'),
    ('expired'),
    ('awaiting_payment'),
    ('paid'),
    ('refunded'),

-- 3. order_statuses
INSERT INTO reference.order_statuses (code) VALUES
    ('pending'),
    ('confirmed'),
    ('processed'),
    ('shipped'),
    ('delivered'),
    ('cancelled'),
    ('returned'),
    ('on_hold'),

-- 4. payment_statuses
INSERT INTO reference.payment_statuses (code) VALUES
    ('unpaid'),
    ('paid'),
    ('refunded'),
    ('pending_verification'),
    ('failed'),
    ('expired'),
    ('refunding'),
    ('cancelled'),

-- 5. shipment_statuses
INSERT INTO reference.shipment_statuses (code) VALUES
    ('pending'),
    ('picked_up'),
    ('delivered'),
    ('returned'),
    ('on_hold'),
    ('out_for_delivery'),
    ('failed_attempt');

-- 6. contract_statuses
INSERT INTO reference.contract_statuses (code) VALUES
    ('rejected'),
    ('approved'),
    ('active'),
    ('completed'),
    ('cancelled'),
    ('expired');

-- 7. payment_methods
INSERT INTO reference.payment_methods (name) VALUES
    ('Transfer Bank'),
    ('QRIS'),
    ('Virtual Account'),
    ('GoPay'),
    ('OVO'),
    ('Dana'),
    ('Debit Online');

-- 8. product_categories 
INSERT INTO reference.product_categories (name, parent_id) VALUES
    ('Sayuran', NULL),
    ('Buah-buahan', NULL),
    ('Biji-bijian & Serealia', NULL),
    ('Umbi-umbian', NULL),
    ('Kacang-kacangan', NULL),
    ('Rempah-rempah & Bumbu', NULL),
    ('Tanaman Perkebunan', NULL),
    ('Tanaman Hias & Bunga', NULL),
    ('Hasil Hutan Non-Kayu', NULL);

-- Anak kategori 
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Sayuran Daun', id FROM reference.product_categories WHERE name = 'Sayuran';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Sayuran Buah', id FROM reference.product_categories WHERE name = 'Sayuran';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Sayuran Akar & Umbi', id FROM reference.product_categories WHERE name = 'Sayuran';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Buah Tropis', id FROM reference.product_categories WHERE name = 'Buah-buahan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Buah Subtropis', id FROM reference.product_categories WHERE name = 'Buah-buahan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Buah Berry', id FROM reference.product_categories WHERE name = 'Buah-buahan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Padi & Beras', id FROM reference.product_categories WHERE name = 'Biji-bijian & Serealia';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Jagung', id FROM reference.product_categories WHERE name = 'Biji-bijian & Serealia';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Gandum & Serealia Lain', id FROM reference.product_categories WHERE name = 'Biji-bijian & Serealia';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Singkong & Ubi', id FROM reference.product_categories WHERE name = 'Umbi-umbian';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kentang', id FROM reference.product_categories WHERE name = 'Umbi-umbian';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kacang Tanah', id FROM reference.product_categories WHERE name = 'Kacang-kacangan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kedelai', id FROM reference.product_categories WHERE name = 'Kacang-kacangan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kacang Hijau & Lainnya', id FROM reference.product_categories WHERE name = 'Kacang-kacangan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Rempah Daun', id FROM reference.product_categories WHERE name = 'Rempah-rempah & Bumbu';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Rempah Akar & Rimpang', id FROM reference.product_categories WHERE name = 'Rempah-rempah & Bumbu';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kopi', id FROM reference.product_categories WHERE name = 'Tanaman Perkebunan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Teh', id FROM reference.product_categories WHERE name = 'Tanaman Perkebunan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kakao', id FROM reference.product_categories WHERE name = 'Tanaman Perkebunan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Kelapa & Turunannya', id FROM reference.product_categories WHERE name = 'Tanaman Perkebunan';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Tanaman Hias Daun', id FROM reference.product_categories WHERE name = 'Tanaman Hias & Bunga';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Madu', id FROM reference.product_categories WHERE name = 'Hasil Hutan Non-Kayu';
INSERT INTO reference.product_categories (name, parent_id)
SELECT 'Rotan & Bambu', id FROM reference.product_categories WHERE name = 'Hasil Hutan Non-Kayu';
INSERT INTO reference.product_categories (name, parent_id)

-- 9. provinces 
INSERT INTO reference.provinces (name) VALUES
    ('Aceh'),
    ('Sumatera Utara'),
    ('Sumatera Barat'),
    ('Riau'),
    ('Kepulauan Riau'),
    ('Jambi'),
    ('Sumatera Selatan'),
    ('Bangka Belitung'),
    ('Bengkulu'),
    ('Lampung'),
    ('DKI Jakarta'),
    ('Banten'),
    ('Jawa Barat'),
    ('Jawa Tengah'),
    ('DI Yogyakarta'),
    ('Jawa Timur'),
    ('Bali'),
    ('Nusa Tenggara Barat'),
    ('Nusa Tenggara Timur'),
    ('Kalimantan Barat'),
    ('Kalimantan Tengah'),
    ('Kalimantan Selatan'),
    ('Kalimantan Timur'),
    ('Kalimantan Utara'),
    ('Sulawesi Utara'),
    ('Gorontalo'),
    ('Sulawesi Tengah'),
    ('Sulawesi Barat'),
    ('Sulawesi Selatan'),
    ('Sulawesi Tenggara'),
    ('Maluku'),
    ('Maluku Utara'),
    ('Papua'),
    ('Papua Barat'),
    ('Papua Selatan'),
    ('Papua Tengah'),
    ('Papua Pegunungan'),
    ('Papua Barat Daya');

-- 10. cities 
INSERT INTO reference.cities (name, province_id) VALUES
    -- Aceh
    ('Banda Aceh', (SELECT id FROM reference.provinces WHERE name = 'Aceh')),
    ('Lhokseumawe', (SELECT id FROM reference.provinces WHERE name = 'Aceh')),
    ('Langsa', (SELECT id FROM reference.provinces WHERE name = 'Aceh')),
    -- Sumatera Utara
    ('Medan', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Utara')),
    ('Binjai', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Utara')),
    ('Pematangsiantar', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Utara')),
    ('Tebing Tinggi', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Utara')),
    ('Sibolga', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Utara')),
    -- Sumatera Barat
    ('Padang', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Barat')),
    ('Bukittinggi', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Barat')),
    ('Payakumbuh', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Barat')),
    ('Solok', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Barat')),
    -- Riau
    ('Pekanbaru', (SELECT id FROM reference.provinces WHERE name = 'Riau')),
    ('Dumai', (SELECT id FROM reference.provinces WHERE name = 'Riau')),
    ('Siak', (SELECT id FROM reference.provinces WHERE name = 'Riau')),
    -- Kepulauan Riau
    ('Batam', (SELECT id FROM reference.provinces WHERE name = 'Kepulauan Riau')),
    ('Tanjungpinang', (SELECT id FROM reference.provinces WHERE name = 'Kepulauan Riau')),
    -- Jambi
    ('Jambi', (SELECT id FROM reference.provinces WHERE name = 'Jambi')),
    ('Sungai Penuh', (SELECT id FROM reference.provinces WHERE name = 'Jambi')),
    -- Sumatera Selatan
    ('Palembang', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Selatan')),
    ('Lubuklinggau', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Selatan')),
    ('Prabumulih', (SELECT id FROM reference.provinces WHERE name = 'Sumatera Selatan')),
    -- Bangka Belitung
    ('Pangkalpinang', (SELECT id FROM reference.provinces WHERE name = 'Bangka Belitung')),
    -- Bengkulu
    ('Bengkulu', (SELECT id FROM reference.provinces WHERE name = 'Bengkulu')),
    -- Lampung
    ('Bandar Lampung', (SELECT id FROM reference.provinces WHERE name = 'Lampung')),
    ('Metro', (SELECT id FROM reference.provinces WHERE name = 'Lampung')),
    ('Kotabumi', (SELECT id FROM reference.provinces WHERE name = 'Lampung')),
    -- DKI Jakarta
    ('Jakarta Pusat', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Jakarta Selatan', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Jakarta Timur', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Jakarta Barat', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    ('Jakarta Utara', (SELECT id FROM reference.provinces WHERE name = 'DKI Jakarta')),
    -- Banten
    ('Tangerang', (SELECT id FROM reference.provinces WHERE name = 'Banten')),
    ('Serang', (SELECT id FROM reference.provinces WHERE name = 'Banten')),
    ('Cilegon', (SELECT id FROM reference.provinces WHERE name = 'Banten')),
    ('Pandeglang', (SELECT id FROM reference.provinces WHERE name = 'Banten')),
    -- Jawa Barat
    ('Bandung', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Bogor', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Depok', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Bekasi', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Cirebon', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Tasikmalaya', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Cimahi', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    ('Sukabumi', (SELECT id FROM reference.provinces WHERE name = 'Jawa Barat')),
    -- Jawa Tengah
    ('Semarang', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Solo', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Magelang', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Pekalongan', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Tegal', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Purwokerto', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    ('Salatiga', (SELECT id FROM reference.provinces WHERE name = 'Jawa Tengah')),
    -- DI Yogyakarta
    ('Yogyakarta', (SELECT id FROM reference.provinces WHERE name = 'DI Yogyakarta')),
    ('Sleman', (SELECT id FROM reference.provinces WHERE name = 'DI Yogyakarta')),
    -- Jawa Timur
    ('Surabaya', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Malang', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Kediri', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Madiun', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Jember', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Banyuwangi', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Probolinggo', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Pasuruan', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    ('Blitar', (SELECT id FROM reference.provinces WHERE name = 'Jawa Timur')),
    -- Bali
    ('Denpasar', (SELECT id FROM reference.provinces WHERE name = 'Bali')),
    ('Singaraja', (SELECT id FROM reference.provinces WHERE name = 'Bali')),
    -- NTB
    ('Mataram', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Barat')),
    ('Bima', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Barat')),
    ('Sumbawa Besar', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Barat')),
    -- NTT
    ('Kupang', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Timur')),
    ('Ende', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Timur')),
    ('Maumere', (SELECT id FROM reference.provinces WHERE name = 'Nusa Tenggara Timur')),
    -- Kalimantan Barat
    ('Pontianak', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Barat')),
    ('Singkawang', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Barat')),
    ('Ketapang', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Barat')),
    -- Kalimantan Tengah
    ('Palangkaraya', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Tengah')),
    ('Sampit', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Tengah')),
    -- Kalimantan Selatan
    ('Banjarmasin', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Selatan')),
    ('Banjarbaru', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Selatan')),
    ('Martapura', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Selatan')),
    -- Kalimantan Timur
    ('Samarinda', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Timur')),
    ('Balikpapan', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Timur')),
    ('Bontang', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Timur')),
    -- Kalimantan Utara
    ('Tanjung Selor', (SELECT id FROM reference.provinces WHERE name = 'Kalimantan Utara')),
    -- Sulawesi Utara
    ('Manado', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Utara')),
    ('Bitung', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Utara')),
    ('Tomohon', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Utara')),
    -- Gorontalo
    ('Gorontalo', (SELECT id FROM reference.provinces WHERE name = 'Gorontalo')),
    -- Sulawesi Tengah
    ('Palu', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Tengah')),
    -- Sulawesi Barat
    ('Mamuju', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Barat')),
    -- Sulawesi Selatan
    ('Makassar', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Selatan')),
    ('Parepare', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Selatan')),
    ('Palopo', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Selatan')),
    ('Watampone', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Selatan')),
    -- Sulawesi Tenggara
    ('Kendari', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Tenggara')),
    ('Baubau', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Tenggara')),
    ('Kolaka', (SELECT id FROM reference.provinces WHERE name = 'Sulawesi Tenggara')),
    -- Maluku
    ('Ambon', (SELECT id FROM reference.provinces WHERE name = 'Maluku')),
    ('Tual', (SELECT id FROM reference.provinces WHERE name = 'Maluku')),
    -- Maluku Utara
    ('Ternate', (SELECT id FROM reference.provinces WHERE name = 'Maluku Utara')),
    -- Papua
    ('Jayapura', (SELECT id FROM reference.provinces WHERE name = 'Papua')),
    ('Sentani', (SELECT id FROM reference.provinces WHERE name = 'Papua')),
    -- Papua Barat
    ('Manokwari', (SELECT id FROM reference.provinces WHERE name = 'Papua Barat')),
    -- Papua Selatan
    ('Merauke', (SELECT id FROM reference.provinces WHERE name = 'Papua Selatan')),
    -- Papua Tengah
    ('Timika', (SELECT id FROM reference.provinces WHERE name = 'Papua Tengah')),
    -- Papua Pegunungan
    ('Wamena', (SELECT id FROM reference.provinces WHERE name = 'Papua Pegunungan')),
    -- Papua Barat Daya
    ('Sorong', (SELECT id FROM reference.provinces WHERE name = 'Papua Barat Daya'));
