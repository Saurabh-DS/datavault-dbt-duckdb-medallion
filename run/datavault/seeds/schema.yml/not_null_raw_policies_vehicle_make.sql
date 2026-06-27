select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select vehicle_make
from "datavault"."raw"."raw_policies"
where vehicle_make is null



      
    ) dbt_internal_test