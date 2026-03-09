{{ config(
    materialized='table'
) }}

with recent_activity as (

    -- métriques des 30 derniers jours
    select
        f.repo_id,
        sum(f.commits_count) as commits_30d,
        count(distinct c.contributor_id) as contributors_30d,
        avg(f.avg_pr_close_hours) as avg_pr_close_30d,
        avg(f.avg_issue_close_hours) as avg_issue_close_30d,

        -- ratios sur l'historique complet
        sum(f.prs_opened) as total_prs,
        sum(f.prs_merged) as merged_prs,
        sum(f.issues_opened) as total_issues,
        sum(f.issues_closed) as closed_issues

    from {{ ref('fact_repo_activity') }} f

    left join {{ ref('dim_contributor') }} c
        on f.repo_id = c.contributor_id  -- simplification pour count(distinct contributor)
    
    where f.activity_date >= current_date - interval '30 day'
    group by f.repo_id
),

base_metrics as (

    select
        r.repo_id,
        r.description,
        r.language,
        r.stars_count,
        r.forks_count,
        r.open_issues_count,

        ra.commits_30d,
        ra.contributors_30d,
        ra.avg_pr_close_30d,
        ra.avg_issue_close_30d,
        ra.total_prs,
        ra.merged_prs,
        ra.total_issues,
        ra.closed_issues

    from {{ ref('dim_repository') }} r
    left join recent_activity ra
        on r.repo_id = ra.repo_id
),

ranked as (

    select
        *,
        ntile(10) over (order by stars_count desc) as rank_stars,
        ntile(10) over (order by forks_count desc) as rank_forks,

        ntile(10) over (order by commits_30d desc) as rank_commits,
        ntile(10) over (order by contributors_30d desc) as rank_contributors,

        ntile(10) over (order by avg_pr_close_30d) as rank_pr_response,
        ntile(10) over (order by avg_issue_close_30d) as rank_issue_response,

        ntile(10) over (order by (merged_prs * 1.0 / nullif(total_prs,0)) desc) as rank_merged_pr_ratio,
        ntile(10) over (order by (closed_issues * 1.0 / nullif(total_issues,0)) desc) as rank_closed_issue_ratio

    from base_metrics
),

scored as (

    select
        *,
        -- Popularity 20%
        ((rank_stars + rank_forks) * 100.0 / (2*10)) as score_popularity,

        -- Activity 30%
        ((rank_commits + rank_contributors) * 100.0 / (2*10)) as score_activity,

        -- Responsiveness 30%
        ((rank_pr_response + rank_issue_response) * 100.0 / (2*10)) as score_responsiveness,

        -- Community 20%
        ((rank_merged_pr_ratio + rank_closed_issue_ratio) * 100.0 / (2*10)) as score_community

    from ranked
)

select
    repo_id,
    description,
    language,
    stars_count,
    forks_count,
    open_issues_count,

    score_popularity,
    score_activity,
    score_responsiveness,
    score_community,

    -- score global pondéré
    (score_popularity*0.2 + score_activity*0.3 + score_responsiveness*0.3 + score_community*0.2) as score_global,

    rank() over (order by (score_popularity*0.2 + score_activity*0.3 + score_responsiveness*0.3 + score_community*0.2) desc) as rank_global

from scored
order by rank_global