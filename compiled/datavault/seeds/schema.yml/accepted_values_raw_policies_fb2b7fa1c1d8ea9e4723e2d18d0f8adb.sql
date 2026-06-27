
    
    

with all_values as (

    select
        policy_status as value_field,
        count(*) as n_records

    from "datavault"."raw"."raw_policies"
    group by policy_status

)

select *
from all_values
where value_field not in (
    'active','expired','cancelled'
)


