select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select policy_status
from "datavault"."raw"."raw_policies"
where policy_status is null



      
    ) dbt_internal_test