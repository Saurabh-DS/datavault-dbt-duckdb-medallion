select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select open_claim_count
from "datavault"."intermediate"."int_policy_claims_bridge"
where open_claim_count is null



      
    ) dbt_internal_test