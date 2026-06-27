
    
    

select
    policy_id as unique_field,
    count(*) as n_records

from "datavault"."marts"."mart_policy_renewals"
where policy_id is not null
group by policy_id
having count(*) > 1


