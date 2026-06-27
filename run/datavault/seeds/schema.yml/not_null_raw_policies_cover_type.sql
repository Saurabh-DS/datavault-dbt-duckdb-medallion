select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select cover_type
from "datavault"."raw"."raw_policies"
where cover_type is null



      
    ) dbt_internal_test