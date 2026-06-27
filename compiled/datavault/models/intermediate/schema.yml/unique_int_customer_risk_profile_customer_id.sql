
    
    

select
    customer_id as unique_field,
    count(*) as n_records

from "datavault"."intermediate"."int_customer_risk_profile"
where customer_id is not null
group by customer_id
having count(*) > 1


