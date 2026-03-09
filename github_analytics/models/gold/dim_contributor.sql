{{ config(
    materialized='table'
) }}

with filtered as (

    select *
    from {{ ref('stg_commits') }}
    where author_login != 'unknown'

),

aggregated as (

    select
        author_login as contributor_id,
        min(author_date) as first_contribution_at,
        count(distinct repo_id) as repos_contributed_to,
        count(*) as total_activities
    from filtered
    group by author_login

)

select *
from aggregated