select
    repo_id,
    count(*) as total_prs,
    sum(case when is_merged then 1 else 0 end) as merged_prs
from {{ ref('stg_pull_requests') }}
group by repo_id
having merged_prs > total_prs