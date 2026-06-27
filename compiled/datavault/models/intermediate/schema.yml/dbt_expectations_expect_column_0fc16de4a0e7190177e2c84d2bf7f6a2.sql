






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and policy_count >= 1 and policy_count <= 100
)
 as expression


    from "datavault"."intermediate"."int_customer_risk_profile"
    

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







