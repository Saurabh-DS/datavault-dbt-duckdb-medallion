select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select claim_status
from "datavault"."raw"."raw_claims"
where claim_status is null



      
    ) dbt_internal_test