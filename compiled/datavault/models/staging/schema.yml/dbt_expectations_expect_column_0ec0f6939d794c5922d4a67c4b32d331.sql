






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and licence_years >= 0 and licence_years <= 60
)
 as expression


    from "datavault"."staging"."stg_customers"
    

),
validation_errors as (

    select
        *
    from
        grouped_expression
    where
        not(expression = true)

)

select *
from validation_errors







