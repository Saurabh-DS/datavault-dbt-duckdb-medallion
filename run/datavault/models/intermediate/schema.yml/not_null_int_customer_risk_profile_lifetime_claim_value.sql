select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select lifetime_claim_value
from "datavault"."intermediate"."int_customer_risk_profile"
where lifetime_claim_value is null



      
    ) dbt_internal_test