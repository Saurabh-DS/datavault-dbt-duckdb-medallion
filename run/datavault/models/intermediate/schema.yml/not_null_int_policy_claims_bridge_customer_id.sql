select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select customer_id
from "datavault"."intermediate"."int_policy_claims_bridge"
where customer_id is null



      
    ) dbt_internal_test