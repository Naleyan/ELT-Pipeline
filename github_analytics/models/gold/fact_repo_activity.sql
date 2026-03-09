{{ config(
    materialized='table'
) }}

with daily_commits as (

    select
        repo_id,
        date(author_date) as activity_date,
        count(*) as commits_count,
        count(distinct author_login) as unique_committers
    from {{ ref('stg_commits') }}
    group by repo_id, activity_date

),

daily_prs as (

    select
        repo_id,
        date(created_at) as activity_date,
        count(*) as prs_opened,
        sum(case when is_merged then 1 else 0 end) as prs_merged,
        avg(
            case
                when closed_at is not null
                then datediff('hour', created_at, closed_at)
            end
        ) as avg_pr_close_hours
    from {{ ref('stg_pull_requests') }}
    group by repo_id, activity_date

),

daily_issues as (

    select
        repo_id,
        date(created_at) as activity_date,
        count(*) as issues_opened,
        sum(case when closed_at is not null then 1 else 0 end) as issues_closed,
        avg(
            case
                when closed_at is not null
                then datediff('hour', created_at, closed_at)
            end
        ) as avg_issue_close_hours
    from {{ ref('stg_issues') }}
    group by repo_id, activity_date

),

all_activity_dates as (

    select repo_id, activity_date from daily_commits
    union
    select repo_id, activity_date from daily_prs
    union
    select repo_id, activity_date from daily_issues

),

final as (

    select

        a.repo_id,
        a.activity_date,

        cast(strftime(a.activity_date, '%Y%m%d') as integer) as date_id,

        coalesce(c.commits_count, 0) as commits_count,
        coalesce(c.unique_committers, 0) as unique_committers,

        coalesce(p.prs_opened, 0) as prs_opened,
        coalesce(p.prs_merged, 0) as prs_merged,
        p.avg_pr_close_hours,

        coalesce(i.issues_opened, 0) as issues_opened,
        coalesce(i.issues_closed, 0) as issues_closed,
        i.avg_issue_close_hours

    from all_activity_dates a

    left join daily_commits c
        on a.repo_id = c.repo_id
        and a.activity_date = c.activity_date

    left join daily_prs p
        on a.repo_id = p.repo_id
        and a.activity_date = p.activity_date

    left join daily_issues i
        on a.repo_id = i.repo_id
        and a.activity_date = i.activity_date

)

select * from final