
      update "datavault"."snapshots"."scd_customers" as DBT_INTERNAL_TARGET
    set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to
    from "scd_customers__dbt_tmp20260627001851206739" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_scd_id::text = DBT_INTERNAL_TARGET.dbt_scd_id::text
      and DBT_INTERNAL_SOURCE.dbt_change_type::text in ('update'::text, 'delete'::text)
      and DBT_INTERNAL_TARGET.dbt_valid_to is null;

    insert into "datavault"."snapshots"."scd_customers" ("customer_id", "first_name", "last_name", "full_name", "email", "phone", "address_line_1", "city", "postcode", "date_of_birth", "licence_years", "created_at", "updated_at", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to", "dbt_scd_id")
    select DBT_INTERNAL_SOURCE."customer_id",DBT_INTERNAL_SOURCE."first_name",DBT_INTERNAL_SOURCE."last_name",DBT_INTERNAL_SOURCE."full_name",DBT_INTERNAL_SOURCE."email",DBT_INTERNAL_SOURCE."phone",DBT_INTERNAL_SOURCE."address_line_1",DBT_INTERNAL_SOURCE."city",DBT_INTERNAL_SOURCE."postcode",DBT_INTERNAL_SOURCE."date_of_birth",DBT_INTERNAL_SOURCE."licence_years",DBT_INTERNAL_SOURCE."created_at",DBT_INTERNAL_SOURCE."updated_at",DBT_INTERNAL_SOURCE."dbt_updated_at",DBT_INTERNAL_SOURCE."dbt_valid_from",DBT_INTERNAL_SOURCE."dbt_valid_to",DBT_INTERNAL_SOURCE."dbt_scd_id"
    from "scd_customers__dbt_tmp20260627001851206739" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_change_type::text = 'insert'::text;


  