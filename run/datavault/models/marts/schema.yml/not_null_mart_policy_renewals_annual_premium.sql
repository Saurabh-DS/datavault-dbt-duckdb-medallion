select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select annual_premium
from "datavault"."marts"."mart_policy_renewals"
where annual_premium is null



      
    ) dbt_internal_test