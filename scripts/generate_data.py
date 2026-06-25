"""
DataVault — Synthetic UK Motor Insurance Data Generator
=======================================================

Generates three CSV files written to seeds/:

  raw_customers.csv   10,000 rows — UK motor insurance customers
  raw_policies.csv    ~25,000 rows — Policies + renewal versions (SCD Type 2)
  raw_claims.csv      8,000 rows — Claims linked to policy_id

SCD demonstration data:
  - SCD Type 1 (customers): 20% of customers have a later updated_at,
    indicating an address or phone change. When dbt snapshot is run a second
    time with the updated version of this data, it overwrites those rows.
  - SCD Type 2 (policies): 20% of expired policies have a renewal row with the
    same policy_number (stable key), a new policy_id, incremented NCD, and a
    recalculated annual_premium. Both rows share the same policy_number, so
    the dbt timestamp snapshot captures both versions and preserves history.

Run:
    python scripts/generate_data.py

Output is deterministic (RANDOM_SEED constant below). Change the seed to
produce a different but equally valid synthetic dataset.
"""

from __future__ import annotations

import csv
import io
import os
import random
import sys
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

import faker

# Force UTF-8 stdout so emoji/box-drawing chars work on Windows terminals.
# Falls back gracefully on systems that don't support reconfigure.
try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[union-attr]
except AttributeError:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ── Configuration ─────────────────────────────────────────────────────────────
RANDOM_SEED = 42
N_CUSTOMERS = 10_000
N_BASE_POLICIES = 21_000   # ~25k total after adding renewal rows
N_CLAIMS = 8_000
SCD1_CHANGE_RATE = 0.20    # 20% of customers get an address/phone change
RENEWAL_RATE = 0.20        # 20% of expired policies get a renewal row
SEEDS_DIR = Path(__file__).parent.parent / "seeds"

# UK cities — weighted towards larger cities
UK_CITIES = [
    "London", "London", "London", "London",  # 4× weight
    "Birmingham", "Birmingham",
    "Manchester", "Manchester",
    "Leeds", "Leeds",
    "Glasgow", "Glasgow",
    "Liverpool",
    "Bristol",
    "Sheffield",
    "Edinburgh",
    "Newcastle upon Tyne",
    "Leicester",
    "Nottingham",
    "Coventry",
    "Bradford",
    "Cardiff",
    "Belfast",
    "Southampton",
    "Portsmouth",
    "Reading",
    "Milton Keynes",
    "Derby",
    "Wolverhampton",
    "Sunderland",
]

COVER_TYPES = ["comprehensive", "third_party_fire_theft", "third_party"]
COVER_MULTIPLIERS = {
    "comprehensive": 1.0,
    "third_party_fire_theft": 0.70,
    "third_party": 0.50,
}

VEHICLE_MAKES = [
    ("Ford", ["Fiesta", "Focus", "Mondeo", "Puma", "Kuga"]),
    ("Volkswagen", ["Golf", "Polo", "Passat", "Tiguan", "T-Roc"]),
    ("BMW", ["3 Series", "5 Series", "1 Series", "X3", "X5"]),
    ("Toyota", ["Corolla", "Yaris", "Rav4", "Prius", "CH-R"]),
    ("Vauxhall", ["Astra", "Corsa", "Insignia", "Mokka", "Crossland"]),
    ("Audi", ["A3", "A4", "Q3", "Q5", "A1"]),
    ("Mercedes-Benz", ["A-Class", "C-Class", "E-Class", "GLA", "CLA"]),
    ("Nissan", ["Qashqai", "Juke", "Leaf", "Micra", "X-Trail"]),
    ("Honda", ["Civic", "Jazz", "CR-V", "HR-V", "e"]),
    ("Kia", ["Sportage", "Ceed", "Niro", "Stonic", "EV6"]),
]

CLAIM_TYPES = [
    "accident", "accident", "accident",  # 3× weight
    "theft",
    "fire",
    "windscreen",
    "weather",
]

