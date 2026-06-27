select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select open_claim_count
from "datavault"."marts"."mart_customer_risk"
where open_claim_count is null



      
    ) dbt_internal_test