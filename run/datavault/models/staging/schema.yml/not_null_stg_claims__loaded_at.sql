select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select _loaded_at
from "datavault"."staging"."stg_claims"
where _loaded_at is null



      
    ) dbt_internal_test