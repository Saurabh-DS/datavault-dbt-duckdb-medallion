
  
    
    
      
    

    create  table
      "datavault"."marts"."mart_claims_summary__dbt_tmp"
  
  (
    claim_month date not null,
    total_claims bigint,
    settled_claims bigint,
    open_claims bigint,
    rejected_claims bigint,
    total_claim_amount double,
    avg_claim_amount double,
    max_claim_amount double,
    settled_claim_amount double,
    avg_days_to_settle double,
    accident_claims bigint,
    theft_claims bigint,
    fire_claims bigint,
    windscreen_claims bigint,
    weather_claims bigint,
    comprehensive_claims bigint,
    tpft_claims bigint,
    tp_claims bigint,
    rolling_3m_avg_claims double,
    rolling_3m_avg_claim_amount double,
    rolling_3m_avg_claim_size double
    
    )
 ;
    insert into "datavault"."marts"."mart_claims_summary__dbt_tmp" 
  (
    
      
      claim_month ,
    
      
      total_claims ,
    
      
      settled_claims ,
    
      
      open_claims ,
    
      
      rejected_claims ,
    
      
      total_claim_amount ,
    
      
      avg_claim_amount ,
    
      
      max_claim_amount ,
    
      
      settled_claim_amount ,
    
      
      avg_days_to_settle ,
    
      
      accident_claims ,
    
      
      theft_claims ,
    
      
      fire_claims ,
    
      
      windscreen_claims ,
    
      
      weather_claims ,
    
      
      comprehensive_claims ,
    
      
      tpft_claims ,
    
      
      tp_claims ,
    
      
      rolling_3m_avg_claims ,
    
      
      rolling_3m_avg_claim_amount ,
    
      
      rolling_3m_avg_claim_size 
    
  )
 (
      
    select claim_month, total_claims, settled_claims, open_claims, rejected_claims, total_claim_amount, avg_claim_amount, max_claim_amount, settled_claim_amount, avg_days_to_settle, accident_claims, theft_claims, fire_claims, windscreen_claims, weather_claims, comprehensive_claims, tpft_claims, tp_claims, rolling_3m_avg_claims, rolling_3m_avg_claim_amount, rolling_3m_avg_claim_size
    from (
        -- mart_claims_summary.sql
-- Gold layer: Monthly claim aggregation with 3-month rolling averages.
--
-- Provides management information on claim frequency and value trends.
-- The 3-month rolling average smooths month-to-month volatility, which is
-- the standard way to present claims trends to a UK insurance board.
--
-- Materialization: table (enforced by contract)
-- Grain: one row per calendar month
-- Contract: enforced (see schema.yml)

with claims as (

    select * from "datavault"."staging"."stg_claims"

),

policies as (

    select
        policy_id,
        cover_type,
        vehicle_value

    from "datavault"."staging"."stg_policies"

),

-- Join claims to policies to get cover_type for segmentation
enriched_claims as (

    select
        c.claim_id,
        c.claim_type,
        c.claim_date,
        c.claim_amount,
        c.claim_status,
        c.days_to_settle,
        c.is_settled,
        c.is_open,
        p.cover_type,
        p.vehicle_value,

        -- Truncate claim_date to the first day of the month for grouping
        date_trunc('month', c.claim_date)::date            as claim_month

    from claims c
    left join policies p on c.policy_id = p.policy_id

),

monthly_aggregates as (

    select
        claim_month,

        -- Volume metrics
        count(*)                                          as total_claims,
        count(distinct case when is_settled then claim_id end)
                                                          as settled_claims,
        count(distinct case when is_open then claim_id end)
                                                          as open_claims,
        count(distinct case when claim_status = 'rejected' then claim_id end)
                                                          as rejected_claims,

        -- Value metrics
        sum(claim_amount)                                 as total_claim_amount,
        avg(claim_amount)                                 as avg_claim_amount,
        max(claim_amount)                                 as max_claim_amount,
        sum(case when is_settled then claim_amount else 0 end)
                                                          as settled_claim_amount,

        -- Settlement speed (for settled claims only)
        avg(case when is_settled then days_to_settle end)
                                                          as avg_days_to_settle,

        -- Claim type breakdown
        count(case when claim_type = 'accident' then 1 end)
                                                          as accident_claims,
        count(case when claim_type = 'theft' then 1 end)
                                                          as theft_claims,
        count(case when claim_type = 'fire' then 1 end)
                                                          as fire_claims,
        count(case when claim_type = 'windscreen' then 1 end)
                                                          as windscreen_claims,
        count(case when claim_type = 'weather' then 1 end)
                                                          as weather_claims,

        -- Cover type split
        count(case when cover_type = 'comprehensive' then 1 end)
                                                          as comprehensive_claims,
        count(case when cover_type = 'third_party_fire_theft' then 1 end)
                                                          as tpft_claims,
        count(case when cover_type = 'third_party' then 1 end)
                                                          as tp_claims

    from enriched_claims
    group by claim_month

),

with_rolling_averages as (

    select
        claim_month,
        total_claims,
        settled_claims,
        open_claims,
        rejected_claims,
        total_claim_amount,
        avg_claim_amount,
        max_claim_amount,
        settled_claim_amount,
        avg_days_to_settle,
        accident_claims,
        theft_claims,
        fire_claims,
        windscreen_claims,
        weather_claims,
        comprehensive_claims,
        tpft_claims,
        tp_claims,

        -- 3-month rolling averages (current month + 2 preceding)
        avg(total_claims) over (
            order by claim_month
            rows between 2 preceding and current row
        )                                                 as rolling_3m_avg_claims,

        avg(total_claim_amount) over (
            order by claim_month
            rows between 2 preceding and current row
        )                                                 as rolling_3m_avg_claim_amount,

        avg(avg_claim_amount) over (
            order by claim_month
            rows between 2 preceding and current row
        )                                                 as rolling_3m_avg_claim_size

    from monthly_aggregates

)

select * from with_rolling_averages
order by claim_month
    ) as model_subq
    );
  
  