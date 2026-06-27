-- assert_claim_amount_within_vehicle_value.sql
-- Custom singular test: Claim amount business rule validation.
--
-- A settled claim cannot exceed the insured vehicle value. This is a
-- fundamental insurance principle: the maximum payout on a total loss is
-- the declared vehicle value (subject to excess, depreciation, and other
-- policy terms — but never MORE than the vehicle value).
--
-- If this test fails, it indicates one of:
--   1. Bad source data — a claim amount was recorded incorrectly
--   2. A join error in the intermediate layer — a claim has been matched
--      to the wrong policy (wrong vehicle_value)
--   3. A data generation bug in scripts/generate_data.py
--
-- In a production environment, this test would also trigger a data quality
-- alert to the source system team, as the root cause is upstream data quality.
--
-- The test joins claims to policies via the bridge to pick up vehicle_value.
-- Only SETTLED claims are checked — open claims may not yet have a final
-- settled amount, and rejected claims are excluded from payouts.

select
    c.claim_id,
    c.policy_id,
    c.claim_amount,
    c.claim_status,
    p.vehicle_value,
    p.cover_type,
    c.claim_amount - p.vehicle_value                     as excess_amount

from "datavault"."staging"."stg_claims" c
inner join "datavault"."staging"."stg_policies" p
    on c.policy_id = p.policy_id

where
    c.claim_status = 'settled'
    and c.claim_amount > p.vehicle_value