{{ config(
    materialized='table'
) }}

with repo as (

    select *
    from {{ ref('stg_repositories') }}

)

select
    repo_id,
    description,
    language,
    stars_count,
    forks_count,
    open_issues_count,
    created_at,
    repo_age_days

from repo