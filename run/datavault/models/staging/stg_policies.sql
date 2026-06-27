
  
  create view "datavault"."staging"."stg_policies__dbt_tmp" as (
    -- stg_policies.sql
-- Bronze layer: staging view for raw policy data.
--
-- Key modelling note:
--   raw_policies contains one row per policy VERSION. A policy_number is
--   stable across renewals; policy_id is unique per version. Both columns
--   are surfaced here — downstream models choose which to join on.
--
--   is_current_version flags the latest version of each policy_number,
--   derived in this staging model so all downstream consumers benefit from it.

with source as (

    select * from "datavault"."raw"."raw_policies"

),

staged as (

    select
        -- Version-specific identifier (unique per row)
        policy_id,

        -- Stable identifier across renewals (snapshot unique_key)
        policy_number,

        -- Foreign keys
        customer_id,

        -- Coverage details
        cover_type,
        vehicle_make,
        vehicle_model,
        vehicle_registration_year,
        vehicle_value,

        -- Premium details
        annual_premium,
        no_claims_discount,

        -- Policy dates
        start_date,
        end_date,
        policy_status,

        -- Derived: days remaining until expiry (negative = already expired)
        datediff('day', current_date, end_date)           as days_until_expiry,

        -- Derived: is this the latest version of this policy_number?
        case
            when row_number() over (
                partition by policy_number
                order by updated_at desc
            ) = 1 then true
            else false
        end                                               as is_current_version,

        -- Audit columns
        created_at,
        updated_at,

        -- Pipeline observability
        current_timestamp                                 as _loaded_at

    from source

)

select * from staged
  );
