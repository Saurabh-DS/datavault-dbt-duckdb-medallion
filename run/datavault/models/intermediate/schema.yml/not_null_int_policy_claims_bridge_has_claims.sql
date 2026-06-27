select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select has_claims
from "datavault"."intermediate"."int_policy_claims_bridge"
where has_claims is null



      
    ) dbt_internal_test