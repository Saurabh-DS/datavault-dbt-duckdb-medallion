select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    claim_month as unique_field,
    count(*) as n_records

from "datavault"."marts"."mart_claims_summary"
where claim_month is not null
group by claim_month
having count(*) > 1



      
    ) dbt_internal_test