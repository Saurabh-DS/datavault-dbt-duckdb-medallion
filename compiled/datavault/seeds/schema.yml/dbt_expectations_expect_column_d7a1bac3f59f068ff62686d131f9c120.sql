






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and annual_premium >= 0 and annual_premium <= 50000
)
 as expression


    from "datavault"."raw"."raw_policies"
    

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







