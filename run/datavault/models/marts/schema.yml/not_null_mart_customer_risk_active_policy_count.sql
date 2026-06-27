select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select active_policy_count
from "datavault"."marts"."mart_customer_risk"
where active_policy_count is null



      
    ) dbt_internal_test