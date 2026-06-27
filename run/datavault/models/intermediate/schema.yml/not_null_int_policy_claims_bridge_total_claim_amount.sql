select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select total_claim_amount
from "datavault"."intermediate"."int_policy_claims_bridge"
where total_claim_amount is null



      
    ) dbt_internal_test