CLAIM_STATUSES = ["settled", "settled", "open", "rejected"]  # Weighted


# ── Helpers ───────────────────────────────────────────────────────────────────

def rand_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def rand_dt(start: date, end: date) -> datetime:
    d = rand_date(start, end)
    return datetime(d.year, d.month, d.day,
                    random.randint(0, 23), random.randint(0, 59))


def uk_postcode(fake: faker.Faker) -> str:
    """Return a plausible (not necessarily real) UK postcode."""
    area = fake.lexify("??", letters="ABCDEFGHIJKLMNOPRSTUVWXY").upper()
    district = str(random.randint(1, 99))
    sector = str(random.randint(0, 9))
    unit = fake.lexify("??", letters="ABDEFGHJLNPQRSTUVWXYZ").upper()
    return f"{area}{district} {sector}{unit}"


def calc_premium(vehicle_value: float, cover_type: str, ncd: int) -> float:
    """
    Deterministic premium formula.
    base = 5% of vehicle value
    multiplier = cover type factor
    discount = 5% per NCD year, capped at 50%
    """
    base = vehicle_value * 0.05
    multiplier = COVER_MULTIPLIERS[cover_type]
    discount = min(ncd * 0.05, 0.50)
    return round(base * multiplier * (1 - discount), 2)


def new_uuid() -> str:
    return str(uuid.uuid4())


# ── Generators ────────────────────────────────────────────────────────────────

def generate_customers(fake: faker.Faker) -> list[dict[str, Any]]:
    """Generate 10,000 customer records. 20% have a later updated_at."""
    customers = []
    base_start = date(2015, 1, 1)
    base_end = date(2022, 12, 31)
    update_end = date(2024, 6, 30)
    used_emails: set[str] = set()

    for i in range(N_CUSTOMERS):
        customer_id = new_uuid()
        dob = rand_date(date(1944, 1, 1), date(2005, 12, 31))
        created_at = rand_dt(base_start, base_end)
        # 20% of customers have a later updated_at (address or phone changed)
        has_update = random.random() < SCD1_CHANGE_RATE
        updated_at = (
            rand_dt(created_at.date() + timedelta(days=30), update_end)
            if has_update
            else created_at
        )
        licence_years = max(0, (date.today().year - dob.year) - 17)
        licence_years = min(licence_years, 50)

        # Guarantee email uniqueness by appending a sequential suffix
        base_email = fake.email()
        local, domain = base_email.rsplit("@", 1)
        email = base_email
        counter = 0
        while email in used_emails:
            counter += 1
            email = f"{local}{counter}@{domain}"
        used_emails.add(email)

        customers.append({
            "customer_id": customer_id,
            "first_name": fake.first_name(),
            "last_name": fake.last_name(),
            "email": email,
            "phone": fake.phone_number(),
            "address_line_1": fake.street_address(),
            "city": random.choice(UK_CITIES),
            "postcode": uk_postcode(fake),
            "date_of_birth": dob.isoformat(),
            "licence_years": licence_years,
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": updated_at.isoformat(sep=" "),
        })

    return customers


