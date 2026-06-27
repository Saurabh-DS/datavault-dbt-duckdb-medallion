






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and no_claims_discount >= 0 and no_claims_discount <= 9
)
 as expression


    from "datavault"."marts"."mart_policy_renewals"
    

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







