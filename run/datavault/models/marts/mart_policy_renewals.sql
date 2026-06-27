
  
    
    
      
    

    create  table
      "datavault"."marts"."mart_policy_renewals__dbt_tmp"
  
  (
    policy_id varchar not null,
    policy_number varchar,
    customer_id varchar,
    customer_name varchar,
    customer_email varchar,
    customer_phone varchar,
    city varchar,
    postcode varchar,
    cover_type varchar,
    vehicle_make varchar,
    vehicle_model varchar,
    vehicle_registration_year integer,
    vehicle_value double,
    annual_premium double,
    no_claims_discount integer,
    projected_renewal_ncd bigint,
    current_start_date date,
    current_end_date date,
    days_until_expiry bigint
    
    )
 ;
    insert into "datavault"."marts"."mart_policy_renewals__dbt_tmp" 
  (
    
      
      policy_id ,
    
      
      policy_number ,
    
      
      customer_id ,
    
      
      customer_name ,
    
      
      customer_email ,
    
      
      customer_phone ,
    
      
      city ,
    
      
      postcode ,
    
      
      cover_type ,
    
      
      vehicle_make ,
    
      
      vehicle_model ,
    
      
      vehicle_registration_year ,
    
      
      vehicle_value ,
    
      
      annual_premium ,
    
      
      no_claims_discount ,
    
      
      projected_renewal_ncd ,
    
      
      current_start_date ,
    
      
      current_end_date ,
    
      
      days_until_expiry 
    
  )
 (
      
    select policy_id, policy_number, customer_id, customer_name, customer_email, customer_phone, city, postcode, cover_type, vehicle_make, vehicle_model, vehicle_registration_year, vehicle_value, annual_premium, no_claims_discount, projected_renewal_ncd, current_start_date, current_end_date, days_until_expiry
    from (
        -- mart_policy_renewals.sql
-- Gold layer: Active policies due for renewal within the lookahead window.
--
-- Used by the renewals team to prioritise outreach. The renewal_lookahead_days
-- project variable controls the window (default 30 days). Override at runtime:
--   dbt build --vars '{"renewal_lookahead_days": 60}' --profiles-dir .
--
-- Only CURRENT versions of active policies are included (is_current_version = true
-- and policy_status = 'active'). Renewal rows (non-current policy versions) are
-- excluded — they are historical records, not live policies needing renewal action.
--
-- Materialization: table (enforced by contract)
-- Grain: one row per policy_id (current active version only)
-- Contract: enforced (see schema.yml)

with policies as (

    select * from "datavault"."staging"."stg_policies"

),

customers as (

    select
        customer_id,
        full_name,
        email,
        phone,
        city,
        postcode

    from "datavault"."staging"."stg_customers"

),

renewal_candidates as (

    select
        p.policy_id,
        p.policy_number,
        p.customer_id,
        p.cover_type,
        p.vehicle_make,
        p.vehicle_model,
        p.vehicle_registration_year,
        p.vehicle_value,
        p.annual_premium,
        p.no_claims_discount,
        p.start_date,
        p.end_date,
        p.days_until_expiry

    from policies p
    where
        -- Only the current version of each policy
        p.is_current_version = true
        -- Only live active policies (not expired or cancelled)
        and p.policy_status = 'active'
        -- Only policies expiring within the lookahead window
        and p.end_date between current_date
            and current_date + interval (30) day

),

enriched as (

    select
        rc.policy_id,
        rc.policy_number,
        rc.customer_id,
        c.full_name                                       as customer_name,
        c.email                                           as customer_email,
        c.phone                                           as customer_phone,
        c.city,
        c.postcode,
        rc.cover_type,
        rc.vehicle_make,
        rc.vehicle_model,
        rc.vehicle_registration_year,
        rc.vehicle_value,
        rc.annual_premium,
        rc.no_claims_discount,

        -- Projected renewal NCD (1 year earned if no claims)
        least(rc.no_claims_discount + 1, 9)               as projected_renewal_ncd,

        rc.start_date                                     as current_start_date,
        rc.end_date                                       as current_end_date,
        rc.days_until_expiry

    from renewal_candidates rc
    inner join customers c on rc.customer_id = c.customer_id

)

select * from enriched
order by days_until_expiry asc
    ) as model_subq
    );
  
  