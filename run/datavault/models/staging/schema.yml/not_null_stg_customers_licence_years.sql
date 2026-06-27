select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select licence_years
from "datavault"."staging"."stg_customers"
where licence_years is null



      
    ) dbt_internal_test