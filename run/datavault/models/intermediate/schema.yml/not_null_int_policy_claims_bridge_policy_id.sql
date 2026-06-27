select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select policy_id
from "datavault"."intermediate"."int_policy_claims_bridge"
where policy_id is null



      
    ) dbt_internal_test