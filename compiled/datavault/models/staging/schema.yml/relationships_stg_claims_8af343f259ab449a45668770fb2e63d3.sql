
    
    

with child as (
    select policy_id as from_field
    from "datavault"."staging"."stg_claims"
    where policy_id is not null
),

parent as (
    select policy_id as to_field
    from "datavault"."staging"."stg_policies"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


