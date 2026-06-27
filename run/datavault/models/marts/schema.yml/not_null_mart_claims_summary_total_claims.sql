select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select total_claims
from "datavault"."marts"."mart_claims_summary"
where total_claims is null



      
    ) dbt_internal_test