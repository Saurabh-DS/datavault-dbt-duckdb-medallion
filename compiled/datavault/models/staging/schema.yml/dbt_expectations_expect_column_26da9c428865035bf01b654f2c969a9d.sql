






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and vehicle_value >= 500 and vehicle_value <= 200000
)
 as expression


    from "datavault"."staging"."stg_policies"
    

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







