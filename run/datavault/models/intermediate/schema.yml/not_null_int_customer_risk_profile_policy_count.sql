select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select policy_count
from "datavault"."intermediate"."int_customer_risk_profile"
where policy_count is null



      
    ) dbt_internal_test