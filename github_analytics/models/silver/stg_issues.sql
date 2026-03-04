{{ config(
    materialized='view'
) }}

with source as (

    select *
    from {{ source('bronze', 'raw_issues') }}

),

cleaned as (

    select
        repo_full_name                              as repo_id,
        cast(issue_number as integer)               as issue_number,

        cast(created_at as timestamp)               as created_at,
        cast(closed_at as timestamp)                as closed_at,

        cast(is_pull_request as boolean)            as is_pull_request,

        case
            when closed_at is not null then
                datediff('hour',
                         cast(created_at as timestamp),
                         cast(closed_at as timestamp))
            else null
        end                                         as time_to_close_hours

    from source
    where issue_number is not null

)

-- IMPORTANT : keep only REAL issues
select *
from cleaned
where is_pull_request = false