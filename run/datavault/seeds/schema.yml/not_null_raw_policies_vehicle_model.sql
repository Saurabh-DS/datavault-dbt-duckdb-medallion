select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select vehicle_model
from "datavault"."raw"."raw_policies"
where vehicle_model is null



      
    ) dbt_internal_test