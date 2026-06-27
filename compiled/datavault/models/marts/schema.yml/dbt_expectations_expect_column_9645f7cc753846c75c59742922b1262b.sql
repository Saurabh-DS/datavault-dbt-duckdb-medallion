






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and days_until_expiry >= 0 and days_until_expiry <= 366
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







