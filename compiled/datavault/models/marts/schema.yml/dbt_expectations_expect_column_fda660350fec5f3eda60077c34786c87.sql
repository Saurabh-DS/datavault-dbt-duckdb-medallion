






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and lifetime_claim_value >= 0 and lifetime_claim_value <= 10000000
)
 as expression


    from "datavault"."marts"."mart_customer_risk"
    

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







