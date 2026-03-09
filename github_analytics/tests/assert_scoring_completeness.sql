select
    dr.repo_id
from {{ ref('dim_repository') }} dr
left join {{ ref('scoring_repositories') }} sr
    on dr.repo_id = sr.repo_id
where sr.repo_id is null