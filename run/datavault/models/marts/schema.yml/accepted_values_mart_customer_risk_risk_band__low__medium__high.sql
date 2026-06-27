select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        risk_band as value_field,
        count(*) as n_records

    from "datavault"."marts"."mart_customer_risk"
    group by risk_band

)

select *
from all_values
where value_field not in (
    'low','medium','high'
)



      
    ) dbt_internal_test