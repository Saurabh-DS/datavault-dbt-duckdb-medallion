
      update "datavault"."snapshots"."scd_policies" as DBT_INTERNAL_TARGET
    set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to
    from "scd_policies__dbt_tmp20260627001851504639" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_scd_id::text = DBT_INTERNAL_TARGET.dbt_scd_id::text
      and DBT_INTERNAL_SOURCE.dbt_change_type::text in ('update'::text, 'delete'::text)
      and DBT_INTERNAL_TARGET.dbt_valid_to is null;

    insert into "datavault"."snapshots"."scd_policies" ("policy_id", "policy_number", "customer_id", "cover_type", "vehicle_make", "vehicle_model", "vehicle_registration_year", "vehicle_value", "annual_premium", "no_claims_discount", "start_date", "end_date", "policy_status", "created_at", "updated_at", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to", "dbt_scd_id")
    select DBT_INTERNAL_SOURCE."policy_id",DBT_INTERNAL_SOURCE."policy_number",DBT_INTERNAL_SOURCE."customer_id",DBT_INTERNAL_SOURCE."cover_type",DBT_INTERNAL_SOURCE."vehicle_make",DBT_INTERNAL_SOURCE."vehicle_model",DBT_INTERNAL_SOURCE."vehicle_registration_year",DBT_INTERNAL_SOURCE."vehicle_value",DBT_INTERNAL_SOURCE."annual_premium",DBT_INTERNAL_SOURCE."no_claims_discount",DBT_INTERNAL_SOURCE."start_date",DBT_INTERNAL_SOURCE."end_date",DBT_INTERNAL_SOURCE."policy_status",DBT_INTERNAL_SOURCE."created_at",DBT_INTERNAL_SOURCE."updated_at",DBT_INTERNAL_SOURCE."dbt_updated_at",DBT_INTERNAL_SOURCE."dbt_valid_from",DBT_INTERNAL_SOURCE."dbt_valid_to",DBT_INTERNAL_SOURCE."dbt_scd_id"
    from "scd_policies__dbt_tmp20260627001851504639" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_change_type::text = 'insert'::text;


  