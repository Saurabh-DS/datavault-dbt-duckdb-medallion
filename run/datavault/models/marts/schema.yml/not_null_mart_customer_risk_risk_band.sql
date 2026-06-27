select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select risk_band
from "datavault"."marts"."mart_customer_risk"
where risk_band is null



      
    ) dbt_internal_test