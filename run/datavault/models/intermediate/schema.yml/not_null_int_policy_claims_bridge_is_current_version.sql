select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select is_current_version
from "datavault"."intermediate"."int_policy_claims_bridge"
where is_current_version is null



      
    ) dbt_internal_test