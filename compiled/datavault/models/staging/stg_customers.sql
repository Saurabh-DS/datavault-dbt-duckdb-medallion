-- stg_customers.sql
-- Bronze layer: staging view for raw customer data.
--
-- Responsibilities:
--   • Select from the raw seed source
--   • Explicit column selection (no SELECT *)
--   • Consistent snake_case naming
--   • Minimal type casting (DuckDB infers well from seed column_types config)
--   • Add _loaded_at timestamp for pipeline observability
--   • NO business logic — that lives in intermediate/mart models

with source as (

    select * from "datavault"."raw"."raw_customers"

),

staged as (

    select
        -- Primary key
        customer_id,

        -- Personal details
        first_name,
        last_name,
        first_name || ' ' || last_name                   as full_name,
        email,
        phone,

        -- Address
        address_line_1,
        city,
        postcode,

        -- Driving history
        date_of_birth,
        licence_years,

        -- Audit columns
        created_at,
        updated_at,

        -- Pipeline observability
        current_timestamp                                 as _loaded_at

    from source

)

select * from staged