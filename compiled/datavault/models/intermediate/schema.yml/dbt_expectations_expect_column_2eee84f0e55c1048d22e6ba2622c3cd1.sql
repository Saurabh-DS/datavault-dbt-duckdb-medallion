






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and claim_count >= 0 and claim_count <= 500
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







