with sr as (
    select * from {{ ref('scoring_repositories') }}
)
select
    sr.repo_id,
    sr.score_global,
    sr.rank_global
from sr
where sr.rank_global = 1
  and sr.score_global < (select max(sr2.score_global) 
                         from {{ ref('scoring_repositories') }} as sr2)