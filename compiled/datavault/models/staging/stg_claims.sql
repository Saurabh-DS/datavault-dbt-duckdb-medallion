-- stg_claims.sql
-- Bronze layer: staging view for raw claims data.
--
-- Key modelling note:
--   Claims join to policies on policy_id (the specific version).
--   This preserves the correct vehicle_value and premium at claim time.
--   The policy_number column is denormalised from the seed for convenience
--   when joining to the SCD Type 2 snapshot history.

with source as (

    select * from "datavault"."raw"."raw_claims"

),

staged as (

    select
        -- Primary key
        claim_id,

        -- Foreign keys
        policy_id,
        policy_number,

        -- Claim details
        claim_type,
        claim_date,
        claim_amount,
        claim_status,

        -- days_to_settle is null for open and rejected claims
        days_to_settle,

        -- Derived: is this claim still active?
        case
            when claim_status = 'open' then true
            else false
        end                                               as is_open,

        -- Derived: was this claim paid out?
        case
            when claim_status = 'settled' then true
            else false
        end                                               as is_settled,

        -- Audit columns
        created_at,
        updated_at,

        -- Pipeline observability
        current_timestamp                                 as _loaded_at

    from source

)

select * from staged