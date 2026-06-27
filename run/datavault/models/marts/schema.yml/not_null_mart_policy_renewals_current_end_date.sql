select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select current_end_date
from "datavault"."marts"."mart_policy_renewals"
where current_end_date is null



      
    ) dbt_internal_test