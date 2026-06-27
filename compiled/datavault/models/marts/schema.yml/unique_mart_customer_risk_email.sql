
    
    

select
    email as unique_field,
    count(*) as n_records

from "datavault"."marts"."mart_customer_risk"
where email is not null
group by email
having count(*) > 1


