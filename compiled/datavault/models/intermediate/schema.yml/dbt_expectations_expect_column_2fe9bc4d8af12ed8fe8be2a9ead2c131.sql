






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and vehicle_value >= 0 and vehicle_value <= 500000
)
 as expression


    from "datavault"."intermediate"."int_policy_claims_bridge"
    

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







