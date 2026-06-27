select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select risk_band
from "datavault"."intermediate"."int_customer_risk_profile"
where risk_band is null



      
    ) dbt_internal_test