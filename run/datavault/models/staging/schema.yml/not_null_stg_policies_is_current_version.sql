select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select is_current_version
from "datavault"."staging"."stg_policies"
where is_current_version is null



      
    ) dbt_internal_test