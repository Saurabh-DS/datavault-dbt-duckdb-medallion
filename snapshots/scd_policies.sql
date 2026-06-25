-- scd_policies.sql
-- SCD Type 2 snapshot: policy premium history.
--
-- Strategy: timestamp (on updated_at column)
-- Unique key: policy_number  ← stable across renewals
-- Updated at: updated_at
--
-- Behaviour:
--   When a policy_number row changes (i.e. a renewal row with a later updated_at
--   arrives in stg_policies), dbt:
--     1. Sets dbt_valid_to on the OLD row to the new updated_at value
--     2. Inserts a NEW row with dbt_valid_from = updated_at, dbt_valid_to = null
--
--   The result is a full premium history per policy_number. This preserves the
--   exact premium and NCD level a customer was paying at the time of any claim —
--   a regulatory requirement for a UK FCA-regulated insurer.
--
-- The is_current column (dbt_valid_to is null) identifies the active version.
--
-- Verification SQL:
--   select
--       policy_number,
--       policy_id,
--       annual_premium,
--       no_claims_discount,
--       dbt_valid_from,
--       dbt_valid_to
--   from snapshots.scd_policies
--   where policy_number in (
--       select policy_number
--       from snapshots.scd_policies
--       group by policy_number
--       having count(*) > 1
--   )
--   order by policy_number, dbt_valid_from
--   -- Returns renewal history rows. Each policy_number should show original
--   -- and renewed versions with non-overlapping date ranges.

{% snapshot scd_policies %}

{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'policy_number',
        strategy      = 'timestamp',
        updated_at    = 'updated_at',
        invalidate_hard_deletes = true
    )
}}

select
    policy_id,
    policy_number,
    customer_id,
    cover_type,
    vehicle_make,
    vehicle_model,
    vehicle_registration_year,
    vehicle_value,
    annual_premium,
    no_claims_discount,
    start_date,
    end_date,
    policy_status,
    created_at,
    updated_at

from {{ ref('stg_policies') }}

-- Note: dbt_valid_to (used to derive is_current) is a snapshot-managed column
-- that dbt adds to the snapshot TABLE, not to this source SELECT.
-- To get the current policy version in downstream models, use:
--   where dbt_valid_to is null

{% endsnapshot %}
