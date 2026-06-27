select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select updated_at
from "datavault"."raw"."raw_policies"
where updated_at is null



      
    ) dbt_internal_test