select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select vehicle_value
from "datavault"."raw"."raw_policies"
where vehicle_value is null



      
    ) dbt_internal_test