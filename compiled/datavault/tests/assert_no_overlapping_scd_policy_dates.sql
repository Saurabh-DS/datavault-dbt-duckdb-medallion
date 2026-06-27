-- assert_no_overlapping_scd_policy_dates.sql
-- Custom singular test: SCD Type 2 date range integrity.
--
-- A correct SCD Type 2 implementation must NEVER produce two rows for the
-- same policy_number where the date ranges overlap. If ranges overlap,
-- downstream joins will match a claim to multiple policy versions, producing
-- duplicated claim values and incorrect aggregations in every mart.
--
-- This test self-joins scd_policies on policy_number and checks for any pair
-- where the first row's dbt_valid_to is AFTER the second row's dbt_valid_from.
-- Zero rows returned = test passes.
--
-- This is the kind of test you write after being burned by a broken SCD
-- snapshot in production. Detecting overlap early is a senior engineering
-- signal because the bug is non-obvious: the snapshot looks correct, models
-- build successfully, but aggregations are silently wrong.
--
-- Why the proxy test (unique on dbt_scd_id) isn't enough:
--   dbt's built-in unique test on dbt_scd_id catches exact duplicate rows,
--   but not overlapping date ranges caused by out-of-order updated_at values
--   or source system backfills with old timestamps. This test catches that
--   class of bug directly.

select
    a.policy_number,
    a.policy_id                                           as policy_id_a,
    b.policy_id                                           as policy_id_b,
    a.dbt_valid_from                                      as valid_from_a,
    a.dbt_valid_to                                        as valid_to_a,
    b.dbt_valid_from                                      as valid_from_b,
    b.dbt_valid_to                                        as valid_to_b

from "datavault"."snapshots"."scd_policies" a
inner join "datavault"."snapshots"."scd_policies" b
    on  a.policy_number = b.policy_number
    and a.dbt_scd_id   != b.dbt_scd_id   -- exclude self-join

where
    -- Row A's valid_to is after row B's valid_from → overlap detected
    a.dbt_valid_to is not null
    and a.dbt_valid_to > b.dbt_valid_from