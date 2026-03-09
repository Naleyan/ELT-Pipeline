
select
    pr_number as id,
    created_at,
    closed_at
from {{ ref('stg_pull_requests') }}
where closed_at < created_at
union all
select
    issue_number as id,
    created_at,
    closed_at
from {{ ref('stg_issues') }}
where closed_at < created_at