-- renewal_pipeline_value.sql
-- One-off analysis: Total annual premium value of the renewal pipeline.
--
-- This analysis is NOT materialised — it runs on demand for ad-hoc reporting.
-- Run with: dbt compile --select renewal_pipeline_value --profiles-dir .
-- Then execute the compiled SQL against the DuckDB file.
--
-- Use case: Board-level question before a renewal season.
--   "What is the total premium at risk this month, and how is it distributed
--    by cover type and customer risk band?"
--
-- Output segmented by cover_type × risk_band for underwriting insight.

with renewal_candidates as (

    select
        mr.policy_id,
        mr.customer_id,
        mr.cover_type,
        mr.annual_premium,
        mr.vehicle_value,
        mr.no_claims_discount,
        mr.projected_renewal_ncd,
        mr.days_until_expiry,
        mr.current_end_date

    from "datavault"."marts"."mart_policy_renewals" mr

),

customer_risk as (

    select
        customer_id,
        risk_band

    from "datavault"."marts"."mart_customer_risk"

),

enriched as (

    select
        rc.policy_id,
        rc.cover_type,
        rc.annual_premium,
        rc.vehicle_value,
        rc.no_claims_discount,
        rc.projected_renewal_ncd,
        rc.days_until_expiry,
        rc.current_end_date,
        cr.risk_band

    from renewal_candidates rc
    inner join customer_risk cr
        on rc.customer_id = cr.customer_id

),

summary as (

    select
        cover_type,
        risk_band,

        count(*)                                          as policy_count,
        sum(annual_premium)                               as total_premium_at_risk,
        avg(annual_premium)                               as avg_premium,
        sum(vehicle_value)                                as total_vehicle_value_at_risk,
        avg(vehicle_value)                                as avg_vehicle_value,
        avg(no_claims_discount)                           as avg_ncd,
        min(days_until_expiry)                            as min_days_until_expiry,
        max(days_until_expiry)                            as max_days_until_expiry

    from enriched
    group by cover_type, risk_band
    order by cover_type, risk_band

)

select
    cover_type,
    risk_band,
    policy_count,
    round(total_premium_at_risk, 2)                       as total_premium_at_risk_gbp,
    round(avg_premium, 2)                                 as avg_premium_gbp,
    round(total_vehicle_value_at_risk, 2)                 as total_vehicle_value_at_risk_gbp,
    round(avg_vehicle_value, 2)                           as avg_vehicle_value_gbp,
    round(avg_ncd, 1)                                     as avg_ncd_years,
    min_days_until_expiry,
    max_days_until_expiry

from summary