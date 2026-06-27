select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select max_no_claims_discount
from "datavault"."intermediate"."int_customer_risk_profile"
where max_no_claims_discount is null



      
    ) dbt_internal_test