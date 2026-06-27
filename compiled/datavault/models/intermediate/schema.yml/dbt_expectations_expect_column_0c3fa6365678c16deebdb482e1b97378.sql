






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and lifetime_claim_count >= 0 and lifetime_claim_count <= 1000
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







