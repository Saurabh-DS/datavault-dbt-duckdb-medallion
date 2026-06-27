
    
    

select
    email as unique_field,
    count(*) as n_records

from "datavault"."staging"."stg_customers"
where email is not null
group by email
having count(*) > 1