def generate_policies(
    customer_ids: list[str], fake: faker.Faker
) -> list[dict[str, Any]]:
    """
    Generate ~25,000 policy rows.
    Each customer gets 1-4 base policies.
    20% of expired policies get a renewal row (same policy_number, new policy_id).
    The policy_number is stable across renewals — it is the snapshot unique key.
    """
    policies: list[dict[str, Any]] = []
    pol_counter = 0

    for customer_id in customer_ids:
        num_policies = random.randint(1, 4)
        for _ in range(num_policies):
            pol_counter += 1
            policy_number = f"POL-{pol_counter:07d}"  # stable across renewals
            policy_id = new_uuid()

            make, models = random.choice(VEHICLE_MAKES)
            model = random.choice(models)
            reg_year = random.randint(2005, 2023)
            vehicle_value = round(random.uniform(3_000, 55_000), 2)
            cover_type = random.choices(
                COVER_TYPES, weights=[5, 3, 2], k=1
            )[0]
            ncd = random.randint(0, 9)
            annual_premium = calc_premium(vehicle_value, cover_type, ncd)

            start_date = rand_date(date(2018, 1, 1), date(2023, 12, 31))
            end_date = start_date + timedelta(days=365)
            is_expired = end_date < date.today()

            if is_expired:
                policy_status = random.choices(
                    ["expired", "cancelled"], weights=[9, 1]
                )[0]
            else:
                policy_status = "active"

            created_at = datetime(
                start_date.year, start_date.month, start_date.day, 9, 0, 0
            )

            policies.append({
                "policy_id": policy_id,
                "policy_number": policy_number,
                "customer_id": customer_id,
                "cover_type": cover_type,
                "vehicle_make": make,
                "vehicle_model": model,
                "vehicle_registration_year": reg_year,
                "vehicle_value": vehicle_value,
                "annual_premium": annual_premium,
                "no_claims_discount": ncd,
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "policy_status": policy_status,
                "created_at": created_at.isoformat(sep=" "),
                "updated_at": created_at.isoformat(sep=" "),
            })

            # ── Renewal row (SCD Type 2) ────────────────────────────────────
            # Expired policies: 20% chance of a renewal. Creates a new row
            # with the SAME policy_number (snapshot unique key) but a new
            # policy_id, incremented NCD, and a recalculated premium.
            if is_expired and random.random() < RENEWAL_RATE:
                renewal_id = new_uuid()
                renewal_ncd = min(ncd + 1, 9)
                renewal_start = end_date + timedelta(days=1)
                renewal_end = renewal_start + timedelta(days=365)
                renewal_premium = calc_premium(
                    vehicle_value, cover_type, renewal_ncd
                )
                renewal_status = (
                    "active" if renewal_end >= date.today() else "expired"
                )
                renewal_created_at = datetime(
                    renewal_start.year,
                    renewal_start.month,
                    renewal_start.day,
                    9, 0, 0,
                )
                policies.append({
                    "policy_id": renewal_id,
                    "policy_number": policy_number,
                    "customer_id": customer_id,
                    "cover_type": cover_type,
                    "vehicle_make": make,
                    "vehicle_model": model,
                    "vehicle_registration_year": reg_year,
                    "vehicle_value": vehicle_value,
                    "annual_premium": renewal_premium,
                    "no_claims_discount": renewal_ncd,
                    "start_date": renewal_start.isoformat(),
                    "end_date": renewal_end.isoformat(),
                    "policy_status": renewal_status,
                    "created_at": renewal_created_at.isoformat(sep=" "),
                    "updated_at": renewal_created_at.isoformat(sep=" "),
                })

    return policies


