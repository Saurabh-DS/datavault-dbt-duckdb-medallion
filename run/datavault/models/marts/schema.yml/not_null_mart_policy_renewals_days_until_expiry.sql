select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select days_until_expiry
from "datavault"."marts"."mart_policy_renewals"
where days_until_expiry is null



      
    ) dbt_internal_test