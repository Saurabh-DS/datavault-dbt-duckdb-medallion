select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select annual_premium
from "datavault"."raw"."raw_policies"
where annual_premium is null



      
    ) dbt_internal_test