select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select settled_claims
from "datavault"."marts"."mart_claims_summary"
where settled_claims is null



      
    ) dbt_internal_test