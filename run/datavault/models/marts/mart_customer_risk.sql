
  
    
    
      
    

    create  table
      "datavault"."marts"."mart_customer_risk__dbt_tmp"
  
  (
    customer_id varchar not null,
    full_name varchar,
    email varchar,
    phone varchar,
    city varchar,
    postcode varchar,
    date_of_birth date,
    licence_years integer,
    risk_band varchar,
    policy_count bigint,
    unique_policy_count bigint,
    active_policy_count bigint,
    total_annual_premium double,
    avg_annual_premium double,
    max_no_claims_discount integer,
    lifetime_claim_count bigint,
    lifetime_claim_value double,
    max_single_claim_value double,
    open_claim_count bigint,
    settled_claim_count bigint,
    first_claim_date date,
    most_recent_claim_date date,
    max_vehicle_value double,
    avg_vehicle_value double,
    customer_last_updated_at timestamp
    
    )
 ;
    insert into "datavault"."marts"."mart_customer_risk__dbt_tmp" 
  (
    
      
      customer_id ,
    
      
      full_name ,
    
      
      email ,
    
      
      phone ,
    
      
      city ,
    
      
      postcode ,
    
      
      date_of_birth ,
    
      
      licence_years ,
    
      
      risk_band ,
    
      
      policy_count ,
    
      
      unique_policy_count ,
    
      
      active_policy_count ,
    
      
      total_annual_premium ,
    
      
      avg_annual_premium ,
    
      
      max_no_claims_discount ,
    
      
      lifetime_claim_count ,
    
      
      lifetime_claim_value ,
    
      
      max_single_claim_value ,
    
      
      open_claim_count ,
    
      
      settled_claim_count ,
    
      
      first_claim_date ,
    
      
      most_recent_claim_date ,
    
      
      max_vehicle_value ,
    
      
      avg_vehicle_value ,
    
      
      customer_last_updated_at 
    
  )
 (
      
    select customer_id, full_name, email, phone, city, postcode, date_of_birth, licence_years, risk_band, policy_count, unique_policy_count, active_policy_count, total_annual_premium, avg_annual_premium, max_no_claims_discount, lifetime_claim_count, lifetime_claim_value, max_single_claim_value, open_claim_count, settled_claim_count, first_claim_date, most_recent_claim_date, max_vehicle_value, avg_vehicle_value, customer_last_updated_at
    from (
        -- mart_customer_risk.sql
-- Gold layer: One row per customer with full risk profile and claim history.
--
-- This is a consumer-facing output table with an enforced dbt contract.
-- Any schema change (renamed or removed column, type change) will cause
-- the build to fail immediately, preventing silent breakage of BI tools
-- or downstream data consumers.
--
-- Materialization: table (enforced by contract)
-- Grain: one row per customer_id
-- Contract: enforced (see schema.yml)

with risk_profile as (

    select * from "datavault"."intermediate"."int_customer_risk_profile"

),

customers as (

    select * from "datavault"."staging"."stg_customers"

),

joined as (

    select
        -- Customer identity
        c.customer_id,
        c.full_name,
        c.email,
        c.phone,
        c.city,
        c.postcode,
        c.date_of_birth,
        c.licence_years,

        -- Risk classification
        rp.risk_band,

        -- Policy portfolio
        rp.policy_count,
        rp.unique_policy_count,
        rp.active_policy_count,
        rp.total_annual_premium,
        rp.avg_annual_premium,
        rp.max_no_claims_discount,

        -- Lifetime claim history
        rp.lifetime_claim_count,
        rp.lifetime_claim_value,
        rp.max_single_claim_value,
        rp.open_claim_count,
        rp.settled_claim_count,
        rp.first_claim_date,
        rp.most_recent_claim_date,

        -- Vehicle portfolio
        rp.max_vehicle_value,
        rp.avg_vehicle_value,

        -- Audit
        c.updated_at                                      as customer_last_updated_at

    from customers c
    inner join risk_profile rp on c.customer_id = rp.customer_id

)

select * from joined
    ) as model_subq
    );
  
  