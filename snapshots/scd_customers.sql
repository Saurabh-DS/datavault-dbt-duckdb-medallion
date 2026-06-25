-- scd_customers.sql
-- SCD Type 1 snapshot: customer contact details.
--
-- Strategy: check
-- Unique key: customer_id
-- Tracked columns: address_line_1, city, postcode, phone
--
-- Behaviour:
--   When any of the tracked columns changes, dbt OVERWRITES the existing
--   snapshot row with the new values. No history is preserved.
--
--   This is the correct approach for contact details in a regulated insurance
--   business. You need the current address to send documents and regulatory
--   correspondence — not a history of every address. Audit trails for contact
--   changes are handled by the source system's own change log, not dbt snapshots.
--
-- To observe SCD Type 1 in action:
--   1. Run: dbt snapshot --profiles-dir .
--   2. Modify raw_customers.csv (change address/phone for some rows, advance updated_at)
--      OR re-run scripts/generate_data.py after setting RANDOM_SEED=43
--   3. Re-seed: dbt seed --profiles-dir .
--   4. Re-snapshot: dbt snapshot --profiles-dir .
--   5. Verify: no customer_id should appear more than once in the snapshot.
--
-- Verification SQL:
--   select customer_id, count(*) as row_count
--   from snapshots.scd_customers
--   group by customer_id
--   having count(*) > 1
--   -- Returns zero rows if SCD Type 1 is working correctly

{% snapshot scd_customers %}

{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'customer_id',
        strategy      = 'check',
        check_cols    = ['address_line_1', 'city', 'postcode', 'phone'],
        invalidate_hard_deletes = true
    )
}}

select
    customer_id,
    first_name,
    last_name,
    full_name,
    email,
    phone,
    address_line_1,
    city,
    postcode,
    date_of_birth,
    licence_years,
    created_at,
    updated_at

from {{ ref('stg_customers') }}

{% endsnapshot %}
