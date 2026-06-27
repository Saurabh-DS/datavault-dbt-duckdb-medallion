select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        policy_status as value_field,
        count(*) as n_records

    from "datavault"."staging"."stg_policies"
    group by policy_status

)

select *
from all_values
where value_field not in (
    'active','expired','cancelled'
)



      
    ) dbt_internal_test