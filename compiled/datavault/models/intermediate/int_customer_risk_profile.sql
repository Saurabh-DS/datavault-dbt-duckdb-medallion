-- int_customer_risk_profile.sql
-- Silver layer: Customer-level lifetime claim aggregation and risk classification.
--
-- Aggregates the policy-claims bridge to customer level, computing lifetime
-- claim history and applying the risk_band macro for FCA-relevant risk tiering.
--
-- Materialization: table
-- Grain: one row per customer_id

with bridge as (

    select * from "datavault"."intermediate"."int_policy_claims_bridge"

),

customer_aggregates as (

    select
        customer_id,

        -- Policy portfolio metrics
        count(distinct policy_id)::bigint                 as policy_count,
        count(distinct policy_number)::bigint             as unique_policy_count,
        count(distinct case
            when policy_status = 'active' then policy_id
        end)::bigint                                      as active_policy_count,

        -- Premium metrics
        sum(annual_premium)                               as total_annual_premium,
        avg(annual_premium)                               as avg_annual_premium,
        max(annual_premium)                               as max_annual_premium,
        max(no_claims_discount)                           as max_no_claims_discount,

        -- Lifetime claim metrics (across all policy versions)
        sum(claim_count)::bigint                          as lifetime_claim_count,
        sum(total_claim_amount)                           as lifetime_claim_value,
        max(max_claim_amount)                             as max_single_claim_value,
        sum(open_claim_count)::bigint                     as open_claim_count,
        sum(settled_claim_count)::bigint                  as settled_claim_count,

        -- Claim history dates
        min(first_claim_date)                             as first_claim_date,
        max(most_recent_claim_date)                       as most_recent_claim_date,

        -- Vehicle portfolio
        max(vehicle_value)                                as max_vehicle_value,
        avg(vehicle_value)                                as avg_vehicle_value

    from bridge
    group by customer_id

),

risk_classified as (

    select
        customer_id,
        policy_count,
        unique_policy_count,
        active_policy_count,
        total_annual_premium,
        avg_annual_premium,
        max_annual_premium,
        max_no_claims_discount,
        lifetime_claim_count,
        lifetime_claim_value,
        max_single_claim_value,
        open_claim_count,
        settled_claim_count,
        first_claim_date,
        most_recent_claim_date,
        max_vehicle_value,
        avg_vehicle_value,

        -- Apply the risk_band macro — thresholds driven by project variables
        

  case
    when lifetime_claim_count >= 3
      or lifetime_claim_value >= 10000
      then 'high'
    when lifetime_claim_count >= 1
      then 'medium'
    else 'low'
  end


            as risk_band

    from customer_aggregates

)

select * from risk_classified