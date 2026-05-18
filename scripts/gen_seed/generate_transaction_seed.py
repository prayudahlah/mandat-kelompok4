#!/usr/bin/env python3
import csv
import os
import random
from datetime import datetime, timedelta


random.seed(42)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SEED_DIR = os.path.join(BASE_DIR, "seeder", "transaction")
REFERENCE_DIR = os.path.join(BASE_DIR, "seeder", "reference")
MASTER_DIR = os.path.join(BASE_DIR, "seeder", "master")

SELLER_MIN = 1
SELLER_MAX = 200
BUYER_MIN = 201
BUYER_MAX = 599
PRODUCT_MAX = 350
UNIT_MAX = 6

NEGOTIATIONS_COUNT = 600_000
NEGOTIATION_CHATS_COUNT = 1_500_000
CARTS_COUNT = 700_000
CART_ITEMS_COUNT = 1_400_000
CHECKOUTS_COUNT = 300_000
ORDERS_COUNT = 350_000
SHIPMENTS_COUNT = 350_000
ORDER_ITEMS_COUNT = 850_000
PAYMENTS_COUNT = 550_000
CONTRACTS_COUNT = 250_000
CONTRACT_PRODUCTS_COUNT = 1_300_000
CONTRACT_SCHEDULES_COUNT = 500_000

COURIERS = ["JNE", "JNT", "SiCepat", "TIKI", "AnterAja", "Ninja"]
STREETS = [
    "Merdeka",
    "Sudirman",
    "Gatot Subroto",
    "Diponegoro",
    "Ahmad Yani",
    "Pahlawan",
    "Imam Bonjol",
    "Veteran",
    "Kenanga",
    "Melati",
]
VILLAGES = [
    "Sukamaju",
    "Sukamukti",
    "Sukamulia",
    "Sukajaya",
    "Mekarjaya",
    "Mekarsari",
    "Harapan",
    "Sejahtera",
    "Makmur",
    "Maju",
]
PAYMENT_PREFIX = {1: "TRF", 2: "QRS", 3: "VAC", 4: "GOP", 5: "OVO", 6: "DAN", 7: "DBT"}
BUYER_CHAT = [
    "Harga masih bisa kurang gak?",
    "Kalau saya ambil banyak, bisa lebih murah?",
    "Budget saya segini, bisa dibantu gak?",
    "Kalau harga segitu, saya pikir-pikir dulu.",
]
SELLER_CHAT = [
    "Maaf, harga sudah pas banget, gak bisa kurang lagi.",
    "Sudah paling bawah, kak.",
    "Kalau itu saya rugi, belum bisa.",
    "Harga segitu sudah sesuai kualitasnya.",
]
CONTRACT_TEXT = [
    "Saya ajukan kerja sama pasokan rutin.",
    "Mohon dipertimbangkan kontrak suplai ini.",
    "Saya ingin kontrak pengadaan bulanan.",
    "Tolong cek proposal kemitraan ini.",
]


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def read_csv_dict(path):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def read_products():
    products = {}
    rows = read_csv_dict(os.path.join(MASTER_DIR, "03_products.csv"))
    for idx, row in enumerate(rows, start=1):
        products[idx] = {
            "seller_id": int(row["seller_id"]),
            "price_per_unit": int(row["price_per_unit"]),
            "unit_id": int(row["unit_id"]),
            "min_order_qty": int(row["min_order_qty"]),
            "is_negotiable": row["is_negotiable"].strip().lower() == "true",
        }
    return products


def read_cities():
    cities = {}
    rows = read_csv_dict(os.path.join(REFERENCE_DIR, "10_cities.csv"))
    for idx, row in enumerate(rows, start=1):
        cities[idx] = {"name": row["name"], "province_id": int(row["province_id"])}
    return cities


def read_provinces():
    rows = read_csv_dict(os.path.join(REFERENCE_DIR, "09_provinces.csv"))
    return {idx: row["name"] for idx, row in enumerate(rows, start=1)}


