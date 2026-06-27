select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select claim_month
from "datavault"."marts"."mart_claims_summary"
where claim_month is null



      
    ) dbt_internal_test