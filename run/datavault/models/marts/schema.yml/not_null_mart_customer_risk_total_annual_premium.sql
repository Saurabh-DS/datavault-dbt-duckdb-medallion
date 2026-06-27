select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select total_annual_premium
from "datavault"."marts"."mart_customer_risk"
where total_annual_premium is null



      
    ) dbt_internal_test