select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select is_settled
from "datavault"."staging"."stg_claims"
where is_settled is null



      
    ) dbt_internal_test