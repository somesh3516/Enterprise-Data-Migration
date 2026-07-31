from __future__ import annotations

import csv
import random
import uuid
from datetime import date, timedelta
from pathlib import Path


OUTPUT_FILE = Path("data/raw/legacy_customers.csv")
RECORD_COUNT = 10_000
RANDOM_SEED = 42

FIRST_NAMES = [
    "James", "Maria", "Robert", "Jennifer", "Michael",
    "Linda", "David", "Patricia", "John", "Elizabeth",
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones",
    "Garcia", "Miller", "Davis", "Wilson", "Taylor",
]

LOCATIONS = [
    ("Manassas", "VA", "20110"),
    ("Richmond", "VA", "23220"),
    ("Charlotte", "NC", "28202"),
    ("Atlanta", "GA", "30303"),
    ("Baltimore", "MD", "21201"),
]

STREETS = [
    "Main Street",
    "Oak Avenue",
    "Maple Drive",
    "Cedar Lane",
    "Park Road",
]


def generate_date(start_year: int, end_year: int) -> str:
    start_date = date(start_year, 1, 1)
    end_date = date(end_year, 12, 31)

    days_between = (end_date - start_date).days

    return (
        start_date + timedelta(days=random.randint(0, days_between))
    ).isoformat()


def generate_phone() -> str:
    return (
        f"{random.randint(200, 999)}-"
        f"{random.randint(200, 999)}-"
        f"{random.randint(1000, 9999)}"
    )


def generate_customer(customer_number: int) -> dict[str, str]:
    first_name = random.choice(FIRST_NAMES)
    last_name = random.choice(LAST_NAMES)
    city, state, zip_code = random.choice(LOCATIONS)

    return {
        "legacy_customer_id": f"CUST-{customer_number:06d}",
        "external_id": str(uuid.uuid4()),
        "first_name": first_name,
        "last_name": last_name,
        "email": (
            f"{first_name.lower()}."
            f"{last_name.lower()}{customer_number}@example.com"
        ),
        "phone": generate_phone(),
        "birth_date": generate_date(1940, 2005),
        "street_address": (
            f"{random.randint(100, 9999)} "
            f"{random.choice(STREETS)}"
        ),
        "city": city,
        "state": state,
        "zip_code": zip_code,
        "customer_status": random.choice(
            ["Active", "Active", "Active", "Inactive"]
        ),
        "created_date": generate_date(2015, 2025),
    }


def add_data_quality_issues(
    records: list[dict[str, str]]
) -> None:
    # Missing emails
    for index in random.sample(range(len(records)), 100):
        records[index]["email"] = ""

    # Invalid emails
    for index in random.sample(range(len(records)), 75):
        records[index]["email"] = "invalid-email"

    # Invalid state codes
    for index in random.sample(range(len(records)), 50):
        records[index]["state"] = "XX"

    # Invalid ZIP codes
    for index in random.sample(range(len(records)), 80):
        records[index]["zip_code"] = "123"

    # Missing phone numbers
    for index in random.sample(range(len(records)), 120):
        records[index]["phone"] = ""

    # Duplicate records
    duplicates = [
        records[index].copy()
        for index in random.sample(range(len(records)), 50)
    ]

    records.extend(duplicates)


def main() -> None:
    random.seed(RANDOM_SEED)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    records = [
        generate_customer(customer_number)
        for customer_number in range(1, RECORD_COUNT + 1)
    ]

    add_data_quality_issues(records)

    with OUTPUT_FILE.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as csv_file:
        writer = csv.DictWriter(
            csv_file,
            fieldnames=records[0].keys(),
        )

        writer.writeheader()
        writer.writerows(records)

    print(
        f"Created {len(records):,} records at "
        f"{OUTPUT_FILE.resolve()}"
    )


if __name__ == "__main__":
    main()
