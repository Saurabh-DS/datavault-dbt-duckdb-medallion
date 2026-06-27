select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        cover_type as value_field,
        count(*) as n_records

    from "datavault"."staging"."stg_policies"
    group by cover_type

)

select *
from all_values
where value_field not in (
    'comprehensive','third_party_fire_theft','third_party'
)



      
    ) dbt_internal_test