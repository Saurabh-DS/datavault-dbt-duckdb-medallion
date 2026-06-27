select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select claim_count
from "datavault"."intermediate"."int_policy_claims_bridge"
where claim_count is null



      
    ) dbt_internal_test