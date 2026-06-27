select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select no_claims_discount
from "datavault"."raw"."raw_policies"
where no_claims_discount is null



      
    ) dbt_internal_test