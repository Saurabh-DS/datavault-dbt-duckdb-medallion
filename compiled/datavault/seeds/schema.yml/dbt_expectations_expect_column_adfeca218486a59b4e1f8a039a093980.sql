






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and claim_amount >= 0 and claim_amount <= 200000
)
 as expression


    from "datavault"."raw"."raw_claims"
    

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