def generate_claims(
    policies: list[dict[str, Any]], fake: faker.Faker
) -> list[dict[str, Any]]:
    """
    Generate 8,000 claims.
    Comprehensive policies are 3× more likely to generate claims.
    Settled claims have days_to_settle; open/rejected have null.
    Settled claim_amount <= vehicle_value (enforced by singular test).
    """
    # Build weighted pool of policy_ids for claim generation
    weighted_pool: list[dict] = []
    for p in policies:
        weight = 3 if p["cover_type"] == "comprehensive" else 1
        weighted_pool.extend([p] * weight)

    claims: list[dict[str, Any]] = []
    for _ in range(N_CLAIMS):
        policy = random.choice(weighted_pool)
        claim_id = new_uuid()

        start = date.fromisoformat(policy["start_date"])
        end = date.fromisoformat(policy["end_date"])
        # Claims can't happen after end_date or in the future
        end_cap = min(end, date.today() - timedelta(days=1))
        if start >= end_cap:
            continue
        claim_date = rand_date(start, end_cap)

        status = random.choice(CLAIM_STATUSES)
        vehicle_value = float(policy["vehicle_value"])

        if status == "settled":
            # Claim amount must not exceed vehicle value (singular test asserts this)
            claim_amount = round(random.uniform(200, vehicle_value * 0.80), 2)
            days_to_settle = str(random.randint(3, 180))
        elif status == "open":
            claim_amount = round(random.uniform(200, vehicle_value * 0.60), 2)
            days_to_settle = ""
        else:  # rejected
            claim_amount = round(random.uniform(200, vehicle_value * 0.40), 2)
            days_to_settle = ""

        created_at = datetime(
            claim_date.year, claim_date.month, claim_date.day,
            random.randint(8, 18), random.randint(0, 59)
        )

        claims.append({
            "claim_id": claim_id,
            "policy_id": policy["policy_id"],
            "policy_number": policy["policy_number"],
            "claim_type": random.choice(CLAIM_TYPES),
            "claim_date": claim_date.isoformat(),
            "claim_amount": claim_amount,
            "claim_status": status,
            "days_to_settle": days_to_settle,
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": created_at.isoformat(sep=" "),
        })

    return claims


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        print(f"  [WARN] No rows to write to {path.name}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(rows[0].keys())
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def print_summary(
    customers: list[dict],
    policies: list[dict],
    claims: list[dict],
) -> None:
    scd1_eligible = sum(
        1 for c in customers if c["created_at"] != c["updated_at"]
    )
    # Policies with duplicated policy_number = SCD Type 2 eligible
    from collections import Counter
    pn_counts = Counter(p["policy_number"] for p in policies)
    scd2_eligible = sum(1 for v in pn_counts.values() if v > 1)
    renewal_rows = sum(1 for v in pn_counts.values() if v > 1)

    active_policies = sum(1 for p in policies if p["policy_status"] == "active")
    settled_claims = sum(1 for c in claims if c["claim_status"] == "settled")
    open_claims = sum(1 for c in claims if c["claim_status"] == "open")
    rejected_claims = sum(1 for c in claims if c["claim_status"] == "rejected")

    print()
    print("=" * 60)
    print("  DataVault — Synthetic Data Generation Summary")
    print("=" * 60)
    print(f"  Customers          : {len(customers):,}")
    print(f"    SCD Type 1 eligible (address/phone changed): {scd1_eligible:,}  "
          f"({scd1_eligible / len(customers):.0%})")
    print()
    print(f"  Policies (total rows): {len(policies):,}")
    print(f"    Active policies    : {active_policies:,}")
    print(f"    Policy numbers with renewal history (SCD Type 2): {scd2_eligible:,}")
    print(f"    Renewal rows       : {renewal_rows:,}")
    print()
    print(f"  Claims             : {len(claims):,}")
    print(f"    Settled           : {settled_claims:,}")
    print(f"    Open              : {open_claims:,}")
    print(f"    Rejected          : {rejected_claims:,}")
    print()
    print("  Files written to seeds/:")
    print(f"    raw_customers.csv   ({len(customers):,} rows)")
    print(f"    raw_policies.csv    ({len(policies):,} rows)")
    print(f"    raw_claims.csv      ({len(claims):,} rows)")
    print("=" * 60)
    print()
    print("  Next step: dbt seed --profiles-dir .")
    print()


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    print("[1/5] Seeding random number generators...")
    random.seed(RANDOM_SEED)
    fake = faker.Faker("en_GB")
    fake.seed_instance(RANDOM_SEED)

    print("[2/5] Generating customers...")
    customers = generate_customers(fake)

    print("[3/5] Generating policies (base + renewals)...")
    customer_ids = [c["customer_id"] for c in customers]
    policies = generate_policies(customer_ids, fake)

    print("[4/5] Generating claims...")
    claims = generate_claims(policies, fake)

    print("[5/5] Writing CSV files...")
    write_csv(SEEDS_DIR / "raw_customers.csv", customers)
    write_csv(SEEDS_DIR / "raw_policies.csv", policies)
    write_csv(SEEDS_DIR / "raw_claims.csv", claims)

    print_summary(customers, policies, claims)


if __name__ == "__main__":
    main()
