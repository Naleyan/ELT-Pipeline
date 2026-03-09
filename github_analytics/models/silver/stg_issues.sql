{{ config(
    materialized='incremental',
    unique_key='issue_id'
) }}

with source as (

    select *
    from {{ source('bronze', 'raw_issues') }}

),

filtered as (

    select *
    from source

    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}

),

cleaned as (

    select
        cast(issue_number as integer) as issue_id,
        cast(issue_number as integer) as issue_number,
        repo_full_name as repo_id,
        user_login as reporter_id,
        cast(is_pull_request as boolean) as is_pull_request,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(closed_at as timestamp) as closed_at,
        coalesce(title, 'No Title') as title,
        state
    from filtered
    where issue_number is not null

)

select *
from cleaned
where is_pull_request = false