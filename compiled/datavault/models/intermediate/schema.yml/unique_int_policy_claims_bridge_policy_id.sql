
    
    

select
    policy_id as unique_field,
    count(*) as n_records

from "datavault"."intermediate"."int_policy_claims_bridge"
where policy_id is not null
group by policy_id
having count(*) > 1


