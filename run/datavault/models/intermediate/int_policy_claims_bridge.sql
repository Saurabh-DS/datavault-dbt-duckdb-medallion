
  
    
    

    create  table
      "datavault"."intermediate"."int_policy_claims_bridge__dbt_tmp"
  
    as (
      -- int_policy_claims_bridge.sql
-- Silver layer: LEFT JOIN of policies to claims with per-policy claim metrics.
--
-- This is the central aggregation bridge between the policies and claims
-- domains. Every policy appears here (LEFT JOIN preserves zero-claim policies).
-- All downstream customer-level aggregations flow through this model.
--
-- Materialization: table (business logic warrants persistence)
-- Grain: one row per policy_id (policy version)

with policies as (

    select * from "datavault"."staging"."stg_policies"

),

claims as (

    select * from "datavault"."staging"."stg_claims"

),

-- Aggregate claim metrics at the policy_id level
claim_metrics as (

    select
        policy_id,
        count(*)                                          as claim_count,
        sum(claim_amount)                                 as total_claim_amount,
        max(claim_amount)                                 as max_claim_amount,
        sum(case when is_open then 1 else 0 end)          as open_claim_count,
        sum(case when is_settled then 1 else 0 end)       as settled_claim_count,
        min(claim_date)                                   as first_claim_date,
        max(claim_date)                                   as most_recent_claim_date

    from claims
    group by policy_id

),

joined as (

    select
        -- Policy identifiers
        p.policy_id,
        p.policy_number,
        p.customer_id,

        -- Policy details needed for downstream marts
        p.cover_type,
        p.vehicle_make,
        p.vehicle_model,
        p.vehicle_value,
        p.annual_premium,
        p.no_claims_discount,
        p.start_date,
        p.end_date,
        p.policy_status,
        p.is_current_version,
        p.days_until_expiry,

        -- Claim metrics (null for zero-claim policies, coalesced to 0)
        coalesce(cm.claim_count, 0)                       as claim_count,
        coalesce(cm.total_claim_amount, 0.0)              as total_claim_amount,
        coalesce(cm.max_claim_amount, 0.0)                as max_claim_amount,
        coalesce(cm.open_claim_count, 0)                  as open_claim_count,
        coalesce(cm.settled_claim_count, 0)               as settled_claim_count,
        cm.first_claim_date,
        cm.most_recent_claim_date,

        -- Derived flag
        case when coalesce(cm.claim_count, 0) = 0
             then false else true
        end                                               as has_claims

    from policies p
    left join claim_metrics cm on p.policy_id = cm.policy_id

)

select * from joined
    );
  
  