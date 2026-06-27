select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select policy_number
from "datavault"."marts"."mart_policy_renewals"
where policy_number is null



      
    ) dbt_internal_test