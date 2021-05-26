CREATE TABLE tmp_release_milestones_aggregates AS
WITH all_milestone_types AS (
    SELECT
        id,
        TYPE
    FROM
        contract_milestones_summary
    UNION ALL
    SELECT
        id,
        TYPE
    FROM
        contract_implementation_milestones_summary
    UNION ALL
    SELECT
        id,
        TYPE
    FROM
        planning_milestones_summary
    UNION ALL
    SELECT
        id,
        TYPE
    FROM
        tender_milestones_summary
)
SELECT
    id,
    jsonb_object_agg( coalesce(TYPE, ''), total_milestoneTypes) milestoneType_counts,
    sum( total_milestoneTypes) total_milestones
FROM (
    SELECT
        id,
        TYPE,
        count(*) total_milestoneTypes
    FROM
        all_milestone_types
    GROUP BY
        id,
        TYPE
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_milestones_aggregates_id ON tmp_release_milestones_aggregates (id);

