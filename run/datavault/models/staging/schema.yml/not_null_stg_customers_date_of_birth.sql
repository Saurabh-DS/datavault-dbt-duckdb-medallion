select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select date_of_birth
from "datavault"."staging"."stg_customers"
where date_of_birth is null



      
    ) dbt_internal_test