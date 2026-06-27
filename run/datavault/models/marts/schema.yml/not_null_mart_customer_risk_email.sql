select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select email
from "datavault"."marts"."mart_customer_risk"
where email is null



      
    ) dbt_internal_test