def write_csv(path, header, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def fmt_ts(dt):
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def fmt_date(dt):
    return dt.strftime("%Y-%m-%d")


def fmt_time(dt):
    return dt.strftime("%H:%M:%S")


def dt_from_id(base, ident, span_days=365):
    return base + timedelta(seconds=(ident * 7919) % (span_days * 86400))


def address(city_name, province_name):
    return f"Jl. {random.choice(STREETS)} No. {random.randint(1, 200)}, Desa {random.choice(VILLAGES)}, {city_name}, {province_name}, RT {random.randint(1, 9)}/RW {random.randint(1, 9)}"


def load_products_and_cities():
    return read_products(), read_cities(), read_provinces()


def group_products_by_seller(products):
    grouped = {}
    for product_id, product in products.items():
        grouped.setdefault(product["seller_id"], []).append(product_id)
    return grouped


def generate_negotiations(products):
    rows = []
    offers = {}
    start = datetime(2024, 1, 1)
    for idx in range(1, NEGOTIATIONS_COUNT + 1):
        # Shuffle product assignment across the full catalog for better distribution.
        product_id = ((idx - 1) % PRODUCT_MAX) + 1
        product = products[product_id]
        created_at = dt_from_id(start, idx)
        if idx % 3 == 0:
            agreed_price = product["price_per_unit"]
            status = "accepted"
        elif idx % 3 == 1:
            agreed_price = random.randint(
                max(1, int(product["price_per_unit"] * 0.85)), product["price_per_unit"]
            )
            status = "ongoing"
        else:
            agreed_price = random.randint(
                max(1, int(product["price_per_unit"] * 0.5)),
                max(1, int(product["price_per_unit"] * 0.74)),
            )
            status = "rejected"
        rows.append(
            [
                product["seller_id"],
                random.randint(BUYER_MIN, BUYER_MAX),
                product_id,
                agreed_price,
                product["unit_id"],
                random.randint(1, 200),
                fmt_ts(created_at + timedelta(days=7)),
                status,
                fmt_ts(created_at),
                fmt_ts(created_at + timedelta(hours=6)),
            ]
        )
        offers[idx] = {
            "product_id": product_id,
            "agreed_price_offer": agreed_price,
            "unit_id": product["unit_id"],
            "status": status,
        }
    write_csv(
        os.path.join(SEED_DIR, "01_negotiations.csv"),
        [
            "seller_id",
            "buyer_id",
            "product_id",
            "agreed_price_offer",
            "agreed_unit_id",
            "agreed_quantity_offer",
            "valid_until",
            "status",
            "created_at",
            "updated_at",
        ],
        rows,
    )
    return offers


def generate_negotiation_chats(products, negotiation_offers):
    rows = []
    start = datetime(2024, 1, 1)
    turns = ["buyer", "seller", "buyer"]
    for negotiation_id in range(1, 500_001):
        offer = negotiation_offers[negotiation_id]
        product = products[offer["product_id"]]
        base_time = dt_from_id(start, negotiation_id)
        for step, owner in enumerate(turns, start=1):
            rows.append(
                [
                    negotiation_id,
                    step,
                    owner,
                    max(1, offer["agreed_price_offer"] - (step - 1) * 500),
                    offer["unit_id"],
                    random.randint(1, 200),
                    random.choice(BUYER_CHAT if owner == "buyer" else SELLER_CHAT),
                    fmt_ts(base_time + timedelta(minutes=step * 5)),
                ]
            )
    write_csv(
        os.path.join(SEED_DIR, "02_negotiation_chats.csv"),
        [
            "negotiation_id",
            "turn_order",
            "turn_owner",
            "offer_price",
            "unit_id",
            "quantity_offer",
            "description",
            "created_at",
        ],
        rows,
    )


def build_accepted_negotiation_pool(negotiation_offers):
    pool = {}
    for negotiation_id, offer in negotiation_offers.items():
        if offer["status"] != "accepted":
            continue
        pool.setdefault(offer["product_id"], []).append(negotiation_id)
    return pool


def generate_carts():
    rows = []
    start = datetime(2024, 1, 1)
    for cart_id in range(1, CARTS_COUNT + 1):
        rows.append(
            [random.randint(BUYER_MIN, BUYER_MAX), fmt_ts(dt_from_id(start, cart_id))]
        )
    write_csv(os.path.join(SEED_DIR, "03_carts.csv"), ["user_id", "created_at"], rows)


def generate_cart_items(products):
    rows = []
    start = datetime(2024, 1, 1)
    for cart_id in range(1, CARTS_COUNT + 1):
        chosen = random.sample(range(1, PRODUCT_MAX + 1), 2)
        for idx, product_id in enumerate(chosen, start=1):
            product = products[product_id]
            rows.append(
                [
                    cart_id,
                    product_id,
                    random.randint(
                        product["min_order_qty"], product["min_order_qty"] * 5
                    ),
                    product["unit_id"],
                    fmt_ts(dt_from_id(start, cart_id * 10 + idx)),
                ]
            )
    write_csv(
        os.path.join(SEED_DIR, "04_cart_items.csv"),
        ["cart_id", "product_id", "quantity", "unit_id", "added_at"],
        rows,
    )


def build_checkouts(checkout_totals, cities, provinces, checkout_payment_map):
    rows = []
    start = datetime(2024, 1, 1)
    city_ids = list(cities.keys())
    for checkout_id in range(1, CHECKOUTS_COUNT + 1):
        dt = dt_from_id(start, checkout_id)
        city_id = city_ids[(checkout_id - 1) % len(city_ids)]
        city = cities[city_id]
        province_name = provinces[city["province_id"]]
        rows.append(
            [
                random.randint(BUYER_MIN, BUYER_MAX),
                checkout_payment_map.get(checkout_id),
                checkout_totals[checkout_id],
                address(city["name"], province_name),
                random.randint(1, 7),
                fmt_ts(dt),
                fmt_ts(dt + timedelta(hours=6)),
            ]
        )
    return rows


def generate_shipments(cities, provinces):
    rows = []
    start = datetime(2024, 1, 1)
    for shipment_id in range(1, SHIPMENTS_COUNT + 1):
        city_id = ((shipment_id - 1) % len(cities)) + 1
        city = cities[city_id]
        province_id = city["province_id"]
        province_name = provinces[province_id]
        created_at = dt_from_id(start, shipment_id)
        shipped_at = created_at + timedelta(hours=3)
        delivered_at = shipped_at + timedelta(hours=36)
        rows.append(
            [
                random.choice(COURIERS),
                province_id,
                city_id,
                address(city["name"], province_name),
                random.randint(1, 8),
                fmt_ts(shipped_at),
                fmt_ts(delivered_at),
                fmt_ts(created_at),
                fmt_ts(delivered_at),
            ]
        )
    write_csv(
        os.path.join(SEED_DIR, "06_shipments.csv"),
        [
            "courier_name",
            "province_id",
            "city_id",
            "shipping_address",
            "shipment_status_id",
            "shipped_at",
            "delivered_at",
            "created_at",
            "updated_at",
        ],
        rows,
    )


def build_orders_and_checkout_totals(products, negotiation_offers):
    rows = []
    order_item_rows = []
    checkout_totals = [0] * (CHECKOUTS_COUNT + 1)
    order_totals = [0] * (ORDERS_COUNT + 1)
    order_sellers = [0] * (ORDERS_COUNT + 1)
    seller_products = group_products_by_seller(products)
    accepted_pool = build_accepted_negotiation_pool(negotiation_offers)
    start = datetime(2024, 1, 1)
    used_numbers = set()
    for order_id in range(1, ORDERS_COUNT + 1):
        checkout_id = ((order_id - 1) % CHECKOUTS_COUNT) + 1
        seller_id = ((order_id - 1) % SELLER_MAX) + 1
        seller_product_ids = seller_products.get(seller_id)
        if not seller_product_ids:
            seller_id = next(
                sid for sid, product_ids in seller_products.items() if product_ids
            )
            seller_product_ids = seller_products[seller_id]
        created_at = dt_from_id(start, order_id)
        order_number = None
        while not order_number or order_number in used_numbers:
            order_number = (
                f"PNK-{created_at.strftime('%Y%m%d')}-{random.randint(0, 99999999):08d}"
            )
        used_numbers.add(order_number)
        item_count = 3 if order_id <= 150_000 else 2
        chosen_products = random.sample(
            seller_product_ids, k=min(item_count, len(seller_product_ids))
        )
        subtotal = 0
        for item_idx, product_id in enumerate(chosen_products, start=1):
            product = products[product_id]
            quantity = random.randint(1, 20)
            discount = random.randint(0, max(0, product["price_per_unit"] - 1))
            price = product["price_per_unit"]
            negotiation_id = None
            if product["is_negotiable"]:
                pool = accepted_pool.get(product_id)
                if pool and (order_id + item_idx) % 3 == 0:
                    negotiation_id = pool[(order_id - 1) % len(pool)]
                    price = negotiation_offers[negotiation_id]["agreed_price_offer"]
            item_subtotal = max((price - discount) * quantity, quantity)
            subtotal += item_subtotal
            order_item_rows.append(
                [
                    order_id,
                    product_id,
                    random.randint(1, 8),
                    quantity,
                    product["unit_id"],
                    price,
                    discount,
                    item_subtotal,
                    negotiation_id,
                ]
            )
        order_totals[order_id] = subtotal
        order_sellers[order_id] = seller_id
        checkout_totals[checkout_id] += subtotal
        rows.append(
            [
                checkout_id,
                order_id,
                order_number,
                seller_id,
                subtotal,
                fmt_ts(created_at),
                fmt_ts(created_at + timedelta(hours=6)),
            ]
        )
    return rows, order_item_rows, checkout_totals


def build_payments(checkout_totals, contract_totals):
    rows = []
    contract_payment_map = {}
    checkout_payment_map = {}
    start = datetime(2024, 1, 1)
    checkout_payment_count = CHECKOUTS_COUNT
    contract_payment_count = CONTRACTS_COUNT
    for payment_id in range(1, checkout_payment_count + 1):
        checkout_id = payment_id
        method_id = ((payment_id - 1) % 7) + 1
        created_at = dt_from_id(start, payment_id)
        paid_at = created_at + timedelta(hours=2)
        rows.append(
            [
                method_id,
                checkout_totals[checkout_id],
                random.randint(1, 8),
                f"{PAYMENT_PREFIX[method_id]}-{checkout_id:07d}-{payment_id:08d}",
                fmt_ts(paid_at),
                fmt_ts(created_at),
                fmt_ts(paid_at),
            ]
        )
        checkout_payment_map[checkout_id] = payment_id
    for idx in range(contract_payment_count):
        payment_id = checkout_payment_count + idx + 1
        contract_id = idx + 1
        method_id = ((payment_id - 1) % 7) + 1
        created_at = dt_from_id(start, payment_id)
        paid_at = created_at + timedelta(hours=2)
        amount = contract_totals[contract_id]
        rows.append(
            [
                method_id,
                amount,
                random.randint(1, 8),
                f"{PAYMENT_PREFIX[method_id]}-CTR-{contract_id:07d}-{payment_id:08d}",
                fmt_ts(paid_at),
                fmt_ts(created_at),
                fmt_ts(paid_at),
            ]
        )
        contract_payment_map[contract_id] = payment_id
    return rows, checkout_payment_map, contract_payment_map


def build_contract_products_and_totals(products):
    rows = []
    contract_totals = [0] * (CONTRACTS_COUNT + 1)
    for contract_id in range(1, CONTRACTS_COUNT + 1):
        total_shipping = 5 if contract_id % 2 == 0 else 10
        count = 6 if contract_id <= 50_000 else 5
        chosen = random.sample(range(1, PRODUCT_MAX + 1), count)
        for idx, product_id in enumerate(chosen, start=1):
            product = products[product_id]
            quantity = random.randint(1, 50)
            total_quantity = quantity * total_shipping
            subtotal = product["price_per_unit"] * total_quantity
            contract_totals[contract_id] += subtotal
            rows.append(
                [
                    contract_id,
                    product_id,
                    quantity,
                    product["unit_id"],
                    subtotal,
                    total_quantity,
                    fmt_ts(datetime(2024, 1, 1) + timedelta(days=idx)),
                ]
            )
    return rows, contract_totals


def build_contracts(contract_totals, cities, provinces, contract_payment_map):
    rows = []
    end_dates = {}
    start = datetime(2024, 1, 1)
    for contract_id in range(1, CONTRACTS_COUNT + 1):
        buyer_id = random.randint(BUYER_MIN, BUYER_MAX)
        seller_id = random.randint(SELLER_MIN, SELLER_MAX)
        while seller_id == buyer_id:
            seller_id = random.randint(SELLER_MIN, SELLER_MAX)
        city_id = ((contract_id - 1) % len(cities)) + 1
        city = cities[city_id]
        province_name = provinces[city["province_id"]]
        start_date = start + timedelta(days=contract_id % 365)
        end_date = start_date + timedelta(days=60)
        end_dates[contract_id] = end_date
        rows.append(
            [
                buyer_id,
                seller_id,
                contract_id,
                contract_payment_map.get(contract_id),
                contract_totals[contract_id],
                address(city["name"], province_name),
                fmt_date(start_date),
                fmt_date(end_date),
                random.choice(["daily", "weekly", "specific_dates"]),
                5 if contract_id % 2 == 0 else 10,
                random.choice(CONTRACT_TEXT),
                random.randint(1, 6),
                fmt_ts(start_date - timedelta(days=7)),
                fmt_ts(start_date - timedelta(days=1)),
            ]
        )
    return rows, end_dates


def build_contract_schedules(contract_end_dates):
    rows = []
    days = [
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday",
        "sunday",
    ]
    for contract_id in range(1, CONTRACTS_COUNT + 1):
        base = datetime(2024, 1, 1) + timedelta(days=contract_id % 365)
        end_date = contract_end_dates[contract_id]
        first_delivery = end_date - timedelta(days=10)
        second_delivery = end_date - timedelta(days=3)
        rows.append(
            [
                contract_id,
                None,
                fmt_date(first_delivery),
                fmt_time(base),
                fmt_ts(base - timedelta(days=2)),
            ]
        )
        rows.append(
            [
                contract_id,
                random.choice(days),
                fmt_date(second_delivery),
                fmt_time(base + timedelta(hours=2)),
                fmt_ts(base - timedelta(days=1)),
            ]
        )
    return rows


def main():
    ensure_dir(SEED_DIR)
    products, cities, provinces = load_products_and_cities()

    negotiation_offers = generate_negotiations(products)
    generate_negotiation_chats(products, negotiation_offers)
    generate_carts()
    generate_cart_items(products)

    # Build transaction tables bottom-up so parent totals are derived from children.
    order_rows, order_item_rows, checkout_totals = build_orders_and_checkout_totals(
        products, negotiation_offers
    )
    write_csv(
        os.path.join(SEED_DIR, "08_order_items.csv"),
        [
            "order_id",
            "product_id",
            "order_item_status_id",
            "quantity",
            "unit_id",
            "price_per_unit",
            "discount",
            "subtotal",
            "negotiation_id",
        ],
        order_item_rows,
    )

    write_csv(
        os.path.join(SEED_DIR, "07_orders.csv"),
        [
            "checkout_id",
            "shipment_id",
            "order_number",
            "seller_id",
            "subtotal",
            "created_at",
            "updated_at",
        ],
        order_rows,
    )

    generate_shipments(cities, provinces)

    contract_product_rows, contract_totals = build_contract_products_and_totals(
        products
    )
    write_csv(
        os.path.join(SEED_DIR, "11_contract_products.csv"),
        [
            "contract_id",
            "product_id",
            "quantity",
            "unit_id",
            "subtotal",
            "total_quantity",
            "created_at",
        ],
        contract_product_rows,
    )

    payment_rows, checkout_payment_map, contract_payment_map = build_payments(
        checkout_totals, contract_totals
    )
    write_csv(
        os.path.join(SEED_DIR, "09_payments.csv"),
        [
            "payment_method_id",
            "amount",
            "payment_status_id",
            "transaction_id",
            "paid_at",
            "created_at",
            "updated_at",
        ],
        payment_rows,
    )

    checkouts_rows = build_checkouts(
        checkout_totals, cities, provinces, checkout_payment_map
    )
    write_csv(
        os.path.join(SEED_DIR, "05_checkouts.csv"),
        [
            "buyer_id",
            "payment_id",
            "total_amount",
            "shipping_address",
            "checkout_status_id",
            "created_at",
            "updated_at",
        ],
        checkouts_rows,
    )

    contract_rows, contract_end_dates = build_contracts(
        contract_totals, cities, provinces, contract_payment_map
    )
    write_csv(
        os.path.join(SEED_DIR, "10_contracts.csv"),
        [
            "buyer_id",
            "seller_id",
            "shipment_id",
            "payment_id",
            "total_amount",
            "delivery_location",
            "start_date",
            "end_date",
            "frequency",
            "total_shipping",
            "description",
            "contract_status_id",
            "created_at",
            "updated_at",
        ],
        contract_rows,
    )

    contract_schedule_rows = build_contract_schedules(contract_end_dates)
    write_csv(
        os.path.join(SEED_DIR, "12_contract_schedules.csv"),
        ["contract_id", "delivery_day", "delivery_date", "delivery_time", "created_at"],
        contract_schedule_rows,
    )


if __name__ == "__main__":
    main()
